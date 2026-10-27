package watchdog

import (
	"sync"
	"sync/atomic"
)

// PubSub manages pub/sub subscriptions for fleet summaries and per-machine metrics streams.
type PubSub struct {
	mu           sync.RWMutex
	fleetSubs    map[uint64]chan []MachineSummary
	machineSubs  map[string]map[uint64]chan *MachineDetail
	nextSubID    uint64
}

// NewPubSub creates an initialized PubSub broker.
func NewPubSub() *PubSub {
	return &PubSub{
		fleetSubs:   make(map[uint64]chan []MachineSummary),
		machineSubs: make(map[string]map[uint64]chan *MachineDetail),
	}
}

// SubscribeFleetSummary registers a listener for full fleet summary updates.
// Returns a buffered channel receiving updates and an unsubscribe cleanup function.
func (ps *PubSub) SubscribeFleetSummary() (<-chan []MachineSummary, func()) {
	subID := atomic.AddUint64(&ps.nextSubID, 1)
	ch := make(chan []MachineSummary, 16)

	ps.mu.Lock()
	ps.fleetSubs[subID] = ch
	ps.mu.Unlock()

	unsubscribe := func() {
		ps.mu.Lock()
		defer ps.mu.Unlock()
		if c, exists := ps.fleetSubs[subID]; exists {
			delete(ps.fleetSubs, subID)
			close(c)
		}
	}

	return ch, unsubscribe
}

// SubscribeMachineMetrics registers a listener for 1 Hz detailed metrics for a specific machine.
// Returns a buffered channel and an unsubscribe cleanup function.
func (ps *PubSub) SubscribeMachineMetrics(machineID string) (<-chan *MachineDetail, func()) {
	subID := atomic.AddUint64(&ps.nextSubID, 1)
	ch := make(chan *MachineDetail, 16)

	ps.mu.Lock()
	if _, exists := ps.machineSubs[machineID]; !exists {
		ps.machineSubs[machineID] = make(map[uint64]chan *MachineDetail)
	}
	ps.machineSubs[machineID][subID] = ch
	ps.mu.Unlock()

	unsubscribe := func() {
		ps.mu.Lock()
		defer ps.mu.Unlock()
		if subs, exists := ps.machineSubs[machineID]; exists {
			if c, ok := subs[subID]; ok {
				delete(subs, subID)
				close(c)
			}
			if len(subs) == 0 {
				delete(ps.machineSubs, machineID)
			}
		}
	}

	return ch, unsubscribe
}

// BroadcastFleetSummary sends the latest fleet summary to all active fleet subscribers.
// Performs non-blocking channel delivery to avoid starving the engine.
func (ps *PubSub) BroadcastFleetSummary(summary []MachineSummary) {
	ps.mu.RLock()
	defer ps.mu.RUnlock()

	for _, ch := range ps.fleetSubs {
		select {
		case ch <- summary:
		default:
			// Drain previous stale item to make room for newest state
			select {
			case <-ch:
			default:
			}
			select {
			case ch <- summary:
			default:
			}
		}
	}
}

// BroadcastMachineDetail sends the detailed metrics frame to subscribers watching this machine.
func (ps *PubSub) BroadcastMachineDetail(detail *MachineDetail) {
	if detail == nil {
		return
	}

	ps.mu.RLock()
	defer ps.mu.RUnlock()

	subs, exists := ps.machineSubs[detail.MachineID]
	if !exists {
		return
	}

	for _, ch := range subs {
		select {
		case ch <- detail:
		default:
			select {
			case <-ch:
			default:
			}
			select {
			case ch <- detail:
			default:
			}
		}
	}
}
