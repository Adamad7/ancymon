package config

import (
	"fmt"
	"net"
	"os"
	"strconv"
	"strings"

	"gopkg.in/yaml.v3"
)

// ServerConfig defines network listening and security parameters.
type ServerConfig struct {
	GrpcPort    int    `yaml:"grpc_port"`
	GraphQLPort int    `yaml:"graphql_port"`
	AuthToken   string `yaml:"auth_token"`
	PublicIP    string `yaml:"public_ip"`
	PublicPort  int    `yaml:"public_port"`
	CaCertPath  string `yaml:"ca_cert_path"`
	StatePath   string `yaml:"state_path"`
}

// VictoriaMetricsConfig defines the TSDB connection and buffering parameters.
type VictoriaMetricsConfig struct {
	URL             string `yaml:"url"`
	BatchSize       int    `yaml:"batch_size"`
	FlushIntervalMs int    `yaml:"flush_interval_ms"`
}

// WatchdogConfig defines workstation liveness watchdog thresholds.
type WatchdogConfig struct {
	CheckIntervalSec  int `yaml:"check_interval_sec"`
	OfflineTimeoutSec int `yaml:"offline_timeout_sec"`
}

// Config bundles all configuration options for ancymon-server.
type Config struct {
	Server          ServerConfig          `yaml:"server"`
	VictoriaMetrics VictoriaMetricsConfig `yaml:"victoriametrics"`
	Watchdog        WatchdogConfig        `yaml:"watchdog"`
}

// DefaultConfig returns the standard production defaults.
func DefaultConfig() *Config {
	return &Config{
		Server: ServerConfig{
			GrpcPort:    50051,
			GraphQLPort: 8080,
			AuthToken:   "ancymon-secret-psk-change-me",
			PublicIP:    detectOutboundIP(),
			PublicPort:  443,
			CaCertPath:  "/data/caddy/pki/authorities/local/root.crt",
			StatePath:   "data/workstations.json",
		},
		VictoriaMetrics: VictoriaMetricsConfig{
			URL:             "http://127.0.0.1:8428",
			BatchSize:       100,
			FlushIntervalMs: 500,
		},
		Watchdog: WatchdogConfig{
			CheckIntervalSec:  5,
			OfflineTimeoutSec: 60,
		},
	}
}

// LoadConfig loads the configuration from an optional YAML file path and environment variables.
func LoadConfig(path string) (*Config, error) {
	cfg := DefaultConfig()

	// If path is not explicitly provided, check ANCYMON_CONFIG
	if path == "" {
		path = os.Getenv("ANCYMON_CONFIG")
	}

	if path != "" {
		data, err := os.ReadFile(path)
		if err != nil {
			return nil, fmt.Errorf("failed to read config file %q: %w", path, err)
		}
		if err := yaml.Unmarshal(data, cfg); err != nil {
			return nil, fmt.Errorf("failed to parse config file %q: %w", path, err)
		}
	}

	// Environment variable overrides
	if val := os.Getenv("ANCYMON_GRPC_PORT"); val != "" {
		if p, err := strconv.Atoi(val); err == nil && p > 0 {
			cfg.Server.GrpcPort = p
		}
	}
	if val := os.Getenv("ANCYMON_GRAPHQL_PORT"); val != "" {
		if p, err := strconv.Atoi(val); err == nil && p > 0 {
			cfg.Server.GraphQLPort = p
		}
	}
	if val := os.Getenv("ANCYMON_AUTH_TOKEN"); val != "" {
		cfg.Server.AuthToken = strings.TrimSpace(val)
	}
	if val := os.Getenv("ANCYMON_PUBLIC_IP"); val != "" {
		cfg.Server.PublicIP = strings.TrimSpace(val)
	}
	if val := os.Getenv("ANCYMON_PUBLIC_PORT"); val != "" {
		if p, err := strconv.Atoi(val); err == nil && p > 0 {
			cfg.Server.PublicPort = p
		}
	}
	if val := os.Getenv("ANCYMON_CA_CERT_PATH"); val != "" {
		cfg.Server.CaCertPath = strings.TrimSpace(val)
	}
	if val := os.Getenv("ANCYMON_STATE_PATH"); val != "" {
		cfg.Server.StatePath = strings.TrimSpace(val)
	}
	if val := os.Getenv("ANCYMON_VM_URL"); val != "" {
		cfg.VictoriaMetrics.URL = strings.TrimRight(strings.TrimSpace(val), "/")
	}
	if val := os.Getenv("ANCYMON_VM_BATCH_SIZE"); val != "" {
		if b, err := strconv.Atoi(val); err == nil && b > 0 {
			cfg.VictoriaMetrics.BatchSize = b
		}
	}
	if val := os.Getenv("ANCYMON_VM_FLUSH_INTERVAL_MS"); val != "" {
		if f, err := strconv.Atoi(val); err == nil && f > 0 {
			cfg.VictoriaMetrics.FlushIntervalMs = f
		}
	}
	if val := os.Getenv("ANCYMON_OFFLINE_TIMEOUT_SEC"); val != "" {
		if t, err := strconv.Atoi(val); err == nil && t > 0 {
			cfg.Watchdog.OfflineTimeoutSec = t
		}
	}

	// Normalize VM URL
	cfg.VictoriaMetrics.URL = strings.TrimRight(cfg.VictoriaMetrics.URL, "/")

	return cfg, nil
}

// detectOutboundIP attempts to discover the primary outbound IP address of the local machine.
func detectOutboundIP() string {
	conn, err := net.Dial("udp", "8.8.8.8:80")
	if err != nil {
		return "127.0.0.1"
	}
	defer conn.Close()

	localAddr, ok := conn.LocalAddr().(*net.UDPAddr)
	if !ok || localAddr.IP == nil {
		return "127.0.0.1"
	}
	return localAddr.IP.String()
}
