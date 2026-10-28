package watchdog

import (
	ancymonproto "ancymon/proto"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"time"
)

// Registry maintains the in-memory state of all known workstations,
// and optionally persists workstation records to disk across server restarts.
type Registry struct {
	mu        sync.RWMutex
	machines  map[string]*MachineRecord
	pubsub    *PubSub
	statePath string
	saveMu    sync.Mutex
}

// NewRegistry constructs a new thread-safe workstation registry.
// An optional statePath parameter may be provided for persistent state storage.
func NewRegistry(ps *PubSub, statePath ...string) *Registry {
	if ps == nil {
		ps = NewPubSub()
	}
	reg := &Registry{
		machines: make(map[string]*MachineRecord),
		pubsub:   ps,
	}
	if len(statePath) > 0 && statePath[0] != "" {
		reg.statePath = statePath[0]
		_ = reg.LoadState(statePath[0])
	}
	return reg
}

// PubSub returns the underlying event broker.
func (r *Registry) PubSub() *PubSub {
	return r.pubsub
}

// StatePath returns the configured persistent state file path.
func (r *Registry) StatePath() string {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return r.statePath
}

// SetStateFile configures the persistent state file path and loads any existing state.
func (r *Registry) SetStateFile(path string) error {
	return r.LoadState(path)
}

// LoadState loads workstation records from disk. All loaded machines are
// initialized with StatusOffline so that silent hosts appear offline until they reconnect.
func (r *Registry) LoadState(path string) error {
	r.saveMu.Lock()
	defer r.saveMu.Unlock()

	if path == "" {
		return nil
	}

	data, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			r.mu.Lock()
			r.statePath = path
			r.mu.Unlock()
			return nil
		}
		return fmt.Errorf("failed to read state file %q: %w", path, err)
	}

	if len(strings.TrimSpace(string(data))) == 0 {
		r.mu.Lock()
		r.statePath = path
		r.mu.Unlock()
		return nil
	}

	var persisted map[string]*MachineRecord
	if err := json.Unmarshal(data, &persisted); err != nil {
		return fmt.Errorf("failed to parse state file %q: %w", path, err)
	}

	r.mu.Lock()
	r.statePath = path
	for id, rec := range persisted {
		if rec == nil || id == "" {
			continue
		}
		rec.MachineID = id
		rec.Status = StatusOffline // Machines loaded from disk are always initialized as OFFLINE
		r.machines[id] = rec
	}
	fleetSummary := r.buildFleetSummaryLocked()
	r.mu.Unlock()

	// Broadcast the initial loaded fleet summary
	if len(fleetSummary) > 0 {
		r.pubsub.BroadcastFleetSummary(fleetSummary)
	}

	return nil
}

// SaveState persists the in-memory workstation records to disk atomically.
func (r *Registry) SaveState() error {
	r.saveMu.Lock()
	defer r.saveMu.Unlock()

	r.mu.RLock()
	statePath := r.statePath
	if statePath == "" {
		r.mu.RUnlock()
		return nil
	}

	// Create snapshot of machines to avoid holding r.mu during disk I/O
	snapshot := make(map[string]*MachineRecord, len(r.machines))
	for id, rec := range r.machines {
		snapshot[id] = &MachineRecord{
			MachineID:   rec.MachineID,
			Hostname:    rec.Hostname,
			Status:      rec.Status,
			LastSeen:    rec.LastSeen,
			LatestFrame: rec.LatestFrame,
		}
	}
	r.mu.RUnlock()

	data, err := json.MarshalIndent(snapshot, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal registry state: %w", err)
	}

	dir := filepath.Dir(statePath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("failed to create state directory %q: %w", dir, err)
	}

	tmpFile, err := os.CreateTemp(dir, "workstations-*.tmp")
	if err != nil {
		return fmt.Errorf("failed to create temp file for state: %w", err)
	}
	tmpName := tmpFile.Name()

	if _, err := tmpFile.Write(data); err != nil {
		_ = tmpFile.Close()
		_ = os.Remove(tmpName)
		return fmt.Errorf("failed to write state temp file: %w", err)
	}

	if err := tmpFile.Sync(); err != nil {
		_ = tmpFile.Close()
		_ = os.Remove(tmpName)
		return fmt.Errorf("failed to sync state temp file: %w", err)
	}

	if err := tmpFile.Close(); err != nil {
		_ = os.Remove(tmpName)
		return fmt.Errorf("failed to close state temp file: %w", err)
	}

	if err := os.Rename(tmpName, statePath); err != nil {
		_ = os.Remove(tmpName)
		return fmt.Errorf("failed to rename state temp file to %q: %w", statePath, err)
	}

	return nil
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

	// Persist updated state to disk
	if err := r.SaveState(); err != nil {
		log.Printf("[Watchdog] Warning: Failed to persist state: %v", err)
	}

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

	// Persist updated state to disk
	if err := r.SaveState(); err != nil {
		log.Printf("[Watchdog] Warning: Failed to persist state after deletion: %v", err)
	}

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
		_ = r.SaveState()
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
