package grpc

import (
	ancymonproto "ancymon/proto"
	"ancymon/server/internal/storage"
	"ancymon/server/internal/watchdog"
	"context"
	"net"
	"testing"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
)

func TestGRPCServerAuthenticationAndStreaming(t *testing.T) {
	authToken := "test-secret-psk-123"
	reg := watchdog.NewRegistry(nil)
	writer := storage.NewWriter("http://127.0.0.1:9999", 10, 500*time.Millisecond)
	defer writer.Stop()

	server := NewServer(reg, writer, authToken)

	lis, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("failed to listen: %v", err)
	}
	defer lis.Close()

	go func() {
		_ = server.Serve(lis)
	}()
	defer server.GracefulStop()

	conn, err := grpc.NewClient(
		lis.Addr().String(),
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	if err != nil {
		t.Fatalf("failed to connect to test server: %v", err)
	}
	defer conn.Close()

	client := ancymonproto.NewTelemetryServiceClient(conn)

	// Case 1: Unauthenticated (no metadata)
	stream, err := client.StreamTelemetry(context.Background())
	if err != nil {
		t.Fatalf("failed to open stream: %v", err)
	}
	_ = stream.Send(&ancymonproto.TelemetryFrame{MachineId: "auth-test"})
	_, err = stream.CloseAndRecv()
	if status.Code(err) != codes.Unauthenticated {
		t.Errorf("expected Unauthenticated code without auth header, got %v: %v", status.Code(err), err)
	}

	// Case 2: Invalid Bearer token
	badCtx := metadata.NewOutgoingContext(context.Background(), metadata.Pairs("authorization", "Bearer wrong-token"))
	stream, err = client.StreamTelemetry(badCtx)
	if err != nil {
		t.Fatalf("failed to open stream: %v", err)
	}
	_ = stream.Send(&ancymonproto.TelemetryFrame{MachineId: "auth-test"})
	_, err = stream.CloseAndRecv()
	if status.Code(err) != codes.Unauthenticated {
		t.Errorf("expected Unauthenticated code with wrong token, got %v", status.Code(err))
	}

	// Case 3: Valid Bearer token
	validCtx := metadata.NewOutgoingContext(context.Background(), metadata.Pairs("authorization", "Bearer "+authToken))
	stream, err = client.StreamTelemetry(validCtx)
	if err != nil {
		t.Fatalf("failed to open authenticated stream: %v", err)
	}

	f1 := &ancymonproto.TelemetryFrame{
		MachineId:     "valid-host-01",
		Hostname:      "worker-node",
		TimestampUnix: 1710000001,
		Cpu:           &ancymonproto.CpuMetrics{TotalUsagePercent: 15.5},
	}
	f2 := &ancymonproto.TelemetryFrame{
		MachineId:     "valid-host-01",
		Hostname:      "worker-node",
		TimestampUnix: 1710000002,
		Cpu:           &ancymonproto.CpuMetrics{TotalUsagePercent: 18.2},
	}

	if err := stream.Send(f1); err != nil {
		t.Fatalf("failed to send frame 1: %v", err)
	}
	if err := stream.Send(f2); err != nil {
		t.Fatalf("failed to send frame 2: %v", err)
	}

	ack, err := stream.CloseAndRecv()
	if err != nil {
		t.Fatalf("CloseAndRecv failed: %v", err)
	}

	if !ack.Success {
		t.Errorf("expected ack.Success == true")
	}
	if ack.AcknowledgedCount != 2 {
		t.Errorf("expected ack count 2, got %d", ack.AcknowledgedCount)
	}
	if ack.AcknowledgedTimestamp != 1710000002 {
		t.Errorf("expected ack timestamp 1710000002, got %d", ack.AcknowledgedTimestamp)
	}

	// Verify registry was updated
	detail, ok := reg.GetMachineDetail("valid-host-01")
	if !ok {
		t.Fatalf("expected host in registry")
	}
	if detail.Hostname != "worker-node" || detail.Cpu.TotalUsagePercent != 18.2 {
		t.Errorf("unexpected registry detail: %+v", detail)
	}
}
