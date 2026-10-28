package grpc

import (
	ancymonproto "ancymon/proto"
	"ancymon/server/internal/storage"
	"ancymon/server/internal/watchdog"
	"io"
	"log"
	"net"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/keepalive"
)

// Server wraps the gRPC telemetry ingestion service and underlying gRPC server.
type Server struct {
	ancymonproto.UnimplementedTelemetryServiceServer

	registry   *watchdog.Registry
	writer     *storage.Writer
	grpcServer *grpc.Server
}

// NewServer builds a configured gRPC server enforcing keepalive policies and Bearer auth.
func NewServer(reg *watchdog.Registry, writer *storage.Writer, authToken string) *Server {
	auth := NewAuthInterceptor(authToken)

	// Keepalive Enforcement Policy:
	// - MinTime: 15s (clients pinging more frequently than 15s will be struck with GOAWAY)
	// - PermitWithoutStream: true (allow keepalive pings even without active RPC streams)
	kaep := keepalive.EnforcementPolicy{
		MinTime:             15 * time.Second,
		PermitWithoutStream: true,
	}

	// Server Keepalive Parameters:
	// - Time: 60s (server pings idle clients every 60s)
	// - Timeout: 20s (wait up to 20s for ping acknowledgement)
	kasp := keepalive.ServerParameters{
		Time:    60 * time.Second,
		Timeout: 20 * time.Second,
	}

	grpcSrv := grpc.NewServer(
		grpc.KeepaliveEnforcementPolicy(kaep),
		grpc.KeepaliveParams(kasp),
		grpc.UnaryInterceptor(auth.UnaryInterceptor()),
		grpc.StreamInterceptor(auth.StreamInterceptor()),
	)

	s := &Server{
		registry:   reg,
		writer:     writer,
		grpcServer: grpcSrv,
	}

	ancymonproto.RegisterTelemetryServiceServer(grpcSrv, s)
	return s
}

// StreamTelemetry handles continuous 1 Hz client telemetry streams from ancymon-agent.
func (s *Server) StreamTelemetry(stream ancymonproto.TelemetryService_StreamTelemetryServer) error {
	var count uint64
	var lastTimestamp int64

	for {
		frame, err := stream.Recv()
		if err == io.EOF {
			ackTimestamp := time.Now().Unix()
			if lastTimestamp > 0 {
				ackTimestamp = lastTimestamp
			}
			return stream.SendAndClose(&ancymonproto.TelemetryAck{
				Success:               true,
				AcknowledgedTimestamp: ackTimestamp,
				AcknowledgedCount:     count,
				Message:               "Telemetry stream acknowledged successfully",
			})
		}
		if err != nil {
			log.Printf("[gRPC] Client telemetry stream error: %v", err)
			return err
		}

		count++
		if frame.TimestampUnix > 0 {
			lastTimestamp = frame.TimestampUnix
		}

		// 1. Update in-memory registry and notify GraphQL subscribers
		if s.registry != nil {
			s.registry.RecordTelemetry(frame)
		}

		// 2. Queue for asynchronous batch persistence into VictoriaMetrics
		if s.writer != nil {
			s.writer.Enqueue(frame)
		}
	}
}

// Serve starts listening on the provided network listener.
func (s *Server) Serve(lis net.Listener) error {
	return s.grpcServer.Serve(lis)
}

// GracefulStop gracefully terminates active streams and shuts down the gRPC server.
func (s *Server) GracefulStop() {
	s.grpcServer.GracefulStop()
}

// GracefulStopWithTimeout attempts to gracefully terminate active streams within the given timeout.
// If active streams or RPCs do not terminate within the deadline, it forces a Stop() to unblock.
func (s *Server) GracefulStopWithTimeout(timeout time.Duration) {
	stopped := make(chan struct{})
	go func() {
		s.grpcServer.GracefulStop()
		close(stopped)
	}()

	select {
	case <-stopped:
	case <-time.After(timeout):
		log.Printf("[gRPC] Graceful stop timed out after %v; forcing server stop", timeout)
		s.grpcServer.Stop()
	}
}

// Stop forcefully stops the gRPC server.
func (s *Server) Stop() {
	s.grpcServer.Stop()
}

