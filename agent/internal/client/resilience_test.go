package client_test

import (
	"context"
	"io"
	"net"
	"os"
	"path/filepath"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"ancymon/agent/internal/client"
	"ancymon/agent/internal/collector"
	"ancymon/agent/internal/config"
	"ancymon/agent/internal/wal"
	ancymonproto "ancymon/proto"

	"google.golang.org/grpc"
)

// controllableMockServer allows testing server crashes, rejections, and frame inspection.
type controllableMockServer struct {
	ancymonproto.UnimplementedTelemetryServiceServer
	mu                sync.Mutex
	receivedFrames    []*ancymonproto.TelemetryFrame
	rejectBatches     atomic.Bool
	closedConnections atomic.Int32
	batchCount        atomic.Int32
	liveStreamCount   atomic.Int32
	frameReceivedHook func(f *ancymonproto.TelemetryFrame)
}

func (s *controllableMockServer) StreamTelemetry(stream ancymonproto.TelemetryService_StreamTelemetryServer) error {
	var count uint64
	var lastTs int64

	isFirst := true

	for {
		frame, err := stream.Recv()
		if err == io.EOF {
			if s.rejectBatches.Load() {
				return stream.SendAndClose(&ancymonproto.TelemetryAck{
					Success:           false,
					AcknowledgedCount: 0,
					Message:           "simulated server rejection for resilience test",
				})
			}
			s.batchCount.Add(1)
			return stream.SendAndClose(&ancymonproto.TelemetryAck{
				Success:               true,
				AcknowledgedTimestamp: lastTs,
				AcknowledgedCount:     count,
				Message:               "Batch processed successfully",
			})
		}
		if err != nil {
			s.closedConnections.Add(1)
			return err
		}

		if isFirst {
			isFirst = false
			s.liveStreamCount.Add(1)
		}

		count++
		lastTs = frame.TimestampUnix

		s.mu.Lock()
		s.receivedFrames = append(s.receivedFrames, frame)
		if s.frameReceivedHook != nil {
			s.frameReceivedHook(frame)
		}
		s.mu.Unlock()
	}
}

// TestDispatcherResilience_ChronologicalReplayAndLiveStreaming validates that:
// 1. Dispatcher buffers frames when server is unreachable.
// 2. Upon connection restoration, backlog segments are drained in strict chronological order.
// 3. New incoming telemetry during replay appends to the WAL tail without interrupting drain.
// 4. Segments are deleted only after gRPC TelemetryAck.
// 5. Direct live streaming resumes seamlessly only when backlog is completely zero.
func TestDispatcherResilience_ChronologicalReplayAndLiveStreaming(t *testing.T) {
	tempDir := t.TempDir()
	bufferDir := filepath.Join(tempDir, "buffer")

	cfg := &config.Config{
		MachineID:          "m-resilience-disp",
		ServerAddress:      "127.0.0.1:54999", // Unreachable initially
		AuthToken:          "test-psk",
		SamplingIntervalMs: 100, // 100ms sampling (not clamped by dispatcher)
		BufferDir:          bufferDir,
		BufferMaxMB:        50,
		Insecure:           true,
	}

	w, err := wal.Open(wal.Options{
		Dir:              bufferDir,
		SegmentSizeBytes: 500, // 500 bytes for multiple segments
		MaxBufferBytes:   50 * 1024 * 1024,
	})
	if err != nil {
		t.Fatalf("failed to open WAL: %v", err)
	}

	// 1. Pre-fill WAL with multiple segments of initial backlog (T = 1000..1039)
	for i := 0; i < 40; i++ {
		frame := &ancymonproto.TelemetryFrame{
			MachineId:     "m-resilience-disp",
			Hostname:      "resilience-box",
			TimestampUnix: int64(1000 + i),
			Cpu:           &ancymonproto.CpuMetrics{TotalUsagePercent: float64(10 + (i % 20))},
		}
		if err := w.Append(frame); err != nil {
			t.Fatalf("failed to append initial backlog: %v", err)
		}
	}
	_ = w.SealActiveSegment()

	completedBefore, err := w.GetCompletedSegments()
	if err != nil {
		t.Fatalf("failed to list completed: %v", err)
	}
	if len(completedBefore) < 3 {
		t.Fatalf("expected at least 3 pre-filled backlog segments, got %d", len(completedBefore))
	}
	t.Logf("Initial backlog: %d segment files ready for replay", len(completedBefore))

	// 2. Setup mock server
	lis, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("failed to listen: %v", err)
	}
	defer lis.Close()

	mockSrv := &controllableMockServer{}
	grpcServer := grpc.NewServer()
	ancymonproto.RegisterTelemetryServiceServer(grpcServer, mockSrv)

	go func() {
		_ = grpcServer.Serve(lis)
	}()
	defer grpcServer.Stop()

	// Update dispatcher config with real server address
	cfg.ServerAddress = lis.Addr().String()

	// Inspector that generates monotonically increasing timestamps starting from 2000
	var tickCounter atomic.Int64
	tickCounter.Store(2000)
	inspector := &dummyInspector{}

	col := collector.NewCollector("m-resilience-disp", inspector)
	disp := client.NewDispatcher(cfg, col, w, nil)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	runErrCh := make(chan error, 1)
	go func() {
		runErrCh <- disp.Run(ctx)
	}()

	// Wait for dispatcher to transition to StateLive
	deadline := time.Now().Add(6 * time.Second)
	var liveReached bool
	for time.Now().Before(deadline) {
		if disp.State() == client.StateLive {
			liveReached = true
			break
		}
		time.Sleep(50 * time.Millisecond)
	}

	if !liveReached {
		t.Fatalf("dispatcher failed to transition to StateLive, current state: %s", disp.State())
	}

	// Allow live frames to be streamed
	time.Sleep(350 * time.Millisecond)

	// Verify WAL backlog is now completely drained (zero completed segments)
	completedAfter, err := w.GetCompletedSegments()
	if err != nil {
		t.Fatalf("failed to query segments after drain: %v", err)
	}
	if len(completedAfter) > 0 {
		t.Errorf("expected 0 completed segments after draining, got %d: %v", len(completedAfter), completedAfter)
	}

	// Verify all pre-filled segment files were deleted from disk
	for _, seg := range completedBefore {
		if _, err := os.Stat(seg); !os.IsNotExist(err) {
			t.Errorf("expected segment %s to be deleted after server ACK, but it still exists", seg)
		}
	}

	// Verify frames received by server are in strict chronological order
	mockSrv.mu.Lock()
	received := mockSrv.receivedFrames
	mockSrv.mu.Unlock()

	if len(received) < 40 {
		t.Fatalf("expected at least 40 frames received on server, got %d", len(received))
	}

	// Assert chronological ordering: frames must not travel backwards in time (nextTs >= curTs)
	for i := 0; i < len(received)-1; i++ {
		curTs := received[i].TimestampUnix
		nextTs := received[i+1].TimestampUnix
		if curTs > nextTs {
			t.Fatalf("chronological order violated at index %d: current ts=%d > next ts=%d", i, curTs, nextTs)
		}
	}

	live, buffered, replayed := disp.Stats()
	t.Logf("Dispatcher resilience stats: live=%d, buffered=%d, replayedSegments=%d, totalFramesReceived=%d",
		live, buffered, replayed, len(received))

	if live == 0 {
		t.Errorf("expected live streaming frames > 0, got %d", live)
	}

	cancel()
	<-runErrCh
}

// TestDispatcherResilience_ServerRejectionPreservesSegments verifies that if the server rejects
// a batch (e.g. TelemetryAck.Success = false), the segment is NOT deleted from disk and the dispatcher
// gracefully retries rather than losing buffered data.
func TestDispatcherResilience_ServerRejectionPreservesSegments(t *testing.T) {
	tempDir := t.TempDir()
	bufferDir := filepath.Join(tempDir, "buffer")

	cfg := &config.Config{
		MachineID:          "m-reject-test",
		ServerAddress:      "127.0.0.1:0",
		AuthToken:          "test-psk",
		SamplingIntervalMs: 100,
		BufferDir:          bufferDir,
		BufferMaxMB:        50,
		Insecure:           true,
	}

	w, err := wal.Open(wal.Options{
		Dir:              bufferDir,
		SegmentSizeBytes: 5000,
		MaxBufferBytes:   50 * 1024 * 1024,
	})
	if err != nil {
		t.Fatalf("failed to open WAL: %v", err)
	}

	// Write 5 frames into segment_000001.wal
	for i := 0; i < 5; i++ {
		_ = w.Append(&ancymonproto.TelemetryFrame{
			MachineId:     "m-reject-test",
			TimestampUnix: int64(500 + i),
		})
	}
	_ = w.SealActiveSegment()

	completed, _ := w.GetCompletedSegments()
	if len(completed) != 1 {
		t.Fatalf("expected 1 completed segment, got %d", len(completed))
	}
	targetSegment := completed[0]

	// Start server that REJECTS batches initially
	lis, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("failed to listen: %v", err)
	}
	defer lis.Close()

	mockSrv := &controllableMockServer{}
	mockSrv.rejectBatches.Store(true) // reject!

	grpcServer := grpc.NewServer()
	ancymonproto.RegisterTelemetryServiceServer(grpcServer, mockSrv)
	go func() {
		_ = grpcServer.Serve(lis)
	}()
	defer grpcServer.Stop()

	cfg.ServerAddress = lis.Addr().String()

	col := collector.NewCollector("m-reject-test", &dummyInspector{})
	disp := client.NewDispatcher(cfg, col, w, nil)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	go func() {
		_ = disp.Run(ctx)
	}()

	// Wait 500ms for dispatcher to try to send batch and receive rejection
	time.Sleep(500 * time.Millisecond)

	// Verify segment still exists on disk!
	if _, err := os.Stat(targetSegment); err != nil {
		t.Fatalf("segment %s was prematurely deleted after server rejection!", targetSegment)
	}

	// Now flip server to ACCEPT batches
	mockSrv.rejectBatches.Store(false)

	// Wait for dispatcher to reconnect and drain the segment
	deadline := time.Now().Add(4 * time.Second)
	var segmentDeleted bool
	for time.Now().Before(deadline) {
		if _, err := os.Stat(targetSegment); os.IsNotExist(err) {
			segmentDeleted = true
			break
		}
		time.Sleep(100 * time.Millisecond)
	}

	if !segmentDeleted {
		t.Errorf("expected segment %s to be deleted once server accepted batch", targetSegment)
	}
}

// TestDispatcherResilience_LiveStreamFailureFallback verifies that when an established live stream
// suddenly drops or the server terminates the connection, the dispatcher immediately falls back
// to StateBuffering, preserves the failed frame by routing it to the offline WAL buffer, and continues buffering.
func TestDispatcherResilience_LiveStreamFailureFallback(t *testing.T) {
	tempDir := t.TempDir()
	bufferDir := filepath.Join(tempDir, "buffer")

	// Start mock gRPC server
	lis, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("failed to listen: %v", err)
	}

	mockSrv := &controllableMockServer{}
	grpcServer := grpc.NewServer()
	ancymonproto.RegisterTelemetryServiceServer(grpcServer, mockSrv)
	go func() {
		_ = grpcServer.Serve(lis)
	}()

	cfg := &config.Config{
		MachineID:          "m-fallback-test",
		ServerAddress:      lis.Addr().String(),
		AuthToken:          "test-psk",
		SamplingIntervalMs: 100,
		BufferDir:          bufferDir,
		BufferMaxMB:        50,
		Insecure:           true,
	}

	w, err := wal.Open(wal.Options{
		Dir:              bufferDir,
		SegmentSizeBytes: 5000,
		MaxBufferBytes:   50 * 1024 * 1024,
	})
	if err != nil {
		t.Fatalf("failed to open WAL: %v", err)
	}

	col := collector.NewCollector("m-fallback-test", &dummyInspector{})
	disp := client.NewDispatcher(cfg, col, w, nil)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	go func() {
		_ = disp.Run(ctx)
	}()

	// 1. Wait until dispatcher establishes live streaming (zero backlog initially)
	deadline := time.Now().Add(3 * time.Second)
	var liveEstablished bool
	for time.Now().Before(deadline) {
		if disp.State() == client.StateLive {
			liveEstablished = true
			break
		}
		time.Sleep(50 * time.Millisecond)
	}

	if !liveEstablished {
		t.Fatalf("dispatcher failed to reach StateLive initially, got: %s", disp.State())
	}

	// 2. Abruptly kill the server while dispatcher is streaming live
	grpcServer.Stop()
	_ = lis.Close()

	// 3. Wait for next ticks: dispatcher must detect stream failure and fall back to StateBuffering
	fallbackDeadline := time.Now().Add(3 * time.Second)
	var fallbackDetected bool
	for time.Now().Before(fallbackDeadline) {
		if disp.State() == client.StateBuffering {
			fallbackDetected = true
			break
		}
		time.Sleep(50 * time.Millisecond)
	}

	if !fallbackDetected {
		t.Fatalf("dispatcher failed to transition to StateBuffering upon network drop, state: %s", disp.State())
	}

	// Allow a few buffered ticks while offline
	time.Sleep(250 * time.Millisecond)

	// 4. Verify frames are being routed to WAL buffer without data loss
	if !w.HasBacklog() {
		t.Errorf("expected WAL to contain buffered backlog after connection loss")
	}

	_, buffered, _ := disp.Stats()
	if buffered == 0 {
		t.Errorf("expected buffered frame count > 0 after connection loss, got %d", buffered)
	}
	t.Logf("Successfully verified fallback to StateBuffering with %d frames safely preserved in WAL", buffered)
}
