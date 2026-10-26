package wal_test

import (
	"os"
	"path/filepath"
	"testing"

	"ancymon/agent/internal/wal"
	ancymonproto "ancymon/proto"
)

func createTestFrame(id string, timestamp int64, cpuUsage float64) *ancymonproto.TelemetryFrame {
	temp := 45.0
	return &ancymonproto.TelemetryFrame{
		MachineId:     id,
		Hostname:      "test-host",
		TimestampUnix: timestamp,
		Cpu: &ancymonproto.CpuMetrics{
			TotalUsagePercent: cpuUsage,
			TemperatureC:      &temp,
		},
		Memory: &ancymonproto.MemoryMetrics{
			TotalBytes:   16000000000,
			UsedBytes:    4000000000,
			UsagePercent: 25.0,
		},
		Network: &ancymonproto.NetworkMetrics{
			RxBytesPerSec: 1024,
			TxBytesPerSec: 512,
		},
	}
}

func TestWAL_AppendAndReadSegment(t *testing.T) {
	tempDir := t.TempDir()

	w, err := wal.Open(wal.Options{
		Dir:              tempDir,
		SegmentSizeBytes: 1024 * 1024,
		MaxBufferBytes:   50 * 1024 * 1024,
	})
	if err != nil {
		t.Fatalf("failed to open WAL: %v", err)
	}
	defer w.Close()

	frame1 := createTestFrame("m-1", 1000, 15.5)
	frame2 := createTestFrame("m-1", 1001, 20.0)

	if err := w.Append(frame1); err != nil {
		t.Fatalf("failed to append frame 1: %v", err)
	}
	if err := w.Append(frame2); err != nil {
		t.Fatalf("failed to append frame 2: %v", err)
	}

	if err := w.SealActiveSegment(); err != nil {
		t.Fatalf("failed to seal active segment: %v", err)
	}

	completed, err := w.GetCompletedSegments()
	if err != nil {
		t.Fatalf("failed to get completed segments: %v", err)
	}
	if len(completed) != 1 {
		t.Fatalf("expected 1 completed segment, got %d", len(completed))
	}

	frames, err := wal.ReadSegment(completed[0])
	if err != nil {
		t.Fatalf("failed to read segment: %v", err)
	}
	if len(frames) != 2 {
		t.Fatalf("expected 2 frames, got %d", len(frames))
	}

	if frames[0].TimestampUnix != 1000 || frames[0].Cpu.TotalUsagePercent != 15.5 {
		t.Errorf("frame 1 mismatch: %+v", frames[0])
	}
	if frames[1].TimestampUnix != 1001 || frames[1].Cpu.TotalUsagePercent != 20.0 {
		t.Errorf("frame 2 mismatch: %+v", frames[1])
	}
}

func TestWAL_SegmentRotation(t *testing.T) {
	tempDir := t.TempDir()

	// Use small segment size to force rapid rotation
	segmentSize := int64(1024) // 1 KB
	w, err := wal.Open(wal.Options{
		Dir:              tempDir,
		SegmentSizeBytes: segmentSize,
		MaxBufferBytes:   100 * 1024,
	})
	if err != nil {
		t.Fatalf("failed to open WAL: %v", err)
	}
	defer w.Close()

	// Append frames until rotation occurs across multiple segments
	for i := 0; i < 40; i++ {
		frame := createTestFrame("m-rotate", int64(1000+i), float64(i*5))
		if err := w.Append(frame); err != nil {
			t.Fatalf("failed to append frame %d: %v", i, err)
		}
	}
	_ = w.SealActiveSegment()

	completed, err := w.GetCompletedSegments()
	if err != nil {
		t.Fatalf("failed to list completed segments: %v", err)
	}

	if len(completed) < 2 {
		t.Fatalf("expected multiple rotated segments, got %d", len(completed))
	}

	// Verify segment naming: segment_000001.wal, segment_000002.wal, ...
	base1 := filepath.Base(completed[0])
	if base1 != "segment_000001.wal" {
		t.Errorf("expected first segment segment_000001.wal, got %s", base1)
	}
}

func TestWAL_FIFOEvictionUnderCeiling(t *testing.T) {
	tempDir := t.TempDir()

	// Total ceiling 3 KB, segment size 1 KB -> can hold at most ~3 segments
	segmentSize := int64(1000)
	maxCeiling := int64(3000)

	w, err := wal.Open(wal.Options{
		Dir:              tempDir,
		SegmentSizeBytes: segmentSize,
		MaxBufferBytes:   maxCeiling,
	})
	if err != nil {
		t.Fatalf("failed to open WAL: %v", err)
	}
	defer w.Close()

	// Write enough frames to generate 5-6 segments
	for i := 0; i < 60; i++ {
		frame := createTestFrame("m-evict", int64(2000+i), 50.0)
		if err := w.Append(frame); err != nil {
			t.Fatalf("failed to append frame %d: %v", i, err)
		}
	}

	// Check total directory size on disk
	entries, err := os.ReadDir(tempDir)
	if err != nil {
		t.Fatalf("failed to read dir: %v", err)
	}

	var totalDiskSize int64
	for _, e := range entries {
		info, err := e.Info()
		if err != nil {
			continue
		}
		totalDiskSize += info.Size()
	}

	// Total disk size should not exceed max ceiling significantly (allowing for active segment overhead)
	if totalDiskSize > maxCeiling+segmentSize {
		t.Errorf("total disk size %d exceeded ceiling %d", totalDiskSize, maxCeiling)
	}

	// Oldest segment (segment_000001.wal) should have been evicted!
	firstSegmentPath := filepath.Join(tempDir, "segment_000001.wal")
	if _, err := os.Stat(firstSegmentPath); !os.IsNotExist(err) {
		t.Errorf("expected oldest segment segment_000001.wal to be evicted via FIFO, but it still exists")
	}
}

func TestWAL_ChronologicalReplayAndAckDeletion(t *testing.T) {
	tempDir := t.TempDir()

	w, err := wal.Open(wal.Options{
		Dir:              tempDir,
		SegmentSizeBytes: 1024,
		MaxBufferBytes:   50 * 1024 * 1024,
	})
	if err != nil {
		t.Fatalf("failed to open WAL: %v", err)
	}

	// Emit frames with strictly increasing timestamps
	for i := 0; i < 15; i++ {
		frame := createTestFrame("m-replay", int64(1700000000+i), float64(10+i))
		if err := w.Append(frame); err != nil {
			t.Fatalf("failed to append: %v", err)
		}
	}
	_ = w.SealActiveSegment()

	completed, err := w.GetCompletedSegments()
	if err != nil {
		t.Fatalf("failed to get completed: %v", err)
	}
	if len(completed) == 0 {
		t.Fatal("expected completed segments")
	}

	var lastTimestamp int64 = 0
	totalReplayedFrames := 0

	for _, segPath := range completed {
		frames, err := wal.ReadSegment(segPath)
		if err != nil {
			t.Fatalf("failed to read segment %s: %v", segPath, err)
		}

		for _, f := range frames {
			if f.TimestampUnix <= lastTimestamp {
				t.Fatalf("chronological order violated: got %d after %d", f.TimestampUnix, lastTimestamp)
			}
			lastTimestamp = f.TimestampUnix
			totalReplayedFrames++
		}

		// Simulate server ACK -> delete segment
		if err := w.DeleteSegment(segPath); err != nil {
			t.Fatalf("failed to delete segment %s: %v", segPath, err)
		}

		// Verify file no longer exists
		if _, err := os.Stat(segPath); !os.IsNotExist(err) {
			t.Errorf("expected segment %s to be deleted after ACK", segPath)
		}
	}

	if totalReplayedFrames != 15 {
		t.Errorf("expected 15 replayed frames, got %d", totalReplayedFrames)
	}

	if w.HasBacklog() {
		t.Errorf("expected zero backlog after draining all segments")
	}
	_ = w.Close()
}

func TestWAL_CrashRecovery(t *testing.T) {
	tempDir := t.TempDir()

	// 1. First run: append frames and close abruptly without sealing
	w1, err := wal.Open(wal.Options{
		Dir:              tempDir,
		SegmentSizeBytes: 1024 * 1024,
		MaxBufferBytes:   50 * 1024 * 1024,
	})
	if err != nil {
		t.Fatalf("failed to open WAL: %v", err)
	}

	for i := 0; i < 5; i++ {
		frame := createTestFrame("m-recover", int64(100+i), 10.0)
		_ = w1.Append(frame)
	}
	_ = w1.Close()

	// 2. Second run: recover existing WAL and append 5 more frames
	w2, err := wal.Open(wal.Options{
		Dir:              tempDir,
		SegmentSizeBytes: 1024 * 1024,
		MaxBufferBytes:   50 * 1024 * 1024,
	})
	if err != nil {
		t.Fatalf("failed to recover WAL: %v", err)
	}

	for i := 5; i < 10; i++ {
		frame := createTestFrame("m-recover", int64(100+i), 20.0)
		_ = w2.Append(frame)
	}
	_ = w2.SealActiveSegment()

	completed, err := w2.GetCompletedSegments()
	if err != nil {
		t.Fatalf("failed to get completed segments: %v", err)
	}
	if len(completed) != 1 {
		t.Fatalf("expected 1 recovered segment, got %d", len(completed))
	}

	frames, err := wal.ReadSegment(completed[0])
	if err != nil {
		t.Fatalf("failed to read recovered segment: %v", err)
	}
	if len(frames) != 10 {
		t.Fatalf("expected 10 combined frames after recovery, got %d", len(frames))
	}

	// Verify timestamps are 100 through 109
	for i, f := range frames {
		expectedTs := int64(100 + i)
		if f.TimestampUnix != expectedTs {
			t.Errorf("frame %d expected timestamp %d, got %d", i, expectedTs, f.TimestampUnix)
		}
	}
	_ = w2.Close()
}
