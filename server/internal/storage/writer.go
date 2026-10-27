package storage

import (
	ancymonproto "ancymon/proto"
	"bytes"
	"context"
	"fmt"
	"io"
	"log"
	"net/http"
	"strings"
	"sync"
	"time"
)

// Writer asynchronously batches and writes telemetry frames to VictoriaMetrics via Influx Line Protocol.
type Writer struct {
	vmURL         string
	httpClient    *http.Client
	frameCh       chan *ancymonproto.TelemetryFrame
	batchSize     int
	flushInterval time.Duration

	ctx    context.Context
	cancel context.CancelFunc
	wg     sync.WaitGroup
}

// NewWriter constructs an asynchronous batch writer for VictoriaMetrics.
func NewWriter(vmURL string, batchSize int, flushInterval time.Duration) *Writer {
	if batchSize <= 0 {
		batchSize = 100
	}
	if flushInterval <= 0 {
		flushInterval = 500 * time.Millisecond
	}

	ctx, cancel := context.WithCancel(context.Background())
	w := &Writer{
		vmURL: strings.TrimRight(vmURL, "/"),
		httpClient: &http.Client{
			Timeout: 5 * time.Second,
		},
		frameCh:       make(chan *ancymonproto.TelemetryFrame, 10000),
		batchSize:     batchSize,
		flushInterval: flushInterval,
		ctx:           ctx,
		cancel:        cancel,
	}

	w.wg.Add(1)
	go w.workerLoop()

	return w
}

// Enqueue queues a telemetry frame for asynchronous batched persistence.
func (w *Writer) Enqueue(frame *ancymonproto.TelemetryFrame) {
	if frame == nil {
		return
	}
	select {
	case w.frameCh <- frame:
	default:
		log.Printf("[Storage] Warning: telemetry queue full, dropping frame for %s", frame.MachineId)
	}
}

// workerLoop buffers frames and flushes periodically or when the batch limit is reached.
func (w *Writer) workerLoop() {
	defer w.wg.Done()

	ticker := time.NewTicker(w.flushInterval)
	defer ticker.Stop()

	batch := make([]*ancymonproto.TelemetryFrame, 0, w.batchSize)

	for {
		select {
		case <-w.ctx.Done():
			// Drain remaining frames in channel
			for {
				select {
				case f := <-w.frameCh:
					batch = append(batch, f)
				default:
					if len(batch) > 0 {
						w.flushBatch(batch)
					}
					return
				}
			}

		case f, ok := <-w.frameCh:
			if !ok {
				if len(batch) > 0 {
					w.flushBatch(batch)
				}
				return
			}
			batch = append(batch, f)
			if len(batch) >= w.batchSize {
				w.flushBatch(batch)
				batch = make([]*ancymonproto.TelemetryFrame, 0, w.batchSize)
			}

		case <-ticker.C:
			if len(batch) > 0 {
				w.flushBatch(batch)
				batch = make([]*ancymonproto.TelemetryFrame, 0, w.batchSize)
			}
		}
	}
}

// Stop gracefully drains and flushes pending frames, then shuts down the worker.
func (w *Writer) Stop() {
	w.cancel()
	w.wg.Wait()
}

// flushBatch serializes frames into Influx Line Protocol and POSTs them to /write.
func (w *Writer) flushBatch(batch []*ancymonproto.TelemetryFrame) {
	if len(batch) == 0 {
		return
	}

	var buf bytes.Buffer
	for _, frame := range batch {
		lines := FormatInfluxLines(frame)
		buf.WriteString(lines)
	}

	payload := buf.Bytes()
	if len(payload) == 0 {
		return
	}

	writeURL := fmt.Sprintf("%s/write", w.vmURL)
	reqCtx, reqCancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer reqCancel()

	req, err := http.NewRequestWithContext(reqCtx, http.MethodPost, writeURL, bytes.NewReader(payload))
	if err != nil {
		log.Printf("[Storage] Failed to construct Influx write request: %v", err)
		return
	}
	req.Header.Set("Content-Type", "text/plain")

	resp, err := w.httpClient.Do(req)
	if err != nil {
		log.Printf("[Storage] Influx write HTTP request failed to %s: %v", writeURL, err)
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusNoContent {
		body, _ := io.ReadAll(resp.Body)
		log.Printf("[Storage] Influx write returned unexpected status %d: %s", resp.StatusCode, string(body))
	}
}

// FormatInfluxLines converts a single TelemetryFrame into Influx Line Protocol rows.
func FormatInfluxLines(frame *ancymonproto.TelemetryFrame) string {
	if frame == nil || frame.MachineId == "" {
		return ""
	}

	tsNs := frame.TimestampUnix * 1_000_000_000
	if tsNs <= 0 {
		tsNs = time.Now().UnixNano()
	}

	machID := escapeTag(frame.MachineId)
	host := escapeTag(frame.Hostname)

	var sb strings.Builder

	// 1. CPU Measurement
	if frame.Cpu != nil {
		if frame.Cpu.TemperatureC != nil {
			fmt.Fprintf(&sb, "cpu,machine_id=%s,hostname=%s total_usage_percent=%.2f,temperature_c=%.2f %d\n",
				machID, host, frame.Cpu.TotalUsagePercent, *frame.Cpu.TemperatureC, tsNs)
		} else {
			fmt.Fprintf(&sb, "cpu,machine_id=%s,hostname=%s total_usage_percent=%.2f %d\n",
				machID, host, frame.Cpu.TotalUsagePercent, tsNs)
		}
	}

	// 2. Memory Measurement
	if frame.Memory != nil {
		fmt.Fprintf(&sb, "memory,machine_id=%s,hostname=%s total_bytes=%di,used_bytes=%di,usage_percent=%.2f %d\n",
			machID, host, frame.Memory.TotalBytes, frame.Memory.UsedBytes, frame.Memory.UsagePercent, tsNs)
	}

	// 3. Network Measurement
	if frame.Network != nil {
		fmt.Fprintf(&sb, "network,machine_id=%s,hostname=%s rx_bytes_per_sec=%di,tx_bytes_per_sec=%di %d\n",
			machID, host, frame.Network.RxBytesPerSec, frame.Network.TxBytesPerSec, tsNs)
	}

	// 4. Disk Partitions
	for _, disk := range frame.Disks {
		if disk != nil {
			mount := escapeTag(disk.MountPoint)
			fs := escapeTag(disk.FsType)
			fmt.Fprintf(&sb, "disk,machine_id=%s,hostname=%s,mount_point=%s,fs_type=%s total_bytes=%di,free_bytes=%di,usage_percent=%.2f %d\n",
				machID, host, mount, fs, disk.TotalBytes, disk.FreeBytes, disk.UsagePercent, tsNs)
		}
	}

	return sb.String()
}

// escapeTag escapes comma, equals, and space characters per Influx Line Protocol tag requirements.
func escapeTag(s string) string {
	r := strings.ReplaceAll(s, " ", `\ `)
	r = strings.ReplaceAll(r, ",", `\,`)
	r = strings.ReplaceAll(r, "=", `\=`)
	return r
}
