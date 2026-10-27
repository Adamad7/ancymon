package watchdog

import (
	"context"
	"log"
	"time"
)

// Watchdog runs a background loop checking for silent workstations and marking them offline.
type Watchdog struct {
	registry       *Registry
	checkInterval  time.Duration
	offlineTimeout time.Duration
}

// NewWatchdog creates a watchdog worker instance.
func NewWatchdog(reg *Registry, checkInterval, offlineTimeout time.Duration) *Watchdog {
	if checkInterval <= 0 {
		checkInterval = 5 * time.Second
	}
	if offlineTimeout <= 0 {
		offlineTimeout = 60 * time.Second
	}
	return &Watchdog{
		registry:       reg,
		checkInterval:  checkInterval,
		offlineTimeout: offlineTimeout,
	}
}

// Start launches the watchdog goroutine. It terminates when ctx is cancelled.
func (w *Watchdog) Start(ctx context.Context) {
	go func() {
		ticker := time.NewTicker(w.checkInterval)
		defer ticker.Stop()

		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				if n := w.registry.CheckHeartbeats(w.offlineTimeout); n > 0 {
					log.Printf("[Watchdog] Transitioned %d silent host(s) to OFFLINE (timeout=%v)", n, w.offlineTimeout)
				}
			}
		}
	}()
}
