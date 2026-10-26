package ancymonproto_test

import (
	"testing"
	"time"

	ancymonproto "ancymon/proto"

	"google.golang.org/protobuf/proto"
)

func TestTelemetryFrameSerializationWithOptionalFields(t *testing.T) {
	// 1. Frame with temperature_c present
	temp := 48.5
	frameWithTemp := &ancymonproto.TelemetryFrame{
		MachineId:     "b9e382b6-455b-43d9-93e1-5e263d90df81",
		Hostname:      "homelab-node-01",
		TimestampUnix: time.Now().Unix(),
		Cpu: &ancymonproto.CpuMetrics{
			TotalUsagePercent: 24.8,
			TemperatureC:      &temp,
		},
		Memory: &ancymonproto.MemoryMetrics{
			TotalBytes:   34359738368, // 32 GB
			UsedBytes:    8589934592,  // 8 GB
			UsagePercent: 25.0,
		},
		Network: &ancymonproto.NetworkMetrics{
			RxBytesPerSec: 1548200,
			TxBytesPerSec: 894200,
		},
		Disks: []*ancymonproto.DiskPartitionMetrics{
			{
				MountPoint:   "/",
				FsType:       "ext4",
				TotalBytes:   500107862016, // ~500 GB
				FreeBytes:    350075503411,
				UsagePercent: 30.0,
			},
		},
	}

	data, err := proto.Marshal(frameWithTemp)
	if err != nil {
		t.Fatalf("failed to marshal frame with temp: %v", err)
	}

	var decoded ancymonproto.TelemetryFrame
	if err := proto.Unmarshal(data, &decoded); err != nil {
		t.Fatalf("failed to unmarshal frame with temp: %v", err)
	}

	if decoded.GetCpu() == nil || decoded.GetCpu().TemperatureC == nil {
		t.Fatalf("expected temperature_c to be non-nil")
	}
	if *decoded.GetCpu().TemperatureC != temp {
		t.Errorf("expected temperature_c %v, got %v", temp, *decoded.GetCpu().TemperatureC)
	}
	if decoded.GetCpu().GetTotalUsagePercent() != 24.8 {
		t.Errorf("expected CPU usage 24.8, got %v", decoded.GetCpu().GetTotalUsagePercent())
	}
	if decoded.GetMemory().GetTotalBytes() != 34359738368 {
		t.Errorf("expected 32GB RAM bytes, got %d", decoded.GetMemory().GetTotalBytes())
	}
	if len(decoded.GetDisks()) != 1 || decoded.GetDisks()[0].GetFsType() != "ext4" {
		t.Errorf("expected ext4 disk partition, got %+v", decoded.GetDisks())
	}

	// 2. Frame with temperature_c omitted (virtualized host without thermal passthrough)
	frameWithoutTemp := &ancymonproto.TelemetryFrame{
		MachineId:     "b9e382b6-455b-43d9-93e1-5e263d90df81",
		Hostname:      "vm-guest-02",
		TimestampUnix: time.Now().Unix(),
		Cpu: &ancymonproto.CpuMetrics{
			TotalUsagePercent: 12.3,
			TemperatureC:      nil, // nil pointer represents missing sensor
		},
		Memory: &ancymonproto.MemoryMetrics{
			TotalBytes:   8589934592,
			UsedBytes:    2147483648,
			UsagePercent: 25.0,
		},
		Network: &ancymonproto.NetworkMetrics{
			RxBytesPerSec: 50000,
			TxBytesPerSec: 10000,
		},
		Disks: []*ancymonproto.DiskPartitionMetrics{
			{
				MountPoint:   "C:",
				FsType:       "ntfs",
				TotalBytes:   107374182400,
				FreeBytes:    53687091200,
				UsagePercent: 50.0,
			},
		},
	}

	dataNoTemp, err := proto.Marshal(frameWithoutTemp)
	if err != nil {
		t.Fatalf("failed to marshal frame without temp: %v", err)
	}

	var decodedNoTemp ancymonproto.TelemetryFrame
	if err := proto.Unmarshal(dataNoTemp, &decodedNoTemp); err != nil {
		t.Fatalf("failed to unmarshal frame without temp: %v", err)
	}

	if decodedNoTemp.GetCpu() == nil {
		t.Fatalf("expected CPU metrics to be present")
	}
	if decodedNoTemp.GetCpu().TemperatureC != nil {
		t.Errorf("expected nil temperature_c on virtualized host, got %v", *decodedNoTemp.GetCpu().TemperatureC)
	}
}

func TestTelemetryAckSerialization(t *testing.T) {
	ack := &ancymonproto.TelemetryAck{
		Success:               true,
		AcknowledgedTimestamp: 1770000000,
		Message:               "WAL segment 000001 ingested successfully",
		AcknowledgedCount:     60,
	}

	data, err := proto.Marshal(ack)
	if err != nil {
		t.Fatalf("failed to marshal TelemetryAck: %v", err)
	}

	var decoded ancymonproto.TelemetryAck
	if err := proto.Unmarshal(data, &decoded); err != nil {
		t.Fatalf("failed to unmarshal TelemetryAck: %v", err)
	}

	if !decoded.GetSuccess() {
		t.Errorf("expected success true")
	}
	if decoded.GetAcknowledgedTimestamp() != 1770000000 {
		t.Errorf("expected timestamp 1770000000, got %d", decoded.GetAcknowledgedTimestamp())
	}
	if decoded.GetAcknowledgedCount() != 60 {
		t.Errorf("expected count 60, got %d", decoded.GetAcknowledgedCount())
	}
}
