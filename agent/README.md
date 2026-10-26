# ancymon-agent

Host workstation telemetry agent written in Go for Linux and Windows platforms.

## Key Features
- **Static Compilation**: Single executable binary with zero external runtime dependencies (`CGO_ENABLED=0`).
- **Cross-Platform Daemon Lifecycle**: Native `systemd` daemon unit (Linux) and Windows Service Control Manager support via `kardianos/service`.
- **Hardware Telemetry (1 Hz)**: CPU (aggregate utilization, package temperature), RAM (used/total), Network I/O (delta bytes/s), and partition inspection filtered strictly by filesystem whitelist (`ext4`, `xfs`, `btrfs`, `zfs`, `ntfs`, `vfat`, `fat32`, `apfs`).
- **Offline WAL Buffer**: Rotating 1 MB segment files in `./buffer/` with 50 MB ceiling, FIFO eviction, flat RAM footprint (~10–15 MB), and chronological sequential replay on reconnect.
- **gRPC Streaming Client**: Persistent HTTP/2 client streaming with keepalive (30s ping, 10s timeout, permit without stream) and PSK Bearer authorization.

## Responsible Subagent
- **`ancymon-agent-engineer`**
