package config_test

import (
	"os"
	"path/filepath"
	"testing"

	"ancymon/agent/internal/config"

	"github.com/google/uuid"
)

func TestLoad_GeneratesDefaultAndUUID(t *testing.T) {
	tempDir := t.TempDir()
	configPath := filepath.Join(tempDir, "config.yaml")

	cfg, err := config.Load(configPath)
	if err != nil {
		t.Fatalf("unexpected error loading non-existent config: %v", err)
	}

	if cfg.MachineID == "" {
		t.Fatal("expected non-empty machine_id")
	}
	if _, err := uuid.Parse(cfg.MachineID); err != nil {
		t.Fatalf("generated machine_id is not a valid UUID: %v", err)
	}
	if cfg.SamplingIntervalMs != config.DefaultSamplingIntervalMs {
		t.Errorf("expected default sampling interval %d, got %d", config.DefaultSamplingIntervalMs, cfg.SamplingIntervalMs)
	}
	if cfg.BufferDir != config.DefaultBufferDir {
		t.Errorf("expected default buffer dir %q, got %q", config.DefaultBufferDir, cfg.BufferDir)
	}
	if cfg.BufferMaxMB != config.DefaultBufferMaxMB {
		t.Errorf("expected default buffer max mb %d, got %d", config.DefaultBufferMaxMB, cfg.BufferMaxMB)
	}

	// Verify file was written to disk
	if _, err := os.Stat(configPath); err != nil {
		t.Fatalf("expected config file to be written on disk: %v", err)
	}

	// Load again and verify same MachineID is preserved
	loadedAgain, err := config.Load(configPath)
	if err != nil {
		t.Fatalf("unexpected error reloading config: %v", err)
	}
	if loadedAgain.MachineID != cfg.MachineID {
		t.Errorf("expected preserved machine_id %s, got %s", cfg.MachineID, loadedAgain.MachineID)
	}
}

func TestLoad_GeneratesUUIDIfMissingInExistingFile(t *testing.T) {
	tempDir := t.TempDir()
	configPath := filepath.Join(tempDir, "config.yaml")

	initialYAML := `
server_address: "10.0.0.1:443"
auth_token: "secret-token"
sampling_interval_ms: 2000
`
	if err := os.WriteFile(configPath, []byte(initialYAML), 0o600); err != nil {
		t.Fatalf("failed to write initial config: %v", err)
	}

	cfg, err := config.Load(configPath)
	if err != nil {
		t.Fatalf("failed to load config with missing machine_id: %v", err)
	}

	if cfg.MachineID == "" {
		t.Fatal("expected machine_id to be generated")
	}
	if _, err := uuid.Parse(cfg.MachineID); err != nil {
		t.Fatalf("generated machine_id is not a valid UUID: %v", err)
	}
	if cfg.ServerAddress != "10.0.0.1:443" {
		t.Errorf("expected server address 10.0.0.1:443, got %s", cfg.ServerAddress)
	}
	if cfg.SamplingIntervalMs != 2000 {
		t.Errorf("expected sampling interval 2000, got %d", cfg.SamplingIntervalMs)
	}

	// Reload from disk to verify it was written back
	reloaded, err := config.Load(configPath)
	if err != nil {
		t.Fatalf("failed to reload config: %v", err)
	}
	if reloaded.MachineID != cfg.MachineID {
		t.Errorf("expected persisted machine_id %s, got %s", cfg.MachineID, reloaded.MachineID)
	}
}

func TestValidate(t *testing.T) {
	validUUID := uuid.New().String()

	tests := []struct {
		name    string
		cfg     config.Config
		wantErr bool
	}{
		{
			name: "valid config",
			cfg: config.Config{
				MachineID:          validUUID,
				ServerAddress:      "localhost:50051",
				AuthToken:          "psk-123",
				SamplingIntervalMs: 1000,
				BufferDir:          "./buffer",
				BufferMaxMB:        50,
			},
			wantErr: false,
		},
		{
			name: "invalid machine_id",
			cfg: config.Config{
				MachineID:          "not-a-uuid",
				ServerAddress:      "localhost:50051",
				AuthToken:          "psk-123",
				SamplingIntervalMs: 1000,
				BufferDir:          "./buffer",
				BufferMaxMB:        50,
			},
			wantErr: true,
		},
		{
			name: "empty server_address",
			cfg: config.Config{
				MachineID:          validUUID,
				ServerAddress:      "",
				AuthToken:          "psk-123",
				SamplingIntervalMs: 1000,
				BufferDir:          "./buffer",
				BufferMaxMB:        50,
			},
			wantErr: true,
		},
		{
			name: "empty auth_token",
			cfg: config.Config{
				MachineID:          validUUID,
				ServerAddress:      "localhost:50051",
				AuthToken:          "",
				SamplingIntervalMs: 1000,
				BufferDir:          "./buffer",
				BufferMaxMB:        50,
			},
			wantErr: true,
		},
		{
			name: "sampling interval too low",
			cfg: config.Config{
				MachineID:          validUUID,
				ServerAddress:      "localhost:50051",
				AuthToken:          "psk-123",
				SamplingIntervalMs: 50,
				BufferDir:          "./buffer",
				BufferMaxMB:        50,
			},
			wantErr: true,
		},
		{
			name: "buffer max mb zero",
			cfg: config.Config{
				MachineID:          validUUID,
				ServerAddress:      "localhost:50051",
				AuthToken:          "psk-123",
				SamplingIntervalMs: 1000,
				BufferDir:          "./buffer",
				BufferMaxMB:        0,
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.cfg.Validate()
			if (err != nil) != tt.wantErr {
				t.Errorf("Validate() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}
