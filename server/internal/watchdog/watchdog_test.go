package watchdog

import (
	ancymonproto "ancymon/proto"
	"context"
	"testing"
	"time"
)

func TestRegistryRecordAndDetail(t *testing.T) {
	ps := NewPubSub()
	reg := NewRegistry(ps)

	temp := 45.5
	frame := &ancymonproto.TelemetryFrame{
		MachineId:     "uuid-1234",
		Hostname:      "dev-station",
		TimestampUnix: time.Now().Unix(),
		Cpu: &ancymonproto.CpuMetrics{
			TotalUsagePercent: 23.4,
			TemperatureC:      &temp,
		},
		Memory: &ancymonproto.MemoryMetrics{
			TotalBytes:   16 * 1024 * 1024 * 1024,
			UsedBytes:    8 * 1024 * 1024 * 1024,
			UsagePercent: 50.0,
		},
		Network: &ancymonproto.NetworkMetrics{
			RxBytesPerSec: 1024,
			TxBytesPerSec: 2048,
		},
		Disks: []*ancymonproto.DiskPartitionMetrics{
			{
				MountPoint:   "/",
				FsType:       "ext4",
				TotalBytes:   500 * 1024 * 1024 * 1024,
				FreeBytes:    250 * 1024 * 1024 * 1024,
				UsagePercent: 50.0,
			},
		},
	}

	reg.RecordTelemetry(frame)

	detail, ok := reg.GetMachineDetail("uuid-1234")
	if !ok {
		t.Fatalf("expected machine uuid-1234 to exist")
	}
	if detail.Hostname != "dev-station" {
		t.Errorf("expected hostname dev-station, got %s", detail.Hostname)
	}
	if detail.Status != StatusOnline {
		t.Errorf("expected status ONLINE, got %s", detail.Status)
	}
	if detail.Cpu.TotalUsagePercent != 23.4 {
		t.Errorf("expected CPU 23.4, got %f", detail.Cpu.TotalUsagePercent)
	}
	if detail.Cpu.TemperatureC == nil || *detail.Cpu.TemperatureC != 45.5 {
		t.Errorf("expected temp 45.5, got %v", detail.Cpu.TemperatureC)
	}
	if len(detail.Disks) != 1 || detail.Disks[0].MountPoint != "/" {
		t.Errorf("expected disk partition /, got %v", detail.Disks)
	}

	summaryList := reg.GetFleetSummary()
	if len(summaryList) != 1 {
		t.Fatalf("expected 1 summary, got %d", len(summaryList))
	}
	if summaryList[0].MachineID != "uuid-1234" {
		t.Errorf("expected summary ID uuid-1234, got %s", summaryList[0].MachineID)
	}
	if summaryList[0].CpuUsagePercent == nil || *summaryList[0].CpuUsagePercent != 23.4 {
		t.Errorf("expected summary CPU 23.4, got %v", summaryList[0].CpuUsagePercent)
	}
}

func TestPubSubSubscriptions(t *testing.T) {
	ps := NewPubSub()
	reg := NewRegistry(ps)

	fleetCh, unsubFleet := ps.SubscribeFleetSummary()
	defer unsubFleet()

	metricCh, unsubMetric := ps.SubscribeMachineMetrics("host-sub-test")
	defer unsubMetric()

	frame := &ancymonproto.TelemetryFrame{
		MachineId:     "host-sub-test",
		Hostname:      "sub-host",
		TimestampUnix: time.Now().Unix(),
		Cpu: &ancymonproto.CpuMetrics{
			TotalUsagePercent: 12.0,
		},
	}

	reg.RecordTelemetry(frame)

	select {
	case sum := <-fleetCh:
		if len(sum) != 1 || sum[0].MachineID != "host-sub-test" {
			t.Errorf("unexpected fleet summary: %v", sum)
		}
	case <-time.After(500 * time.Millisecond):
		t.Fatal("timeout waiting for fleet summary broadcast")
	}

	select {
	case det := <-metricCh:
		if det.MachineID != "host-sub-test" || det.Cpu.TotalUsagePercent != 12.0 {
			t.Errorf("unexpected machine detail: %v", det)
		}
	case <-time.After(500 * time.Millisecond):
		t.Fatal("timeout waiting for machine detail broadcast")
	}
}

func TestDeleteMachine(t *testing.T) {
	ps := NewPubSub()
	reg := NewRegistry(ps)

	frame := &ancymonproto.TelemetryFrame{
		MachineId: "del-uuid",
		Hostname:  "to-be-deleted",
	}
	reg.RecordTelemetry(frame)

	if len(reg.GetFleetSummary()) != 1 {
		t.Fatalf("expected 1 machine")
	}

	deleted := reg.DeleteMachine("del-uuid")
	if !deleted {
		t.Errorf("expected DeleteMachine to return true")
	}
	if len(reg.GetFleetSummary()) != 0 {
		t.Errorf("expected 0 machines after deletion")
	}

	// Deleting again returns false
	if reg.DeleteMachine("del-uuid") {
		t.Errorf("expected second DeleteMachine to return false")
	}
}

func TestHeartbeatWatchdog(t *testing.T) {
	ps := NewPubSub()
	reg := NewRegistry(ps)

	frame := &ancymonproto.TelemetryFrame{
		MachineId: "silent-box",
		Hostname:  "silent-box",
	}
	reg.RecordTelemetry(frame)

	// Manually age the machine's last seen timestamp
	reg.mu.Lock()
	reg.machines["silent-box"].LastSeen = time.Now().Add(-70 * time.Second)
	reg.mu.Unlock()

	changed := reg.CheckHeartbeats(60 * time.Second)
	if changed != 1 {
		t.Fatalf("expected 1 changed machine, got %d", changed)
	}

	detail, ok := reg.GetMachineDetail("silent-box")
	if !ok {
		t.Fatalf("expected machine to exist")
	}
	if detail.Status != StatusOffline {
		t.Errorf("expected status OFFLINE, got %s", detail.Status)
	}

	// Running check again shouldn't change already-offline host
	if n := reg.CheckHeartbeats(60 * time.Second); n != 0 {
		t.Errorf("expected 0 changed machines, got %d", n)
	}

	// Start background watchdog and verify context shutdown
	ctx, cancel := context.WithCancel(context.Background())
	wd := NewWatchdog(reg, 20*time.Millisecond, 50*time.Millisecond)
	wd.Start(ctx)
	cancel()
}
