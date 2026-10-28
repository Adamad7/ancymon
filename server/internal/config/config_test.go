package config

import (
	"os"
	"path/filepath"
	"testing"
)

func TestDefaultConfig(t *testing.T) {
	cfg := DefaultConfig()
	if cfg.Server.GrpcPort != 50051 {
		t.Fatalf("expected GrpcPort 50051, got %d", cfg.Server.GrpcPort)
	}
	if cfg.Server.GraphQLPort != 8080 {
		t.Fatalf("expected GraphQLPort 8080, got %d", cfg.Server.GraphQLPort)
	}
	if cfg.VictoriaMetrics.URL != "http://127.0.0.1:8428" {
		t.Fatalf("expected VM URL http://127.0.0.1:8428, got %s", cfg.VictoriaMetrics.URL)
	}
	if cfg.Watchdog.OfflineTimeoutSec != 60 {
		t.Fatalf("expected OfflineTimeoutSec 60, got %d", cfg.Watchdog.OfflineTimeoutSec)
	}
	if cfg.Server.StatePath != "data/workstations.json" {
		t.Fatalf("expected StatePath data/workstations.json, got %s", cfg.Server.StatePath)
	}
}

func TestLoadConfigFile(t *testing.T) {
	yamlData := `
server:
  grpc_port: 5555
  graphql_port: 9999
  auth_token: "custom-token"
  state_path: "custom/path.json"
victoriametrics:
  url: "http://vm.local:8428/"
  batch_size: 50
watchdog:
  offline_timeout_sec: 120
`
	tmpDir := t.TempDir()
	configPath := filepath.Join(tmpDir, "config.yaml")
	if err := os.WriteFile(configPath, []byte(yamlData), 0600); err != nil {
		t.Fatalf("failed to write temp config: %v", err)
	}

	cfg, err := LoadConfig(configPath)
	if err != nil {
		t.Fatalf("LoadConfig failed: %v", err)
	}

	if cfg.Server.GrpcPort != 5555 {
		t.Errorf("expected GrpcPort 5555, got %d", cfg.Server.GrpcPort)
	}
	if cfg.Server.GraphQLPort != 9999 {
		t.Errorf("expected GraphQLPort 9999, got %d", cfg.Server.GraphQLPort)
	}
	if cfg.Server.AuthToken != "custom-token" {
		t.Errorf("expected custom-token, got %s", cfg.Server.AuthToken)
	}
	if cfg.Server.StatePath != "custom/path.json" {
		t.Errorf("expected custom/path.json, got %s", cfg.Server.StatePath)
	}
	if cfg.VictoriaMetrics.URL != "http://vm.local:8428" {
		t.Errorf("expected URL normalized to http://vm.local:8428, got %s", cfg.VictoriaMetrics.URL)
	}
	if cfg.VictoriaMetrics.BatchSize != 50 {
		t.Errorf("expected BatchSize 50, got %d", cfg.VictoriaMetrics.BatchSize)
	}
	if cfg.Watchdog.OfflineTimeoutSec != 120 {
		t.Errorf("expected OfflineTimeoutSec 120, got %d", cfg.Watchdog.OfflineTimeoutSec)
	}
}

func TestEnvOverrides(t *testing.T) {
	t.Setenv("ANCYMON_GRPC_PORT", "60000")
	t.Setenv("ANCYMON_AUTH_TOKEN", "env-secret")
	t.Setenv("ANCYMON_STATE_PATH", "env/state.json")
	t.Setenv("ANCYMON_VM_URL", "http://env-vm:8428")

	cfg, err := LoadConfig("")
	if err != nil {
		t.Fatalf("LoadConfig failed: %v", err)
	}

	if cfg.Server.GrpcPort != 60000 {
		t.Errorf("expected GrpcPort 60000, got %d", cfg.Server.GrpcPort)
	}
	if cfg.Server.AuthToken != "env-secret" {
		t.Errorf("expected env-secret, got %s", cfg.Server.AuthToken)
	}
	if cfg.Server.StatePath != "env/state.json" {
		t.Errorf("expected env/state.json, got %s", cfg.Server.StatePath)
	}
	if cfg.VictoriaMetrics.URL != "http://env-vm:8428" {
		t.Errorf("expected http://env-vm:8428, got %s", cfg.VictoriaMetrics.URL)
	}
}
