package config

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/google/uuid"
	"gopkg.in/yaml.v3"
)

const (
	DefaultSamplingIntervalMs uint32 = 1000
	DefaultBufferDir                 = "./buffer/"
	DefaultBufferMaxMB        uint32 = 50
	DefaultConfigFileName            = "config.yaml"
)

// Config represents the runtime configuration for ancymon-agent.
type Config struct {
	// MachineID is the persistent UUID v4 uniquely identifying the host.
	MachineID string `yaml:"machine_id"`

	// ServerAddress is the target ancymon-server address (e.g., "192.168.1.100:443" or "localhost:50051").
	ServerAddress string `yaml:"server_address"`

	// AuthToken is the Pre-Shared Key (PSK) for Bearer authentication.
	AuthToken string `yaml:"auth_token"`

	// TLSCAPath is the optional path to a trusted root CA certificate (e.g. Caddy internal ECDSA CA).
	TLSCAPath string `yaml:"tls_ca_path,omitempty"`

	// Insecure allows cleartext HTTP/2 transport without TLS (primarily for local development/testing).
	Insecure bool `yaml:"insecure,omitempty"`

	// SamplingIntervalMs is the frequency of telemetry collection in milliseconds (default: 1000 ms = 1 Hz).
	SamplingIntervalMs uint32 `yaml:"sampling_interval_ms"`

	// BufferDir is the directory where offline WAL segment files are stored (default: "./buffer/").
	BufferDir string `yaml:"buffer_dir"`

	// BufferMaxMB is the maximum total size in megabytes for offline WAL segments (default: 50 MB).
	BufferMaxMB uint32 `yaml:"buffer_max_mb"`
}

// Load loads or creates configuration from the specified file path.
// If the file does not exist, an initial config with a new persistent UUID v4 is created and saved.
// If machine_id is missing or empty in an existing file, a new UUID v4 is generated and persisted back to the file.
func Load(path string) (*Config, error) {
	if path == "" {
		path = DefaultConfigFileName
	}

	data, err := os.ReadFile(path)
	if errors.Is(err, os.ErrNotExist) {
		// Create default config with fresh UUID
		cfg := &Config{
			MachineID:          uuid.New().String(),
			ServerAddress:      "127.0.0.1:443",
			AuthToken:          "replace-with-pre-shared-token",
			SamplingIntervalMs: DefaultSamplingIntervalMs,
			BufferDir:          DefaultBufferDir,
			BufferMaxMB:        DefaultBufferMaxMB,
		}
		if err := cfg.Save(path); err != nil {
			return nil, fmt.Errorf("failed to create default config at %s: %w", path, err)
		}
		return cfg, nil
	} else if err != nil {
		return nil, fmt.Errorf("failed to read config file %s: %w", path, err)
	}

	cfg := &Config{}
	if err := yaml.Unmarshal(data, cfg); err != nil {
		return nil, fmt.Errorf("failed to parse config YAML: %w", err)
	}

	// Apply defaults if zero
	if cfg.SamplingIntervalMs == 0 {
		cfg.SamplingIntervalMs = DefaultSamplingIntervalMs
	}
	if cfg.BufferDir == "" {
		cfg.BufferDir = DefaultBufferDir
	}
	if cfg.BufferMaxMB == 0 {
		cfg.BufferMaxMB = DefaultBufferMaxMB
	}

	// Ensure machine_id exists and is valid UUID v4
	needsSave := false
	if strings.TrimSpace(cfg.MachineID) == "" {
		cfg.MachineID = uuid.New().String()
		needsSave = true
	} else {
		// Validate existing UUID
		if _, err := uuid.Parse(cfg.MachineID); err != nil {
			return nil, fmt.Errorf("invalid machine_id %q: must be a valid UUID v4: %w", cfg.MachineID, err)
		}
	}

	if needsSave {
		if err := cfg.Save(path); err != nil {
			return nil, fmt.Errorf("failed to persist updated machine_id to %s: %w", path, err)
		}
	}

	return cfg, nil
}

// Validate checks the consistency of configuration parameters.
func (c *Config) Validate() error {
	if strings.TrimSpace(c.MachineID) == "" {
		return errors.New("machine_id must not be empty")
	}
	if _, err := uuid.Parse(c.MachineID); err != nil {
		return fmt.Errorf("invalid machine_id %q: %w", c.MachineID, err)
	}
	if strings.TrimSpace(c.ServerAddress) == "" {
		return errors.New("server_address must not be empty")
	}
	if strings.TrimSpace(c.AuthToken) == "" {
		return errors.New("auth_token must not be empty")
	}
	if c.SamplingIntervalMs < 100 {
		return fmt.Errorf("sampling_interval_ms (%d) is too low; must be at least 100 ms", c.SamplingIntervalMs)
	}
	if c.BufferMaxMB < 1 {
		return fmt.Errorf("buffer_max_mb (%d) must be at least 1 MB", c.BufferMaxMB)
	}
	if strings.TrimSpace(c.BufferDir) == "" {
		return errors.New("buffer_dir must not be empty")
	}
	if c.TLSCAPath != "" {
		if _, err := os.Stat(c.TLSCAPath); err != nil {
			return fmt.Errorf("tls_ca_path %q is not accessible: %w", c.TLSCAPath, err)
		}
	}
	return nil
}

// Save serializes the configuration back to disk at the given path.
func (c *Config) Save(path string) error {
	dir := filepath.Dir(path)
	if dir != "" && dir != "." {
		if err := os.MkdirAll(dir, 0o750); err != nil {
			return fmt.Errorf("failed to create config directory %s: %w", dir, err)
		}
	}

	data, err := yaml.Marshal(c)
	if err != nil {
		return fmt.Errorf("failed to marshal config: %w", err)
	}

	// Write atomically using temporary file
	tmpPath := path + ".tmp"
	if err := os.WriteFile(tmpPath, data, 0o600); err != nil {
		return fmt.Errorf("failed to write temporary config: %w", err)
	}

	if err := os.Rename(tmpPath, path); err != nil {
		_ = os.Remove(tmpPath)
		return fmt.Errorf("failed to commit config to %s: %w", path, err)
	}

	return nil
}
