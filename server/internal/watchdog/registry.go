package watchdog

import (
	ancymonproto "ancymon/proto"
	"sort"
	"sync"
	"time"
)

// Registry maintains the in-memory state of all known workstations.
type Registry struct {
	mu       sync.RWMutex
	machines map[string]*MachineRecord
	pubsub   *PubSub
}

// NewRegistry constructs a new thread-safe workstation registry.
func NewRegistry(ps *PubSub) *Registry {
	if ps == nil {
		ps = NewPubSub()
	}
	return &Registry{
		machines: make(map[string]*MachineRecord),
		pubsub:   ps,
	}
}

// PubSub returns the underlying event broker.
func (r *Registry) PubSub() *PubSub {
	return r.pubsub
}

// RecordTelemetry stores incoming telemetry, marks the host online, and notifies subscribers.
func (r *Registry) RecordTelemetry(frame *ancymonproto.TelemetryFrame) {
	if frame == nil || frame.MachineId == "" {
		return
	}

	r.mu.Lock()
	rec, exists := r.machines[frame.MachineId]
	if !exists {
		rec = &MachineRecord{
			MachineID: frame.MachineId,
		}
		r.machines[frame.MachineId] = rec
	}

	rec.Hostname = frame.Hostname
	rec.Status = StatusOnline
	rec.LastSeen = time.Now()
	rec.LatestFrame = frame

	detail := rec.ToMachineDetail()
	fleetSummary := r.buildFleetSummaryLocked()
	r.mu.Unlock()

	// Broadcast updates outside of the mutex lock
	r.pubsub.BroadcastMachineDetail(detail)
	r.pubsub.BroadcastFleetSummary(fleetSummary)
}

// GetFleetSummary returns a snapshot of all registered workstations.
func (r *Registry) GetFleetSummary() []MachineSummary {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return r.buildFleetSummaryLocked()
}

// GetMachineDetail returns the full telemetry detail for a single workstation.
func (r *Registry) GetMachineDetail(machineID string) (*MachineDetail, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	rec, exists := r.machines[machineID]
	if !exists {
		return nil, false
	}
	return rec.ToMachineDetail(), true
}

// DeleteMachine unregisters and prunes a workstation from the in-memory registry.
// Returns true if the machine existed and was deleted.
func (r *Registry) DeleteMachine(machineID string) bool {
	r.mu.Lock()
	_, exists := r.machines[machineID]
	if !exists {
		r.mu.Unlock()
		return false
	}

	delete(r.machines, machineID)
	summary := r.buildFleetSummaryLocked()
	r.mu.Unlock()

	r.pubsub.BroadcastFleetSummary(summary)
	return true
}

// CheckHeartbeats transitions silent machines to OFFLINE if their last-seen timestamp
// exceeds the configured offline timeout. Returns count of transitioned machines.
func (r *Registry) CheckHeartbeats(offlineTimeout time.Duration) int {
	now := time.Now()
	changedCount := 0

	r.mu.Lock()
	for _, rec := range r.machines {
		if rec.Status == StatusOnline && now.Sub(rec.LastSeen) > offlineTimeout {
			rec.Status = StatusOffline
			changedCount++
		}
	}

	var summary []MachineSummary
	if changedCount > 0 {
		summary = r.buildFleetSummaryLocked()
	}
	r.mu.Unlock()

	if changedCount > 0 {
		r.pubsub.BroadcastFleetSummary(summary)
	}

	return changedCount
}

// buildFleetSummaryLocked constructs the sorted slice of MachineSummary.
// Caller MUST hold r.mu (RLock or Lock).
func (r *Registry) buildFleetSummaryLocked() []MachineSummary {
	summary := make([]MachineSummary, 0, len(r.machines))
	for _, rec := range r.machines {
		summary = append(summary, rec.ToMachineSummary())
	}

	// Sort deterministically: online first, then by hostname
	sort.Slice(summary, func(i, j int) bool {
		if summary[i].Status != summary[j].Status {
			return summary[i].Status == StatusOnline
		}
		return summary[i].Hostname < summary[j].Hostname
	})

	return summary
}
