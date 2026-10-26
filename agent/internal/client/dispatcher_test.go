package client_test

import (
	"context"
	"path/filepath"
	"sync/atomic"
	"testing"
	"time"

	"ancymon/agent/internal/client"
	"ancymon/agent/internal/collector"
	"ancymon/agent/internal/config"
	"ancymon/agent/internal/wal"
	ancymonproto "ancymon/proto"

	"github.com/shirou/gopsutil/v3/disk"
	"github.com/shirou/gopsutil/v3/mem"
)

type dummyInspector struct {
	tickCounter atomic.Int64
}

func (d *dummyInspector) CPUPercent() (float64, error) {
	return 25.0, nil
}
func (d *dummyInspector) CPUTemperature() (*float64, error) {
	temp := 40.0
	return &temp, nil
}
func (d *dummyInspector) VirtualMemory() (*mem.VirtualMemoryStat, error) {
	return &mem.VirtualMemoryStat{Total: 8000, Used: 2000, UsedPercent: 25.0}, nil
}
func (d *dummyInspector) NetIOCounters() (uint64, uint64, error) {
	c := uint64(d.tickCounter.Add(1) * 1000)
	return c, c, nil
}
func (d *dummyInspector) Partitions() ([]disk.PartitionStat, error) {
	return []disk.PartitionStat{{Mountpoint: "/", Fstype: "ext4"}}, nil
}
func (d *dummyInspector) DiskUsage(path string) (*disk.UsageStat, error) {
	return &disk.UsageStat{Total: 100000, Free: 50000, UsedPercent: 50.0}, nil
}
func (d *dummyInspector) Hostname() (string, error) {
	return "dispatcher-test-host", nil
}

func TestDispatcher_OfflineBufferingToLiveStreamTransition(t *testing.T) {
	tempDir := t.TempDir()
	bufferDir := filepath.Join(tempDir, "buffer")

	cfg := &config.Config{
		MachineID:          "m-disp-1",
		ServerAddress:      "127.0.0.1:54321", // non-existent initially
		AuthToken:          "disp-token",
		SamplingIntervalMs: 50,                // 50ms ticks for test speed
		BufferDir:          bufferDir,
		BufferMaxMB:        50,
		Insecure:           true,
	}

	col := collector.NewCollector("m-disp-1", &dummyInspector{})

	w, err := wal.Open(wal.Options{
		Dir:              bufferDir,
		SegmentSizeBytes: 5000,
		MaxBufferBytes:   50 * 1024 * 1024,
	})
	if err != nil {
		t.Fatalf("failed to open WAL: %v", err)
	}

	// Pre-populate WAL with some offline backlog
	for i := 0; i < 5; i++ {
		_ = w.Append(&ancymonproto.TelemetryFrame{
			MachineId:     "m-disp-1",
			Hostname:      "dispatcher-test-host",
			TimestampUnix: int64(100 + i),
			Cpu:           &ancymonproto.CpuMetrics{TotalUsagePercent: float64(10 + i)},
		})
	}
	_ = w.SealActiveSegment()

	if !w.HasBacklog() {
		t.Fatal("expected backlog to be present before starting server")
	}

	// Start mock gRPC server
	srv, addr, cleanup := startMockGRPCServer(t)
	defer cleanup()

	// Update config server address to actual mock server address
	cfg.ServerAddress = addr

	disp := client.NewDispatcher(cfg, col, w, nil)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	dispErrCh := make(chan error, 1)
	go func() {
		dispErrCh <- disp.Run(ctx)
	}()

	// Wait for dispatcher to connect, replay WAL, and transition to StateLive
	deadline := time.Now().Add(5 * time.Second)
	transitioned := false
	for time.Now().Before(deadline) {
		if disp.State() == client.StateLive {
			transitioned = true
			break
		}
		time.Sleep(50 * time.Millisecond)
	}

	if !transitioned {
		t.Fatalf("dispatcher failed to transition to StateLive, current state: %s", disp.State())
	}

	// Allow a few live frames to be emitted
	time.Sleep(200 * time.Millisecond)

	// Backlog in WAL should now be 0
	if w.HasBacklog() {
		t.Errorf("expected WAL backlog to be 0 after replay")
	}

	// Verify server received replayed frames + live frames
	srv.mu.Lock()
	receivedCount := len(srv.receivedFrames)
	srv.mu.Unlock()

	if receivedCount < 5 {
		t.Errorf("expected at least 5 frames received on server, got %d", receivedCount)
	}

	cancel()
	<-dispErrCh
}
