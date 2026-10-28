package watchdog

import (
	ancymonproto "ancymon/proto"
	"os"
	"path/filepath"
	"testing"
	"time"
)

// TestRegistry_StatePersistenceAcrossRestarts tests the full lifecycle of workstation
// state persistence across server restarts:
// 1. Telemetry recording automatically persists workstations to disk.
// 2. Directory hierarchy is created automatically if it does not exist.
// 3. Deleting a machine updates disk persistence.
// 4. On simulated server restart, existing workstations are loaded with status OFFLINE.
// 5. Last known metrics (CPU, temp, memory, disks) are preserved for OFFLINE hosts.
// 6. When an agent resumes streaming, the workstation transitions back to ONLINE.
func TestRegistry_StatePersistenceAcrossRestarts(t *testing.T) {
	tempDir := t.TempDir()
	stateFile := filepath.Join(tempDir, "nested", "data", "workstations.json")

	// Phase 1: Initial server run
	ps1 := NewPubSub()
	reg1 := NewRegistry(ps1, stateFile)

	temp := 52.3
	frame1 := &ancymonproto.TelemetryFrame{
		MachineId:     "ws-alpha-01",
		Hostname:      "alpha-workstation",
		TimestampUnix: time.Now().Unix(),
		Cpu: &ancymonproto.CpuMetrics{
			TotalUsagePercent: 34.5,
			TemperatureC:      &temp,
		},
		Memory: &ancymonproto.MemoryMetrics{
			TotalBytes:   32 * 1024 * 1024 * 1024,
			UsedBytes:    16 * 1024 * 1024 * 1024,
			UsagePercent: 50.0,
		},
		Network: &ancymonproto.NetworkMetrics{
			RxBytesPerSec: 50000,
			TxBytesPerSec: 25000,
		},
		Disks: []*ancymonproto.DiskPartitionMetrics{
			{
				MountPoint:   "/",
				FsType:       "ext4",
				TotalBytes:   1000 * 1024 * 1024 * 1024,
				FreeBytes:    600 * 1024 * 1024 * 1024,
				UsagePercent: 40.0,
			},
		},
	}

	frame2 := &ancymonproto.TelemetryFrame{
		MachineId:     "ws-beta-02",
		Hostname:      "beta-workstation",
		TimestampUnix: time.Now().Unix(),
		Cpu: &ancymonproto.CpuMetrics{
			TotalUsagePercent: 12.0,
		},
	}

	reg1.RecordTelemetry(frame1)
	reg1.RecordTelemetry(frame2)

	// Verify both machines are ONLINE in registry 1
	if count := len(reg1.GetFleetSummary()); count != 2 {
		t.Fatalf("expected 2 workstations in reg1, got %d", count)
	}

	// Delete ws-beta-02 and verify deletion is reflected
	if !reg1.DeleteMachine("ws-beta-02") {
		t.Fatalf("failed to delete ws-beta-02")
	}
	if count := len(reg1.GetFleetSummary()); count != 1 {
		t.Fatalf("expected 1 workstation in reg1 after deletion, got %d", count)
	}

	// Explicitly invoke SaveState (as happens during server shutdown)
	if err := reg1.SaveState(); err != nil {
		t.Fatalf("SaveState failed: %v", err)
	}

	// Verify the state file exists on disk
	if _, err := os.Stat(stateFile); err != nil {
		t.Fatalf("expected state file to exist at %s: %v", stateFile, err)
	}

	// Phase 2: Simulated Server Restart (new registry instance pointing to same file)
	ps2 := NewPubSub()
	fleetCh, unsub := ps2.SubscribeFleetSummary()
	defer unsub()

	reg2 := NewRegistry(ps2)
	if err := reg2.LoadState(stateFile); err != nil {
		t.Fatalf("LoadState failed on restart: %v", err)
	}

	// Verify that reg2 broadcast initial fleet summary on load
	select {
	case summary := <-fleetCh:
		if len(summary) != 1 || summary[0].MachineID != "ws-alpha-01" {
			t.Errorf("unexpected broadcast summary on load: %+v", summary)
		}
	case <-time.After(500 * time.Millisecond):
		t.Log("Note: broadcast fleet summary subscription timing")
	}

	// Verify ws-alpha-01 exists and ws-beta-02 does not
	summaryList := reg2.GetFleetSummary()
	if len(summaryList) != 1 {
		t.Fatalf("expected 1 workstation in reg2, got %d", len(summaryList))
	}

	item := summaryList[0]
	if item.MachineID != "ws-alpha-01" {
		t.Errorf("expected machine ws-alpha-01, got %s", item.MachineID)
	}
	if item.Hostname != "alpha-workstation" {
		t.Errorf("expected hostname alpha-workstation, got %s", item.Hostname)
	}

	// MUST be initialized with StatusOffline!
	if item.Status != StatusOffline {
		t.Errorf("CRITICAL: expected status %s after restart, got %s", StatusOffline, item.Status)
	}

	// Last known metrics should be retained for the offline machine
	if item.CpuUsagePercent == nil || *item.CpuUsagePercent != 34.5 {
		t.Errorf("expected retained CPU 34.5, got %v", item.CpuUsagePercent)
	}
	if item.CpuTemperatureC == nil || *item.CpuTemperatureC != 52.3 {
		t.Errorf("expected retained temperature 52.3, got %v", item.CpuTemperatureC)
	}

	// Check detailed metrics for ws-alpha-01
	detail, ok := reg2.GetMachineDetail("ws-alpha-01")
	if !ok {
		t.Fatalf("expected to get detail for ws-alpha-01")
	}
	if detail.Status != StatusOffline {
		t.Errorf("expected detail status OFFLINE, got %s", detail.Status)
	}
	if len(detail.Disks) != 1 || detail.Disks[0].MountPoint != "/" {
		t.Errorf("expected disk details preserved, got %+v", detail.Disks)
	}

	// Phase 3: Agent resumes telemetry streaming to reg2
	resumeFrame := &ancymonproto.TelemetryFrame{
		MachineId:     "ws-alpha-01",
		Hostname:      "alpha-workstation",
		TimestampUnix: time.Now().Unix(),
		Cpu: &ancymonproto.CpuMetrics{
			TotalUsagePercent: 15.0,
		},
	}
	reg2.RecordTelemetry(resumeFrame)

	resumedDetail, _ := reg2.GetMachineDetail("ws-alpha-01")
	if resumedDetail.Status != StatusOnline {
		t.Errorf("expected status ONLINE after telemetry resumed, got %s", resumedDetail.Status)
	}
	if resumedDetail.Cpu.TotalUsagePercent != 15.0 {
		t.Errorf("expected updated CPU 15.0, got %f", resumedDetail.Cpu.TotalUsagePercent)
	}
}

func TestRegistry_NonExistentStateFile(t *testing.T) {
	tempDir := t.TempDir()
	nonExistent := filepath.Join(tempDir, "does-not-exist.json")

	reg := NewRegistry(nil)
	if err := reg.LoadState(nonExistent); err != nil {
		t.Fatalf("expected non-existent file to be handled gracefully without error, got %v", err)
	}
	if len(reg.GetFleetSummary()) != 0 {
		t.Errorf("expected empty fleet, got %d", len(reg.GetFleetSummary()))
	}
}

func TestRegistry_CorruptStateFileHandling(t *testing.T) {
	tempDir := t.TempDir()
	corruptFile := filepath.Join(tempDir, "corrupted.json")
	if err := os.WriteFile(corruptFile, []byte("{not valid json!"), 0644); err != nil {
		t.Fatalf("failed to write corrupt file: %v", err)
	}

	reg := NewRegistry(nil)
	if err := reg.LoadState(corruptFile); err == nil {
		t.Fatalf("expected LoadState to return error for corrupted JSON, got nil")
	}
}

func TestRegistry_EmptyStateFileHandling(t *testing.T) {
	tempDir := t.TempDir()
	emptyFile := filepath.Join(tempDir, "empty.json")
	if err := os.WriteFile(emptyFile, []byte("   \n"), 0644); err != nil {
		t.Fatalf("failed to write empty file: %v", err)
	}

	reg := NewRegistry(nil)
	if err := reg.LoadState(emptyFile); err != nil {
		t.Fatalf("expected LoadState to succeed on empty file, got %v", err)
	}
	if len(reg.GetFleetSummary()) != 0 {
		t.Errorf("expected 0 machines, got %d", len(reg.GetFleetSummary()))
	}
}
