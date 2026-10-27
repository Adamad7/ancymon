package storage

import (
	ancymonproto "ancymon/proto"
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"
	"time"
)

func TestFormatInfluxLines(t *testing.T) {
	temp := 62.5
	frame := &ancymonproto.TelemetryFrame{
		MachineId:     "host=01,uuid",
		Hostname:      "my host",
		TimestampUnix: 1710000000,
		Cpu: &ancymonproto.CpuMetrics{
			TotalUsagePercent: 42.15,
			TemperatureC:      &temp,
		},
		Memory: &ancymonproto.MemoryMetrics{
			TotalBytes:   16000000000,
			UsedBytes:    8000000000,
			UsagePercent: 50.0,
		},
		Network: &ancymonproto.NetworkMetrics{
			RxBytesPerSec: 1048576,
			TxBytesPerSec: 2097152,
		},
		Disks: []*ancymonproto.DiskPartitionMetrics{
			{
				MountPoint:   "/mnt/data,1",
				FsType:       "ext4",
				TotalBytes:   100000000000,
				FreeBytes:    60000000000,
				UsagePercent: 40.0,
			},
		},
	}

	lines := FormatInfluxLines(frame)
	expectedTs := "1710000000000000000"

	// Check CPU
	if !strings.Contains(lines, `cpu,machine_id=host\=01\,uuid,hostname=my\ host total_usage_percent=42.15,temperature_c=62.50 `+expectedTs) {
		t.Errorf("missing or incorrect CPU line: %s", lines)
	}

	// Check Memory
	if !strings.Contains(lines, `memory,machine_id=host\=01\,uuid,hostname=my\ host total_bytes=16000000000i,used_bytes=8000000000i,usage_percent=50.00 `+expectedTs) {
		t.Errorf("missing or incorrect Memory line: %s", lines)
	}

	// Check Network
	if !strings.Contains(lines, `network,machine_id=host\=01\,uuid,hostname=my\ host rx_bytes_per_sec=1048576i,tx_bytes_per_sec=2097152i `+expectedTs) {
		t.Errorf("missing or incorrect Network line: %s", lines)
	}

	// Check Disk
	if !strings.Contains(lines, `disk,machine_id=host\=01\,uuid,hostname=my\ host,mount_point=/mnt/data\,1,fs_type=ext4 total_bytes=100000000000i,free_bytes=60000000000i,usage_percent=40.00 `+expectedTs) {
		t.Errorf("missing or incorrect Disk line: %s", lines)
	}
}

func TestCalculateTimeWindow(t *testing.T) {
	refTime := time.Date(2026, 10, 27, 12, 0, 0, 0, time.UTC)
	refUnix := refTime.Unix()

	tests := []struct {
		rangeName string
		dateStr   string
		expDiff   int64
		expStep   string
		expectErr bool
	}{
		{Range1H, "", 3600, "15s", false},
		{Range6H, "", 21600, "1m", false},
		{Range12H, "", 43200, "2m", false},
		{Range24H, "", 86400, "5m", false},
		{Range3D, "", 259200, "15m", false},
		{Range7D, "", 604800, "30m", false},
		{RangeCustomDate, "2026-10-27", 86399, "5m", false},
		{RangeCustomDate, "", 0, "", true},
		{"INVALID", "", 0, "", true},
	}

	for _, tc := range tests {
		start, end, step, err := CalculateTimeWindow(tc.rangeName, tc.dateStr, refTime)
		if tc.expectErr {
			if err == nil {
				t.Errorf("expected error for %s, got nil", tc.rangeName)
			}
			continue
		}
		if err != nil {
			t.Fatalf("unexpected error for %s: %v", tc.rangeName, err)
		}
		if tc.rangeName != RangeCustomDate && (end-start) != tc.expDiff {
			t.Errorf("[%s] expected diff %d, got %d", tc.rangeName, tc.expDiff, end-start)
		}
		if step != tc.expStep {
			t.Errorf("[%s] expected step %s, got %s", tc.rangeName, tc.expStep, step)
		}
		if tc.rangeName != RangeCustomDate && end != refUnix {
			t.Errorf("[%s] expected end %d, got %d", tc.rangeName, refUnix, end)
		}
	}
}

func TestBuildMetricsQLExpr(t *testing.T) {
	machID := "uuid-123"

	expr, err := BuildMetricsQLExpr(machID, MetricCPUUsage)
	if err != nil || expr != `cpu_total_usage_percent{machine_id="uuid-123"}` {
		t.Errorf("unexpected expr for CPU_USAGE: %s, %v", expr, err)
	}

	expr, err = BuildMetricsQLExpr(machID, MetricDiskUsage)
	if err != nil || expr != `max(disk_usage_percent{machine_id="uuid-123"})` {
		t.Errorf("unexpected expr for DISK_USAGE: %s, %v", expr, err)
	}

	_, err = BuildMetricsQLExpr(machID, "UNKNOWN")
	if err == nil {
		t.Errorf("expected error on unknown metric")
	}
}

func TestWriterAndQuerierWithMockServer(t *testing.T) {
	var mu sync.Mutex
	var receivedWrites []string

	mockServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		mu.Lock()
		defer mu.Unlock()

		if r.URL.Path == "/write" && r.Method == http.MethodPost {
			body, _ := io.ReadAll(r.Body)
			receivedWrites = append(receivedWrites, string(body))
			w.WriteHeader(http.StatusNoContent)
			return
		}

		if r.URL.Path == "/api/v1/query_range" && r.Method == http.MethodGet {
			resp := VMQueryResponse{
				Status: "success",
				Data: VMDataBody{
					ResultType: "matrix",
					Result: []VMSeries{
						{
							Metric: map[string]string{"machine_id": "mock-box"},
							Values: [][]interface{}{
								{float64(1710000000), "33.5"},
								{float64(1710000015), "34.2"},
							},
						},
					},
				},
			}
			w.Header().Set("Content-Type", "application/json")
			_ = json.NewEncoder(w).Encode(resp)
			return
		}

		w.WriteHeader(http.StatusNotFound)
	}))
	defer mockServer.Close()

	// 1. Test Writer
	writer := NewWriter(mockServer.URL, 2, 50*time.Millisecond)

	f1 := &ancymonproto.TelemetryFrame{
		MachineId:     "mock-box",
		Hostname:      "mock-host",
		TimestampUnix: 1710000000,
		Cpu:           &ancymonproto.CpuMetrics{TotalUsagePercent: 33.5},
	}
	f2 := &ancymonproto.TelemetryFrame{
		MachineId:     "mock-box",
		Hostname:      "mock-host",
		TimestampUnix: 1710000015,
		Cpu:           &ancymonproto.CpuMetrics{TotalUsagePercent: 34.2},
	}

	writer.Enqueue(f1)
	writer.Enqueue(f2)
	writer.Stop() // Flushes batch and waits

	mu.Lock()
	if len(receivedWrites) == 0 {
		t.Fatalf("expected writes to be received by mock server")
	}
	combined := strings.Join(receivedWrites, "\n")
	if !strings.Contains(combined, "total_usage_percent=33.50") || !strings.Contains(combined, "total_usage_percent=34.20") {
		t.Errorf("written lines did not contain expected frame values: %s", combined)
	}
	mu.Unlock()

	// 2. Test Querier
	querier := NewQuerier(mockServer.URL)
	points, err := querier.QueryHistory(context.Background(), "mock-box", MetricCPUUsage, Range1H, "")
	if err != nil {
		t.Fatalf("QueryHistory failed: %v", err)
	}

	if len(points) != 2 {
		t.Fatalf("expected 2 points, got %d", len(points))
	}
	if points[0].Timestamp != 1710000000 || points[0].Value != 33.5 {
		t.Errorf("point 0 mismatch: %+v", points[0])
	}
	if points[1].Timestamp != 1710000015 || points[1].Value != 34.2 {
		t.Errorf("point 1 mismatch: %+v", points[1])
	}
}
