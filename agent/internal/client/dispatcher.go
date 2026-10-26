package client

import (
	"context"
	"errors"
	"log"
	"sync"
	"time"

	"ancymon/agent/internal/collector"
	"ancymon/agent/internal/config"
	"ancymon/agent/internal/wal"
	ancymonproto "ancymon/proto"
)

// AgentState tracks the operational state of the telemetry dispatcher.
type AgentState string

const (
	StateBuffering AgentState = "OFFLINE_BUFFERING"
	StateReplaying AgentState = "REPLAYING_WAL"
	StateLive      AgentState = "LIVE_STREAMING"
)

// ClientFactory allows injecting client creation for unit tests.
type ClientFactory func(cfg Config) (*GRPCClient, error)

// Dispatcher orchestrates sampling ticks, offline WAL persistence, server reconnection, and live streaming.
type Dispatcher struct {
	mu            sync.Mutex
	cfg           *config.Config
	collector     *collector.Collector
	wal           *wal.WAL
	clientFactory ClientFactory

	client     *GRPCClient
	liveStream ancymonproto.TelemetryService_StreamTelemetryClient
	state      AgentState

	// Draining coordination
	drainStopCh chan struct{}
	drainWg     sync.WaitGroup

	// Diagnostics / testing counters
	framesLive     uint64
	framesBuffered uint64
	segmentsReplay uint64
}

// NewDispatcher creates a new telemetry dispatcher.
func NewDispatcher(cfg *config.Config, col *collector.Collector, w *wal.WAL, factory ClientFactory) *Dispatcher {
	if factory == nil {
		factory = Dial
	}
	return &Dispatcher{
		cfg:           cfg,
		collector:     col,
		wal:           w,
		clientFactory: factory,
		state:         StateBuffering,
	}
}

// State returns the current dispatcher operational state.
func (d *Dispatcher) State() AgentState {
	d.mu.Lock()
	defer d.mu.Unlock()
	return d.state
}

// Stats returns diagnostic statistics.
func (d *Dispatcher) Stats() (live uint64, buffered uint64, replayedSegments uint64) {
	d.mu.Lock()
	defer d.mu.Unlock()
	return d.framesLive, d.framesBuffered, d.segmentsReplay
}

// Run executes the main agent loop until context is cancelled.
func (d *Dispatcher) Run(ctx context.Context) error {
	samplingInterval := time.Duration(d.cfg.SamplingIntervalMs) * time.Millisecond
	if samplingInterval < 100*time.Millisecond {
		samplingInterval = 1000 * time.Millisecond
	}

	tickTicker := time.NewTicker(samplingInterval)
	defer tickTicker.Stop()

	// Initial connection attempt
	d.tryConnect(ctx)

	reconnectTicker := time.NewTicker(2 * time.Second)
	defer reconnectTicker.Stop()

	for {
		select {
		case <-ctx.Done():
			d.shutdown()
			return ctx.Err()

		case <-reconnectTicker.C:
			d.mu.Lock()
			needConnect := (d.client == nil)
			d.mu.Unlock()

			if needConnect {
				d.tryConnect(ctx)
			}

		case <-tickTicker.C:
			d.onTick(ctx)
		}
	}
}

// tryConnect attempts to establish a connection to ancymon-server.
func (d *Dispatcher) tryConnect(ctx context.Context) {
	d.mu.Lock()
	if d.client != nil {
		d.mu.Unlock()
		return
	}
	d.mu.Unlock()

	clientCfg := Config{
		ServerAddress: d.cfg.ServerAddress,
		AuthToken:     d.cfg.AuthToken,
		TLSCAPath:     d.cfg.TLSCAPath,
		Insecure:      d.cfg.Insecure,
	}

	cli, err := d.clientFactory(clientCfg)
	if err != nil {
		log.Printf("INFO: Connection to %s unavailable: %v", d.cfg.ServerAddress, err)
		return
	}

	d.mu.Lock()
	d.client = cli

	if d.wal.HasBacklog() {
		d.state = StateReplaying
		log.Printf("INFO: Connected to %s with WAL backlog present. Transitioning to %s", d.cfg.ServerAddress, StateReplaying)
		d.startDrainWorker(ctx)
		d.mu.Unlock()
	} else {
		// Open direct live stream
		stream, err := cli.NewLiveStream(ctx)
		if err != nil {
			log.Printf("WARNING: Failed to open live stream: %v; closing client", err)
			_ = cli.Close()
			d.client = nil
			d.state = StateBuffering
			d.mu.Unlock()
			return
		}
		d.liveStream = stream
		d.state = StateLive
		log.Printf("INFO: Connected to %s with zero backlog. Transitioning to %s", d.cfg.ServerAddress, StateLive)
		d.mu.Unlock()
	}
}

// onTick performs 1 Hz metric sampling and routes the frame.
func (d *Dispatcher) onTick(ctx context.Context) {
	frame, err := d.collector.Collect()
	if err != nil {
		log.Printf("ERROR: Failed to collect telemetry frame: %v", err)
		return
	}

	d.mu.Lock()
	defer d.mu.Unlock()

	switch d.state {
	case StateLive:
		if d.liveStream == nil {
			d.fallbackToBufferingLocked(frame, errors.New("live stream is nil"))
			return
		}

		if err := d.liveStream.Send(frame); err != nil {
			d.fallbackToBufferingLocked(frame, err)
			return
		}
		d.framesLive++

	case StateReplaying:
		// Requirement: When connection restores, new incoming measurements
		// continue to append to the tail of the WAL while the drainer works on the head.
		if err := d.wal.Append(frame); err != nil {
			log.Printf("ERROR: Failed to append frame to WAL tail during replay: %v", err)
		} else {
			d.framesBuffered++
		}

	case StateBuffering:
		if err := d.wal.Append(frame); err != nil {
			log.Printf("ERROR: Failed to append frame to WAL buffer: %v", err)
		} else {
			d.framesBuffered++
		}
	}
}

// fallbackToBufferingLocked handles live stream failure and switches back to buffering.
func (d *Dispatcher) fallbackToBufferingLocked(failedFrame *ancymonproto.TelemetryFrame, cause error) {
	log.Printf("WARNING: Live stream failed (%v); diverting to offline WAL buffer", cause)

	if d.liveStream != nil {
		_ = d.liveStream.CloseSend()
		d.liveStream = nil
	}
	if d.client != nil {
		_ = d.client.Close()
		d.client = nil
	}

	d.state = StateBuffering

	// Buffer the frame that failed to send so it is not lost
	if failedFrame != nil {
		if err := d.wal.Append(failedFrame); err != nil {
			log.Printf("ERROR: Failed to append lost frame to WAL: %v", err)
		} else {
			d.framesBuffered++
		}
	}
}

// startDrainWorker launches the background WAL replay worker.
// Caller MUST hold d.mu.
func (d *Dispatcher) startDrainWorker(ctx context.Context) {
	d.drainStopCh = make(chan struct{})
	d.drainWg.Add(1)

	go d.drainLoop(ctx, d.drainStopCh)
}

// drainLoop sequentially replays completed WAL segments oldest-to-newest.
func (d *Dispatcher) drainLoop(ctx context.Context, stopCh chan struct{}) {
	defer d.drainWg.Done()

	for {
		select {
		case <-ctx.Done():
			return
		case <-stopCh:
			return
		default:
		}

		d.mu.Lock()
		cli := d.client
		d.mu.Unlock()

		if cli == nil {
			return
		}

		completed, err := d.wal.GetCompletedSegments()
		if err != nil {
			log.Printf("ERROR: Failed to query completed WAL segments: %v", err)
			time.Sleep(500 * time.Millisecond)
			continue
		}

		if len(completed) == 0 {
			// Seal active segment to make remaining buffered data completed
			if err := d.wal.SealActiveSegment(); err != nil {
				log.Printf("ERROR: Failed to seal active segment: %v", err)
			}
			completed, _ = d.wal.GetCompletedSegments()
		}

		if len(completed) == 0 {
			// Backlog reached zero! Transition to StateLive
			d.mu.Lock()
			if d.client == cli {
				stream, err := cli.NewLiveStream(ctx)
				if err != nil {
					log.Printf("WARNING: Failed to transition from replay to live stream: %v", err)
					_ = cli.Close()
					d.client = nil
					d.state = StateBuffering
					d.mu.Unlock()
					return
				}
				d.liveStream = stream
				d.state = StateLive
				log.Printf("INFO: WAL backlog completely drained. Transitioned to %s", StateLive)
			}
			d.mu.Unlock()
			return
		}

		// Replay oldest completed segment
		oldestPath := completed[0]
		frames, err := wal.ReadSegment(oldestPath)
		if err != nil {
			log.Printf("ERROR: Failed to read segment %s: %v; skipping", oldestPath, err)
			_ = d.wal.DeleteSegment(oldestPath)
			continue
		}

		ack, err := cli.SendBatch(ctx, frames)
		if err != nil {
			log.Printf("WARNING: Failed to replay segment %s to server: %v; interrupting drain", oldestPath, err)
			d.mu.Lock()
			if d.client == cli {
				_ = cli.Close()
				d.client = nil
				d.state = StateBuffering
			}
			d.mu.Unlock()
			return
		}

		if ack.GetSuccess() {
			if err := d.wal.DeleteSegment(oldestPath); err != nil {
				log.Printf("ERROR: Failed to delete acknowledged segment %s: %v", oldestPath, err)
			} else {
				log.Printf("INFO: WAL segment %s acknowledged by server (%d frames) and deleted",
					oldestPath, ack.GetAcknowledgedCount())
				d.mu.Lock()
				d.segmentsReplay++
				d.mu.Unlock()
			}
		}
	}
}

// shutdown cleanly tears down dispatcher resources.
func (d *Dispatcher) shutdown() {
	d.mu.Lock()
	if d.drainStopCh != nil {
		close(d.drainStopCh)
	}
	d.mu.Unlock()

	d.drainWg.Wait()

	d.mu.Lock()
	defer d.mu.Unlock()

	if d.liveStream != nil {
		_ = d.liveStream.CloseSend()
		d.liveStream = nil
	}
	if d.client != nil {
		_ = d.client.Close()
		d.client = nil
	}
	if d.wal != nil {
		_ = d.wal.Close()
	}
	d.state = StateBuffering
}
