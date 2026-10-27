package watchdog

import (
	"context"
	"testing"
	"time"

	ancymonproto "ancymon/proto"
)

// TestWatchdogResilience_60SecondSilenceTransitionToOffline validates that:
// 1. A workstation reporting telemetry is marked ONLINE.
// 2. Silence under 60 seconds keeps the machine ONLINE.
// 3. Exceeding 60 seconds of silence triggers transition to OFFLINE and broadcasts to subscribers.
// 4. Fresh incoming telemetry revives the workstation to ONLINE and broadcasts update.
func TestWatchdogResilience_60SecondSilenceTransitionToOffline(t *testing.T) {
	ps := NewPubSub()
	reg := NewRegistry(ps)

	fleetCh, unsub := ps.SubscribeFleetSummary()
	defer unsub()

	const machineID = "workstation-resilience-alpha"

	// 1. Initial report: host comes online
	frameOnline := &ancymonproto.TelemetryFrame{
		MachineId:     machineID,
		Hostname:      "alpha-pc",
		TimestampUnix: time.Now().Unix(),
		Cpu: &ancymonproto.CpuMetrics{
			TotalUsagePercent: 25.0,
		},
	}
	reg.RecordTelemetry(frameOnline)

	// Consume broadcast for initial ONLINE event
	select {
	case summary := <-fleetCh:
		if len(summary) != 1 || summary[0].Status != StatusOnline {
			t.Fatalf("expected 1 ONLINE machine in summary, got: %+v", summary)
		}
	case <-time.After(1 * time.Second):
		t.Fatal("timeout waiting for initial ONLINE broadcast")
	}

	// 2. Simulate 30 seconds of silence (< 60s threshold)
	reg.mu.Lock()
	reg.machines[machineID].LastSeen = time.Now().Add(-30 * time.Second)
	reg.mu.Unlock()

	changed := reg.CheckHeartbeats(60 * time.Second)
	if changed != 0 {
		t.Errorf("expected 0 machines transitioned at 30s silence, got %d", changed)
	}

	detail, ok := reg.GetMachineDetail(machineID)
	if !ok || detail.Status != StatusOnline {
		t.Fatalf("workstation should remain ONLINE during silence under 60s, got %s", detail.Status)
	}

	// 3. Simulate 65 seconds of silence (> 60s threshold)
	reg.mu.Lock()
	reg.machines[machineID].LastSeen = time.Now().Add(-65 * time.Second)
	reg.mu.Unlock()

	changed = reg.CheckHeartbeats(60 * time.Second)
	if changed != 1 {
		t.Fatalf("expected 1 machine to transition to OFFLINE after exceeding silence timeout, got %d", changed)
	}

	// 4. Verify subscriber received OFFLINE broadcast event
	select {
	case summary := <-fleetCh:
		if len(summary) != 1 {
			t.Fatalf("expected 1 machine in fleet summary broadcast, got %d", len(summary))
		}
		if summary[0].MachineID != machineID {
			t.Errorf("expected machine ID %s, got %s", machineID, summary[0].MachineID)
		}
		if summary[0].Status != StatusOffline {
			t.Errorf("expected status OFFLINE in broadcast, got %s", summary[0].Status)
		}
	case <-time.After(1 * time.Second):
		t.Fatal("timeout waiting for OFFLINE fleet summary broadcast")
	}

	// Check detail directly
	detail, ok = reg.GetMachineDetail(machineID)
	if !ok || detail.Status != StatusOffline {
		t.Fatalf("expected detail status OFFLINE, got: %+v", detail)
	}

	// 5. Subsequent heartbeat check without new telemetry should NOT re-trigger or change count
	if n := reg.CheckHeartbeats(1 * time.Millisecond); n != 0 {
		t.Errorf("expected 0 changed machines for already-offline host, got %d", n)
	}

	// 6. Host reconnects and sends fresh telemetry: must revive to ONLINE
	frameRevive := &ancymonproto.TelemetryFrame{
		MachineId:     machineID,
		Hostname:      "alpha-pc",
		TimestampUnix: time.Now().Unix(),
		Cpu: &ancymonproto.CpuMetrics{
			TotalUsagePercent: 30.0,
		},
	}
	reg.RecordTelemetry(frameRevive)

	select {
	case summary := <-fleetCh:
		if len(summary) != 1 || summary[0].Status != StatusOnline {
			t.Fatalf("expected revived ONLINE machine in summary, got: %+v", summary)
		}
	case <-time.After(1 * time.Second):
		t.Fatal("timeout waiting for revived ONLINE broadcast")
	}
}

// TestWatchdogResilience_MultipleHostsStaggeredTimeouts tests fleet aggregation and sorting
// when multiple hosts have varying silence periods.
func TestWatchdogResilience_MultipleHostsStaggeredTimeouts(t *testing.T) {
	ps := NewPubSub()
	reg := NewRegistry(ps)

	// Host 1: host-c-online
	reg.RecordTelemetry(&ancymonproto.TelemetryFrame{
		MachineId: "host-c-online",
		Hostname:  "charlie",
	})

	// Host 2: host-a-offline
	reg.RecordTelemetry(&ancymonproto.TelemetryFrame{
		MachineId: "host-a-offline",
		Hostname:  "alpha",
	})

	// Host 3: host-b-offline
	reg.RecordTelemetry(&ancymonproto.TelemetryFrame{
		MachineId: "host-b-offline",
		Hostname:  "bravo",
	})

	// Wait 10ms
	time.Sleep(10 * time.Millisecond)

	// Refresh host-c-online so it is brand new
	reg.RecordTelemetry(&ancymonproto.TelemetryFrame{
		MachineId: "host-c-online",
		Hostname:  "charlie",
	})

	// Check with 5ms timeout: host-a and host-b have been silent > 10ms, host-c just arrived
	changed := reg.CheckHeartbeats(5 * time.Millisecond)
	if changed != 2 {
		t.Fatalf("expected 2 silent machines to transition to OFFLINE, got %d", changed)
	}

	summary := reg.GetFleetSummary()
	if len(summary) != 3 {
		t.Fatalf("expected 3 machines in fleet, got %d", len(summary))
	}

	// Fleet sorting rule: ONLINE machines first, then alphabetically by hostname
	if summary[0].MachineID != "host-c-online" || summary[0].Status != StatusOnline {
		t.Errorf("expected first machine to be ONLINE host-c-online, got: %+v", summary[0])
	}
	if summary[1].MachineID != "host-a-offline" || summary[1].Status != StatusOffline {
		t.Errorf("expected second machine to be OFFLINE host-a-offline, got: %+v", summary[1])
	}
	if summary[2].MachineID != "host-b-offline" || summary[2].Status != StatusOffline {
		t.Errorf("expected third machine to be OFFLINE host-b-offline, got: %+v", summary[2])
	}
}

// TestWatchdogResilience_ContinuousBackgroundWorker tests the asynchronous Watchdog worker loop.
func TestWatchdogResilience_ContinuousBackgroundWorker(t *testing.T) {
	ps := NewPubSub()
	reg := NewRegistry(ps)

	fleetCh, unsub := ps.SubscribeFleetSummary()
	defer unsub()

	// Register an active host
	reg.RecordTelemetry(&ancymonproto.TelemetryFrame{
		MachineId: "bg-host-1",
		Hostname:  "bg-worker",
	})

	// Consume initial ONLINE event
	<-fleetCh

	// Start background watchdog with 20ms check interval and 50ms offline threshold
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	wd := NewWatchdog(reg, 20*time.Millisecond, 50*time.Millisecond)
	wd.Start(ctx)

	// Wait for background watchdog to automatically catch silence (> 50ms)
	select {
	case summary := <-fleetCh:
		if len(summary) != 1 {
			t.Fatalf("expected 1 machine in summary, got %d", len(summary))
		}
		if summary[0].Status != StatusOffline {
			t.Errorf("expected background watchdog to transition machine to OFFLINE, got %s", summary[0].Status)
		}
	case <-time.After(2 * time.Second):
		t.Fatal("timeout waiting for background watchdog to detect silent machine")
	}

	// Verify cancellation halts worker cleanly
	cancel()
	time.Sleep(50 * time.Millisecond)
}
