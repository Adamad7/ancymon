package service

import (
	"context"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sync"

	"ancymon/agent/internal/client"
	"ancymon/agent/internal/collector"
	"ancymon/agent/internal/config"
	"ancymon/agent/internal/wal"

	"github.com/kardianos/service"
)

// Program implements service.Interface for kardianos/service.
type Program struct {
	configPath string
	ctx        context.Context
	cancel     context.CancelFunc
	wg         sync.WaitGroup
	dispatcher *client.Dispatcher
}

// NewProgram creates a new service program with the given config path.
func NewProgram(configPath string) *Program {
	ctx, cancel := context.WithCancel(context.Background())
	return &Program{
		configPath: configPath,
		ctx:        ctx,
		cancel:     cancel,
	}
}

// Start is called by kardianos/service when the service starts up.
func (p *Program) Start(s service.Service) error {
	p.wg.Add(1)
	go p.run()
	return nil
}

// run is the main execution body.
func (p *Program) run() {
	defer p.wg.Done()

	resolvedConfigPath := resolveConfigPath(p.configPath)
	log.Printf("Starting ancymon-agent with config at %s", resolvedConfigPath)

	cfg, err := config.Load(resolvedConfigPath)
	if err != nil {
		log.Fatalf("FATAL: Failed to load config: %v", err)
	}

	if err := cfg.Validate(); err != nil {
		log.Printf("WARNING: Config validation warning: %v", err)
	}

	// Resolve buffer dir relative to executable or config directory if relative
	bufferDir := cfg.BufferDir
	if !filepath.IsAbs(bufferDir) {
		bufferDir = filepath.Join(filepath.Dir(resolvedConfigPath), bufferDir)
	}

	// Initialize offline WAL buffer
	w, err := wal.Open(wal.Options{
		Dir:              bufferDir,
		MaxBufferBytes:   int64(cfg.BufferMaxMB) * 1024 * 1024,
		SegmentSizeBytes: wal.DefaultSegmentSizeBytes,
	})
	if err != nil {
		log.Fatalf("FATAL: Failed to initialize WAL buffer at %s: %v", bufferDir, err)
	}
	defer w.Close()

	// Initialize hardware telemetry collector
	col := collector.NewCollector(cfg.MachineID, nil)

	// Initialize and run telemetry dispatcher
	disp := client.NewDispatcher(cfg, col, w, nil)
	p.dispatcher = disp

	log.Printf("ancymon-agent running (machine_id: %s, server: %s, interval: %dms)",
		cfg.MachineID, cfg.ServerAddress, cfg.SamplingIntervalMs)

	if err := disp.Run(p.ctx); err != nil && err != context.Canceled {
		log.Printf("Dispatcher exited with error: %v", err)
	}
}

// Stop is called by kardianos/service on shutdown (SIGINT, SIGTERM, or Service Control Manager).
func (p *Program) Stop(s service.Service) error {
	log.Println("Stopping ancymon-agent...")
	p.cancel()
	p.wg.Wait()
	log.Println("ancymon-agent stopped gracefully.")
	return nil
}

// resolveConfigPath returns the absolute path to config.yaml.
// If the path is relative and not found in current working directory,
// it checks adjacent to the executable.
func resolveConfigPath(path string) string {
	if path == "" {
		path = "config.yaml"
	}

	if filepath.IsAbs(path) {
		return path
	}

	// Check current working directory
	if _, err := os.Stat(path); err == nil {
		abs, err := filepath.Abs(path)
		if err == nil {
			return abs
		}
		return path
	}

	// Check executable directory
	exePath, err := os.Executable()
	if err == nil {
		exeDir := filepath.Dir(exePath)
		candidate := filepath.Join(exeDir, path)
		if _, err := os.Stat(candidate); err == nil {
			return candidate
		}
		// Return candidate next to executable even if not yet created (for first-run auto-creation)
		return candidate
	}

	return path
}

// BuildService creates a kardianos/service instance.
func BuildService(prg *Program, arguments []string) (service.Service, error) {
	svcConfig := &service.Config{
		Name:        "ancymon-agent",
		DisplayName: "AncyMon Host Telemetry Agent",
		Description: "Lightweight background workstation hardware telemetry agent for the AncyMon monitoring system",
		Arguments:   arguments,
		Option: service.KeyValue{
			"Restart":           "always",
			"SuccessExitStatus": "0",
		},
	}

	return service.New(prg, svcConfig)
}

// ExecuteAction performs service commands or runs the service.
func ExecuteAction(action string, configPath string) error {
	prg := NewProgram(configPath)

	var svcArgs []string
	if configPath != "" {
		svcArgs = []string{"-config", resolveConfigPath(configPath)}
	}

	s, err := BuildService(prg, svcArgs)
	if err != nil {
		return fmt.Errorf("failed to create service definition: %w", err)
	}

	switch action {
	case "", "run":
		// Runs as service if called by service manager, or as interactive CLI if in terminal
		return s.Run()
	case "install":
		err = s.Install()
		if err == nil {
			fmt.Println("ancymon-agent service successfully installed.")
		}
		return err
	case "uninstall":
		err = s.Uninstall()
		if err == nil {
			fmt.Println("ancymon-agent service successfully uninstalled.")
		}
		return err
	case "start":
		err = s.Start()
		if err == nil {
			fmt.Println("ancymon-agent service started.")
		}
		return err
	case "stop":
		err = s.Stop()
		if err == nil {
			fmt.Println("ancymon-agent service stopped.")
		}
		return err
	case "restart":
		err = s.Restart()
		if err == nil {
			fmt.Println("ancymon-agent service restarted.")
		}
		return err
	case "status":
		status, err := s.Status()
		if err != nil {
			return fmt.Errorf("failed to get service status: %w", err)
		}
		switch status {
		case service.StatusRunning:
			fmt.Println("ancymon-agent service is running.")
		case service.StatusStopped:
			fmt.Println("ancymon-agent service is stopped.")
		default:
			fmt.Println("ancymon-agent service status is unknown.")
		}
		return nil
	default:
		return fmt.Errorf("unknown service action %q (supported: run, install, uninstall, start, stop, restart, status)", action)
	}
}
