package client_test

import (
	"context"
	"io"
	"net"
	"sync"
	"testing"
	"time"

	"ancymon/agent/internal/client"
	ancymonproto "ancymon/proto"

	"google.golang.org/grpc"
	"google.golang.org/grpc/metadata"
)

type mockServer struct {
	ancymonproto.UnimplementedTelemetryServiceServer
	mu             sync.Mutex
	receivedFrames []*ancymonproto.TelemetryFrame
	authTokens     []string
}

func (s *mockServer) StreamTelemetry(stream ancymonproto.TelemetryService_StreamTelemetryServer) error {
	md, ok := metadata.FromIncomingContext(stream.Context())
	if ok {
		tokens := md.Get("authorization")
		s.mu.Lock()
		s.authTokens = append(s.authTokens, tokens...)
		s.mu.Unlock()
	}

	var count uint64
	for {
		frame, err := stream.Recv()
		if err == io.EOF {
			return stream.SendAndClose(&ancymonproto.TelemetryAck{
				Success:               true,
				AcknowledgedTimestamp: time.Now().Unix(),
				AcknowledgedCount:     count,
				Message:               "Batch processed successfully",
			})
		}
		if err != nil {
			return err
		}

		s.mu.Lock()
		s.receivedFrames = append(s.receivedFrames, frame)
		count++
		s.mu.Unlock()
	}
}

func startMockGRPCServer(t *testing.T) (*mockServer, string, func()) {
	lis, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("failed to listen: %v", err)
	}

	srv := &mockServer{}
	grpcServer := grpc.NewServer()
	ancymonproto.RegisterTelemetryServiceServer(grpcServer, srv)

	go func() {
		_ = grpcServer.Serve(lis)
	}()

	cleanup := func() {
		grpcServer.Stop()
		_ = lis.Close()
	}

	return srv, lis.Addr().String(), cleanup
}

func TestGRPCClient_SendBatchAndAuth(t *testing.T) {
	srv, addr, cleanup := startMockGRPCServer(t)
	defer cleanup()

	cli, err := client.Dial(client.Config{
		ServerAddress: addr,
		AuthToken:     "test-psk-token-xyz",
		Insecure:      true,
	})
	if err != nil {
		t.Fatalf("failed to dial mock server: %v", err)
	}
	defer cli.Close()

	frames := []*ancymonproto.TelemetryFrame{
		{
			MachineId:     "m-client-test",
			Hostname:      "test-box",
			TimestampUnix: 100,
			Cpu:           &ancymonproto.CpuMetrics{TotalUsagePercent: 12.0},
		},
		{
			MachineId:     "m-client-test",
			Hostname:      "test-box",
			TimestampUnix: 101,
			Cpu:           &ancymonproto.CpuMetrics{TotalUsagePercent: 14.5},
		},
	}

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	ack, err := cli.SendBatch(ctx, frames)
	if err != nil {
		t.Fatalf("failed to send batch: %v", err)
	}

	if !ack.GetSuccess() {
		t.Errorf("expected success true, got %v", ack.GetSuccess())
	}
	if ack.GetAcknowledgedCount() != 2 {
		t.Errorf("expected acknowledged count 2, got %d", ack.GetAcknowledgedCount())
	}

	srv.mu.Lock()
	defer srv.mu.Unlock()

	if len(srv.receivedFrames) != 2 {
		t.Fatalf("expected 2 received frames on server, got %d", len(srv.receivedFrames))
	}
	if len(srv.authTokens) == 0 || srv.authTokens[0] != "Bearer test-psk-token-xyz" {
		t.Errorf("expected Bearer test-psk-token-xyz auth token, got %v", srv.authTokens)
	}
}
