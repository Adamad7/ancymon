package wal_test

import (
	"fmt"
	"math/rand"
	"os"
	"path/filepath"
	"runtime"
	"testing"
	"time"

	"ancymon/agent/internal/wal"
	ancymonproto "ancymon/proto"
)

// generateRealisticFrame creates a realistic TelemetryFrame with disk partitions, CPU, memory, and network data.
func generateRealisticFrame(machineID string, timestamp int64, seq int) *ancymonproto.TelemetryFrame {
	temp := 42.0 + float64(seq%20)
	cpuPercent := 15.0 + float64(seq%70)
	rxBytes := uint64(1024 * (10 + (seq % 50)))
	txBytes := uint64(512 * (10 + (seq % 30)))

	disks := []*ancymonproto.DiskPartitionMetrics{
		{
			MountPoint:   "/",
			FsType:       "ext4",
			TotalBytes:   500 * 1024 * 1024 * 1024,
			FreeBytes:    250 * 1024 * 1024 * 1024,
			UsagePercent: 50.0,
		},
		{
			MountPoint:   "/home",
			FsType:       "btrfs",
			TotalBytes:   1000 * 1024 * 1024 * 1024,
			FreeBytes:    600 * 1024 * 1024 * 1024,
			UsagePercent: 40.0,
		},
		{
			MountPoint:   "/var/log",
			FsType:       "xfs",
			TotalBytes:   100 * 1024 * 1024 * 1024,
			FreeBytes:    70 * 1024 * 1024 * 1024,
			UsagePercent: 30.0,
		},
	}

	return &ancymonproto.TelemetryFrame{
		MachineId:     machineID,
		Hostname:      "workstation-resilience-01",
		TimestampUnix: timestamp,
		Cpu: &ancymonproto.CpuMetrics{
			TotalUsagePercent: cpuPercent,
			TemperatureC:      &temp,
		},
		Memory: &ancymonproto.MemoryMetrics{
			TotalBytes:   32 * 1024 * 1024 * 1024,
			UsedBytes:    12 * 1024 * 1024 * 1024,
			UsagePercent: 37.5,
		},
		Network: &ancymonproto.NetworkMetrics{
			RxBytesPerSec: rxBytes,
			TxBytesPerSec: txBytes,
		},
		Disks: disks,
	}
}

// TestWALResilience_LongDisconnectionContinuousBuffering simulates a prolonged network outage
// where continuous 1 Hz frames are reliably appended to the offline WAL buffer.
func TestWALResilience_LongDisconnectionContinuousBuffering(t *testing.T) {
	tempDir := t.TempDir()
	bufferDir := filepath.Join(tempDir, "buffer")

	segmentSize := int64(10 * 1024) // 10 KB per segment for fast rotation in test
	maxCeiling := int64(500 * 1024) // 500 KB ceiling

	w, err := wal.Open(wal.Options{
		Dir:              bufferDir,
		SegmentSizeBytes: segmentSize,
		MaxBufferBytes:   maxCeiling,
	})
	if err != nil {
		t.Fatalf("failed to initialize WAL: %v", err)
	}
	defer w.Close()

	totalFrames := 500
	baseTimestamp := time.Now().Unix() - int64(totalFrames)

	// Simulate continuous 1 Hz incoming frames during an extended outage
	for i := 0; i < totalFrames; i++ {
		frame := generateRealisticFrame("m-resilience-01", baseTimestamp+int64(i), i)
		if err := w.Append(frame); err != nil {
			t.Fatalf("failed to append frame %d during simulated outage: %v", i, err)
		}
	}

	if err := w.SealActiveSegment(); err != nil {
		t.Fatalf("failed to seal active segment: %v", err)
	}

	completed, err := w.GetCompletedSegments()
	if err != nil {
		t.Fatalf("failed to list completed segments: %v", err)
	}

	if len(completed) < 3 {
		t.Fatalf("expected at least 3 completed segment files from %d frames, got %d", totalFrames, len(completed))
	}

	// Verify all completed segment files match naming convention: segment_XXXXXX.wal
	for _, segPath := range completed {
		base := filepath.Base(segPath)
		if len(base) != 18 || base[:8] != "segment_" || base[14:] != ".wal" {
			t.Errorf("segment file name %s does not match expected format segment_XXXXXX.wal", base)
		}
	}

	// Read and verify all frames from all completed segments
	var readCount int
	var lastTs int64
	for _, segPath := range completed {
		frames, err := wal.ReadSegment(segPath)
		if err != nil {
			t.Fatalf("failed to read segment %s: %v", segPath, err)
		}
		for _, f := range frames {
			if f.MachineId != "m-resilience-01" {
				t.Errorf("expected machine ID m-resilience-01, got %s", f.MachineId)
			}
			if f.TimestampUnix <= lastTs {
				t.Fatalf("frames not strictly chronological: previous ts=%d, current ts=%d", lastTs, f.TimestampUnix)
			}
			lastTs = f.TimestampUnix
			readCount++
		}
	}

	if readCount == 0 {
		t.Fatal("expected non-zero frames read from completed segments")
	}
	t.Logf("Successfully verified %d continuously buffered frames across %d segment files", readCount, len(completed))
}

// TestWALResilience_SegmentRotationAtOneMB validates rotation specifically at the 1 MB default boundary.
func TestWALResilience_SegmentRotationAtOneMB(t *testing.T) {
	tempDir := t.TempDir()
	bufferDir := filepath.Join(tempDir, "buffer")

	oneMB := wal.DefaultSegmentSizeBytes // 1 MB
	w, err := wal.Open(wal.Options{
		Dir:              bufferDir,
		SegmentSizeBytes: oneMB,
		MaxBufferBytes:   50 * oneMB,
	})
	if err != nil {
		t.Fatalf("failed to open WAL: %v", err)
	}
	defer w.Close()

	// Create frames with ~10 KB payload (by adding simulated disk partitions) to cross 1 MB quickly
	var extraDisks []*ancymonproto.DiskPartitionMetrics
	for j := 0; j < 80; j++ {
		extraDisks = append(extraDisks, &ancymonproto.DiskPartitionMetrics{
			MountPoint:   fmt.Sprintf("/mnt/volume_extra_storage_partition_%03d", j),
			FsType:       "ext4",
			TotalBytes:   1024 * 1024 * 1024 * 100,
			FreeBytes:    1024 * 1024 * 1024 * 50,
			UsagePercent: 50.0,
		})
	}

	// Append frames until we cross 1 MB and cause rotation into segment_000002.wal
	var framesWritten int
	var rotated bool
	baseTs := int64(1700000000)

	for i := 0; i < 300; i++ {
		frame := generateRealisticFrame("m-1mb", baseTs+int64(i), i)
		frame.Disks = append(frame.Disks, extraDisks...)

		if err := w.Append(frame); err != nil {
			t.Fatalf("failed to append frame %d: %v", i, err)
		}
		framesWritten++

		// Check if segment_000002.wal has been created on disk
		seg2Path := filepath.Join(bufferDir, "segment_000002.wal")
		if _, err := os.Stat(seg2Path); err == nil {
			rotated = true
			break
		}
	}

	if !rotated {
		t.Fatal("expected WAL to rotate into segment_000002.wal after exceeding 1 MB")
	}

	// Verify segment_000001.wal is close to 1 MB
	seg1Path := filepath.Join(bufferDir, "segment_000001.wal")
	info1, err := os.Stat(seg1Path)
	if err != nil {
		t.Fatalf("failed to stat segment_000001.wal: %v", err)
	}

	if info1.Size() > oneMB+32*1024 {
		t.Errorf("segment 1 size %d exceeds 1 MB by more than one frame tolerance", info1.Size())
	}
	if info1.Size() < oneMB-64*1024 {
		t.Errorf("segment 1 size %d rotated prematurely before approaching 1 MB", info1.Size())
	}

	// Verify frames in segment_000001 can be cleanly deserialized
	frames1, err := wal.ReadSegment(seg1Path)
	if err != nil {
		t.Fatalf("failed to read rotated segment 1: %v", err)
	}
	if len(frames1) == 0 {
		t.Fatal("expected frames in rotated segment 1")
	}

	t.Logf("1 MB rotation verified: segment_000001.wal reached %d bytes (%d frames) before segment_000002.wal opened",
		info1.Size(), len(frames1))
}

// TestWALResilience_ConstantRAMProfile verifies that process heap memory stays completely flat
// when buffering thousands of telemetry frames, without caching or leaking frames in RAM.
func TestWALResilience_ConstantRAMProfile(t *testing.T) {
	tempDir := t.TempDir()
	bufferDir := filepath.Join(tempDir, "buffer")

	w, err := wal.Open(wal.Options{
		Dir:              bufferDir,
		SegmentSizeBytes: 50 * 1024,       // 50 KB per segment
		MaxBufferBytes:   50 * 1024 * 1024, // 50 MB ceiling
	})
	if err != nil {
		t.Fatalf("failed to open WAL: %v", err)
	}
	defer w.Close()

	// Force initial GC to establish clean baseline
	runtime.GC()
	var memBefore runtime.MemStats
	runtime.ReadMemStats(&memBefore)

	const frameCount = 3000
	baseTs := time.Now().Unix()

	for i := 0; i < frameCount; i++ {
		frame := generateRealisticFrame("m-mem-profile", baseTs+int64(i), i)
		if err := w.Append(frame); err != nil {
			t.Fatalf("failed to append frame %d: %v", i, err)
		}
	}

	// Force GC after writing 3000 frames
	runtime.GC()
	var memAfter runtime.MemStats
	runtime.ReadMemStats(&memAfter)

	// HeapAlloc must remain very low and flat (well under 15 MB)
	heapAllocMB := float64(memAfter.HeapAlloc) / (1024 * 1024)
	heapInuseMB := float64(memAfter.HeapInuse) / (1024 * 1024)

	t.Logf("Memory Profile after %d frames: HeapAlloc=%.2f MB, HeapInuse=%.2f MB, Sys=%.2f MB",
		frameCount, heapAllocMB, heapInuseMB, float64(memAfter.Sys)/(1024*1024))

	// Specification requires ~10-15 MB RAM maximum footprint
	if heapAllocMB > 15.0 {
		t.Errorf("HeapAlloc %.2f MB exceeds flat RAM specification (< 15 MB)", heapAllocMB)
	}
	if heapInuseMB > 20.0 {
		t.Errorf("HeapInuse %.2f MB exceeds flat RAM specification (< 20 MB)", heapInuseMB)
	}
}

// TestWALResilience_HardCeilingAndFIFOEviction verifies that when the total buffer directory size
// exceeds the ceiling, the oldest completed segment file is evicted in strict FIFO order,
// and disk usage stays capped.
func TestWALResilience_HardCeilingAndFIFOEviction(t *testing.T) {
	tempDir := t.TempDir()
	bufferDir := filepath.Join(tempDir, "buffer")

	segmentSize := int64(4 * 1024) // 4 KB segment
	ceilingSize := int64(20 * 1024) // 20 KB ceiling (~5 segments max)

	w, err := wal.Open(wal.Options{
		Dir:              bufferDir,
		SegmentSizeBytes: segmentSize,
		MaxBufferBytes:   ceilingSize,
	})
	if err != nil {
		t.Fatalf("failed to open WAL: %v", err)
	}
	defer w.Close()

	// Write enough frames to generate ~15-20 segments (way above the 5-segment ceiling)
	baseTs := int64(10000)
	for i := 0; i < 150; i++ {
		frame := generateRealisticFrame("m-fifo", baseTs+int64(i), i)
		if err := w.Append(frame); err != nil {
			t.Fatalf("failed to append frame %d: %v", i, err)
		}
	}
	_ = w.SealActiveSegment()

	// Read directory on disk
	entries, err := os.ReadDir(bufferDir)
	if err != nil {
		t.Fatalf("failed to read buffer directory: %v", err)
	}

	var totalSize int64
	var foundFiles []string
	for _, entry := range entries {
		info, err := entry.Info()
		if err != nil {
			continue
		}
		totalSize += info.Size()
		foundFiles = append(foundFiles, entry.Name())
	}

	t.Logf("Remaining segment files (%d): %v, total size on disk: %d bytes (ceiling: %d bytes)",
		len(foundFiles), foundFiles, totalSize, ceilingSize)

	// Verify total size on disk is constrained within ceiling (+ 1 segment rotation buffer)
	if totalSize > ceilingSize+segmentSize {
		t.Errorf("total buffer size %d exceeded ceiling %d + segment margin", totalSize, ceilingSize)
	}

	// Strict FIFO verification:
	// segment_000001.wal, segment_000002.wal, segment_000003.wal MUST have been evicted!
	for _, evictedFile := range []string{"segment_000001.wal", "segment_000002.wal", "segment_000003.wal"} {
		evictedPath := filepath.Join(bufferDir, evictedFile)
		if _, err := os.Stat(evictedPath); !os.IsNotExist(err) {
			t.Errorf("expected %s to have been deleted via FIFO eviction, but file still exists", evictedFile)
		}
	}

	// Verify remaining completed segments are strictly sorted chronologically
	completed, err := w.GetCompletedSegments()
	if err != nil {
		t.Fatalf("failed to get completed segments: %v", err)
	}

	var prevIdx uint64
	for _, seg := range completed {
		var idx uint64
		_, err := fmt.Sscanf(filepath.Base(seg), "segment_%d.wal", &idx)
		if err != nil {
			t.Fatalf("failed to parse index from %s: %v", seg, err)
		}
		if idx <= prevIdx {
			t.Errorf("segments not strictly ascending: %d <= %d", idx, prevIdx)
		}
		prevIdx = idx
	}
}

// TestWALResilience_CorruptedTailRecovery verifies that an unexpected power cut / truncated frame
// at the tail of a segment file does not prevent recovering all previously committed frames.
func TestWALResilience_CorruptedTailRecovery(t *testing.T) {
	tempDir := t.TempDir()
	bufferDir := filepath.Join(tempDir, "buffer")

	w, err := wal.Open(wal.Options{
		Dir:              bufferDir,
		SegmentSizeBytes: 50 * 1024,
		MaxBufferBytes:   10 * 1024 * 1024,
	})
	if err != nil {
		t.Fatalf("failed to open WAL: %v", err)
	}

	// Append 10 valid frames
	for i := 0; i < 10; i++ {
		frame := generateRealisticFrame("m-corrupt-tail", int64(100+i), i)
		_ = w.Append(frame)
	}
	_ = w.SealActiveSegment()
	_ = w.Close()

	segPath := filepath.Join(bufferDir, "segment_000001.wal")

	// Corrupt file by appending 3 bytes of garbage (simulating interrupted write of 4-byte header)
	f, err := os.OpenFile(segPath, os.O_WRONLY|os.O_APPEND, 0o600)
	if err != nil {
		t.Fatalf("failed to open segment for corruption: %v", err)
	}
	garbage := make([]byte, 3)
	rand.Read(garbage)
	_, _ = f.Write(garbage)
	_ = f.Close()

	// Read segment: must gracefully return all 10 valid frames
	frames, err := wal.ReadSegment(segPath)
	if err != nil {
		t.Fatalf("unexpected fatal error on corrupted tail: %v", err)
	}
	if len(frames) != 10 {
		t.Fatalf("expected 10 recovered frames before corrupted tail, got %d", len(frames))
	}

	for i, f := range frames {
		if f.TimestampUnix != int64(100+i) {
			t.Errorf("frame %d timestamp mismatch: got %d, expected %d", i, f.TimestampUnix, 100+i)
		}
	}
}
