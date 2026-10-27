# ancymon-server

Central backend telemetry ingestion engine, time-series storage coordinator, and GraphQL API server for the AncyMon workstation monitoring platform.

---

## Architecture Overview

```
                                      LAN TLS 443 (Caddy Reverse Proxy)
                                                    │
                 ┌──────────────────────────────────┴──────────────────────────────────┐
                 │                                                                     │
                 ▼                                                                     ▼
    gRPC Ingest (Port 50051)                                              GraphQL Engine (Port 8080)
 (HTTP/2 cleartext h2c upstream)                                          (HTTP POST & WebSockets)
                 │                                                                     │
                 ▼                                                                     ▼
       [Bearer PSK Auth]                                                     [Bearer PSK Auth]
                 │                                                                     │
    ┌────────────┴────────────┐                                              ┌─────────┴─────────┐
    │                         │                                              │                   │
    ▼                         ▼                                              ▼                   ▼
In-Memory Registry    Asynchronous Writer                             Subscriptions           Queries
 & Watchdog (>60s)    (Influx Line Protocol)                         (fleetSummary,       (machineHistory,
                              │                                      machineMetrics)       deleteMachine)
                              ▼                                              │                   │
                      VictoriaMetrics                                        └─────────┬─────────┘
                      TSDB (/write)                                                    │
                              ▲                                                        ▼
                              └──────────────── MetricsQL Range Queries ───────────────┘
                                                (/api/v1/query_range)
```

---

## Key Features

1. **gRPC Ingestion Server (`server/internal/grpc`)**:
   - HTTP/2 client streaming implementing `ancymonproto.TelemetryServiceServer` (`StreamTelemetry`).
   - Server keepalive enforcement:
     - `keepalive.EnforcementPolicy.MinTime = 15s`
     - `keepalive.EnforcementPolicy.PermitWithoutStream = true`
     - `keepalive.ServerParameters.Time = 60s`
     - `keepalive.ServerParameters.Timeout = 20s`
   - Pre-Shared Key (PSK) interceptor validating `Authorization: Bearer <TOKEN>` against constant-time secret check.
   - Streaming ack returned on stream closure with count and timestamp.

2. **VictoriaMetrics TSDB Integration (`server/internal/storage`)**:
   - Asynchronous batch worker writing Influx Line Protocol to `/write`:
     - `cpu,machine_id=...,hostname=... total_usage_percent=...[,temperature_c=...] <timestamp_ns>`
     - `memory,machine_id=...,hostname=... total_bytes=...i,used_bytes=...i,usage_percent=... <timestamp_ns>`
     - `network,machine_id=...,hostname=... rx_bytes_per_sec=...i,tx_bytes_per_sec=...i <timestamp_ns>`
     - `disk,machine_id=...,hostname=...,mount_point=...,fs_type=... total_bytes=...i,free_bytes=...i,usage_percent=... <timestamp_ns>`
   - Historical MetricsQL query runner on `/api/v1/query_range` with dynamic downsampling targeting ~100–360 chart points:
     - `RANGE_1H`: 1h -> `step=15s` (240 points)
     - `RANGE_6H`: 6h -> `step=1m` (360 points)
     - `RANGE_12H`: 12h -> `step=2m` (360 points)
     - `RANGE_24H`: 24h -> `step=5m` (288 points)
     - `RANGE_3D`: 3d -> `step=15m` (288 points)
     - `RANGE_7D`: 7d -> `step=30m` (336 points)
     - `CUSTOM_DATE`: calendar date -> `step=5m` (288 points)

3. **In-Memory Registry & Heartbeat Watchdog (`server/internal/watchdog`)**:
   - Thread-safe workstation state registry (`sync.RWMutex`) storing latest telemetry and online/offline status.
   - Background Heartbeat Watchdog: periodically checks silent hosts. If silence exceeds configured threshold (default `60s`), status transitions to `OFFLINE` and broadcasts event to subscribers.
   - `DeleteMachine(machineId)`: unregisters and prunes host from cache and broadcasts updated fleet snapshot.

4. **GraphQL Engine (`server/internal/graphql`)**:
   - Full implementation of `graphql/schema.graphql`.
   - Supports both HTTP POST queries/mutations and WebSocket subscriptions.
   - WebSocket handler supports both the modern RFC standard (`graphql-transport-ws`) and Apollo legacy (`graphql-ws`).
   - Subscription `fleetSummary`: lightweight stream for dashboard list (`machineId`, `hostname`, `status`, CPU %, temp, Net I/O).
   - Subscription `machineMetrics`: full 1 Hz telemetry stream for detail view.
   - Query `machineHistory`: downsampled historical time-series points.
   - Mutation `deleteMachine`: unregisters machine from fleet.

5. **Terminal QR Code Generator (`server/cmd/ancymon-qr`)**:
   - Reads internal root CA certificate (from Caddy local CA or specified path).
   - Strips PEM headers, footers, carriage returns, and newlines to extract raw Base64 DER certificate string (~600–700 chars).
   - Validates ECDSA P-256 certificate properties.
   - Outputs minified JSON matching `graphql/pairing.schema.json`:
     `{"ip":"<ip>","port":443,"token":"<token>","ca":"<ca>"}`
   - Renders compact Unicode half-block QR code directly in the terminal for zero-typing onboarding.

---

## Configuration Reference

The server loads settings from `server/config.example.yaml` or environment variables:

| Environment Variable | YAML Key | Default | Description |
|---|---|---|---|
| `ANCYMON_CONFIG` | - | - | Path to configuration YAML file |
| `ANCYMON_GRPC_PORT` | `server.grpc_port` | `50051` | Cleartext gRPC listening port (`h2c`) |
| `ANCYMON_GRAPHQL_PORT` | `server.graphql_port` | `8080` | HTTP/WS GraphQL listening port |
| `ANCYMON_AUTH_TOKEN` | `server.auth_token` | `ancymon-secret-psk-change-me` | Pre-Shared Key (PSK) secret token |
| `ANCYMON_PUBLIC_IP` | `server.public_ip` | Auto-detected | Server IP presented in QR pairing code |
| `ANCYMON_PUBLIC_PORT` | `server.public_port` | `443` | TLS ingress port terminated by Caddy |
| `ANCYMON_CA_CERT_PATH` | `server.ca_cert_path` | `/data/caddy/pki/authorities/local/root.crt` | Internal CA certificate path |
| `ANCYMON_VM_URL` | `victoriametrics.url` | `http://127.0.0.1:8428` | VictoriaMetrics base URL |
| `ANCYMON_VM_BATCH_SIZE` | `victoriametrics.batch_size` | `100` | Telemetry frame write buffer capacity |
| `ANCYMON_VM_FLUSH_INTERVAL_MS`| `victoriametrics.flush_interval_ms`| `500` | Flush timer interval in milliseconds |
| `ANCYMON_OFFLINE_TIMEOUT_SEC`| `watchdog.offline_timeout_sec` | `60` | Silence duration before marking host OFFLINE |

---

## Build & Test

```bash
# Build binaries into bin/ancymon-server and bin/ancymon-qr
make -C server build

# Run all unit and integration tests with Go race detector
make -C server test

# Generate a pairing QR code in the terminal
make -C server qr

# Run the central server locally
make -C server run
```
