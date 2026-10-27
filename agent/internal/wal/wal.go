package wal

import (
	"encoding/binary"
	"errors"
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"sync"

	ancymonproto "ancymon/proto"

	"google.golang.org/protobuf/proto"
)

const (
	// DefaultSegmentSizeBytes is 1 MB per segment file.
	DefaultSegmentSizeBytes int64 = 1 * 1024 * 1024

	// DefaultMaxBufferSizeBytes is 50 MB ceiling for the entire WAL directory.
	DefaultMaxBufferSizeBytes int64 = 50 * 1024 * 1024

	// SegmentFilePrefix and format.
	segmentPattern = `^segment_(\d{6})\.wal$`
)

var segmentRegex = regexp.MustCompile(segmentPattern)

// Options configures the WAL buffer behavior.
type Options struct {
	Dir              string
	MaxBufferBytes   int64
	SegmentSizeBytes int64
}

// WAL represents a thread-safe offline segmented Write-Ahead Log buffer.
type WAL struct {
	mu               sync.Mutex
	dir              string
	maxBufferBytes   int64
	segmentSizeBytes int64

	activeFile       *os.File
	activeSegmentIdx uint64
	activeSize       int64
	activePath       string
}

// Open initializes or recovers a WAL buffer in the specified directory.
func Open(opts Options) (*WAL, error) {
	if opts.Dir == "" {
		opts.Dir = "./buffer/"
	}
	if opts.SegmentSizeBytes <= 0 {
		opts.SegmentSizeBytes = DefaultSegmentSizeBytes
	}
	if opts.MaxBufferBytes <= 0 {
		opts.MaxBufferBytes = DefaultMaxBufferSizeBytes
	}

	if err := os.MkdirAll(opts.Dir, 0o750); err != nil {
		return nil, fmt.Errorf("failed to create WAL buffer dir %s: %w", opts.Dir, err)
	}

	w := &WAL{
		dir:              opts.Dir,
		maxBufferBytes:   opts.MaxBufferBytes,
		segmentSizeBytes: opts.SegmentSizeBytes,
	}

	// Scan existing segments in directory
	segments, err := w.scanSegments()
	if err != nil {
		return nil, fmt.Errorf("failed to scan WAL directory: %w", err)
	}

	if len(segments) > 0 {
		// Recover highest segment as active
		lastSegment := segments[len(segments)-1]
		info, err := os.Stat(lastSegment.path)
		if err != nil {
			return nil, fmt.Errorf("failed to stat last segment %s: %w", lastSegment.path, err)
		}

		if info.Size() >= w.segmentSizeBytes {
			// Last segment is full, next append will open new segment
			w.activeSegmentIdx = lastSegment.idx + 1
		} else {
			f, err := os.OpenFile(lastSegment.path, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0o600)
			if err != nil {
				return nil, fmt.Errorf("failed to open last segment %s: %w", lastSegment.path, err)
			}
			w.activeFile = f
			w.activeSegmentIdx = lastSegment.idx
			w.activeSize = info.Size()
			w.activePath = lastSegment.path
		}
	} else {
		w.activeSegmentIdx = 1
	}

	// Initial ceiling check
	w.enforceCeilingLocked()

	return w, nil
}

type segmentMeta struct {
	idx  uint64
	path string
	size int64
}

// scanSegments lists all segment files in directory sorted by index ascending.
func (w *WAL) scanSegments() ([]segmentMeta, error) {
	entries, err := os.ReadDir(w.dir)
	if err != nil {
		return nil, err
	}

	var list []segmentMeta
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		matches := segmentRegex.FindStringSubmatch(entry.Name())
		if len(matches) == 2 {
			idx, err := strconv.ParseUint(matches[1], 10, 64)
			if err != nil {
				continue
			}
			info, err := entry.Info()
			if err != nil {
				continue
			}
			list = append(list, segmentMeta{
				idx:  idx,
				path: filepath.Join(w.dir, entry.Name()),
				size: info.Size(),
			})
		}
	}

	sort.Slice(list, func(i, j int) bool {
		return list[i].idx < list[j].idx
	})

	return list, nil
}

// Append serializes and writes a TelemetryFrame to the active WAL segment.
func (w *WAL) Append(frame *ancymonproto.TelemetryFrame) error {
	if frame == nil {
		return errors.New("cannot append nil telemetry frame")
	}

	payload, err := proto.Marshal(frame)
	if err != nil {
		return fmt.Errorf("failed to marshal telemetry frame: %w", err)
	}

	frameLen := uint32(len(payload))
	totalFrameBytes := int64(4 + frameLen)

	w.mu.Lock()
	defer w.mu.Unlock()

	// Rotate segment if active file is full or not yet opened
	if w.activeFile == nil || (w.activeSize+totalFrameBytes > w.segmentSizeBytes) {
		if err := w.rotateLocked(); err != nil {
			return fmt.Errorf("failed to rotate WAL segment: %w", err)
		}
	}

	// Format: [4 bytes BigEndian length][protobuf payload]
	var lenBuf [4]byte
	binary.BigEndian.PutUint32(lenBuf[:], frameLen)

	if _, err := w.activeFile.Write(lenBuf[:]); err != nil {
		return fmt.Errorf("failed to write frame length header: %w", err)
	}
	if _, err := w.activeFile.Write(payload); err != nil {
		return fmt.Errorf("failed to write frame payload: %w", err)
	}

	w.activeSize += totalFrameBytes
	return nil
}

// rotateLocked rotates the active segment file to the next index.
func (w *WAL) rotateLocked() error {
	if w.activeFile != nil {
		_ = w.activeFile.Sync()
		_ = w.activeFile.Close()
		w.activeFile = nil
		w.activeSegmentIdx++
	}

	if w.activeSegmentIdx == 0 {
		w.activeSegmentIdx = 1
	}

	filename := fmt.Sprintf("segment_%06d.wal", w.activeSegmentIdx)
	filePath := filepath.Join(w.dir, filename)

	f, err := os.OpenFile(filePath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0o600)
	if err != nil {
		return err
	}

	info, err := f.Stat()
	if err != nil {
		_ = f.Close()
		return err
	}

	w.activeFile = f
	w.activeSize = info.Size()
	w.activePath = filePath

	// Enforce hard ceiling with FIFO eviction after rotation
	w.enforceCeilingLocked()

	return nil
}

// SealActiveSegment closes the current active segment making it ready as a completed segment for replay.
// A new segment will be opened on subsequent Append calls.
func (w *WAL) SealActiveSegment() error {
	w.mu.Lock()
	defer w.mu.Unlock()

	if w.activeFile != nil {
		_ = w.activeFile.Sync()
		err := w.activeFile.Close()
		w.activeFile = nil
		w.activePath = ""
		w.activeSize = 0
		w.activeSegmentIdx++
		w.enforceCeilingLocked()
		return err
	}
	return nil
}

// enforceCeilingLocked verifies total buffer size and deletes oldest completed segments if ceiling is exceeded.
func (w *WAL) enforceCeilingLocked() {
	segments, err := w.scanSegments()
	if err != nil {
		log.Printf("ERROR: WAL failed to scan segments for ceiling enforcement: %v", err)
		return
	}

	var totalSize int64
	for _, s := range segments {
		totalSize += s.size
	}

	// While over ceiling, delete oldest segments (excluding current open active segment)
	for totalSize > w.maxBufferBytes && len(segments) > 0 {
		oldest := segments[0]

		// Do not delete currently active file unless it's completed or corrupted
		if w.activeFile != nil && oldest.path == w.activePath {
			if len(segments) == 1 {
				// Only active segment exists and exceeds ceiling, cannot evict
				break
			}
		}

		if err := os.Remove(oldest.path); err != nil {
			log.Printf("ERROR: WAL failed to evict segment %s: %v", oldest.path, err)
			break
		}

		log.Printf("WARNING: WAL buffer ceiling exceeded (%d bytes > %d bytes); evicting oldest completed segment %s (FIFO)",
			totalSize, w.maxBufferBytes, filepath.Base(oldest.path))

		totalSize -= oldest.size
		segments = segments[1:]
	}
}

// GetCompletedSegments returns paths of all completed segment files ready for replay, ordered oldest to newest.
func (w *WAL) GetCompletedSegments() ([]string, error) {
	w.mu.Lock()
	defer w.mu.Unlock()

	segments, err := w.scanSegments()
	if err != nil {
		return nil, err
	}

	var completed []string
	for _, s := range segments {
		// If this segment is currently active and open for writes, it's not completed yet
		if w.activeFile != nil && s.path == w.activePath {
			continue
		}
		completed = append(completed, s.path)
	}

	return completed, nil
}

// HasBacklog returns true if there are any completed segments or unsealed data in active segment.
func (w *WAL) HasBacklog() bool {
	w.mu.Lock()
	defer w.mu.Unlock()

	segments, err := w.scanSegments()
	if err != nil {
		return false
	}
	for _, s := range segments {
		if s.size > 0 {
			return true
		}
	}
	return false
}

// DeleteSegment removes a fully acknowledged segment file from disk.
func (w *WAL) DeleteSegment(path string) error {
	w.mu.Lock()
	defer w.mu.Unlock()

	// If by any chance path is active file, do not remove while open
	if w.activeFile != nil && path == w.activePath {
		_ = w.activeFile.Close()
		w.activeFile = nil
	}

	return os.Remove(path)
}

// ReadSegment reads all TelemetryFrame instances from a segment file in chronological order.
func ReadSegment(path string) ([]*ancymonproto.TelemetryFrame, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, fmt.Errorf("failed to open segment %s: %w", path, err)
	}
	defer f.Close()

	var frames []*ancymonproto.TelemetryFrame
	var lenBuf [4]byte

	for {
		_, err := io.ReadFull(f, lenBuf[:])
		if errors.Is(err, io.EOF) || errors.Is(err, io.ErrUnexpectedEOF) {
			break
		}
		if err != nil {
			return frames, fmt.Errorf("failed to read frame length from %s: %w", path, err)
		}

		payloadLen := binary.BigEndian.Uint32(lenBuf[:])
		payload := make([]byte, payloadLen)
		_, err = io.ReadFull(f, payload)
		if err != nil {
			// Incomplete write / power interruption at tail of segment
			log.Printf("WARNING: Incomplete frame at tail of %s: %v", path, err)
			break
		}

		frame := &ancymonproto.TelemetryFrame{}
		if err := proto.Unmarshal(payload, frame); err != nil {
			log.Printf("WARNING: Corrupted frame at %s: %v", path, err)
			continue
		}

		frames = append(frames, frame)
	}

	return frames, nil
}

// Close gracefully flushes and closes the active WAL segment file.
func (w *WAL) Close() error {
	w.mu.Lock()
	defer w.mu.Unlock()

	if w.activeFile != nil {
		_ = w.activeFile.Sync()
		err := w.activeFile.Close()
		w.activeFile = nil
		return err
	}
	return nil
}
