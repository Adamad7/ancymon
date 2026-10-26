# ancymon-server

Central backend server written in Go coordinating gRPC telemetry ingestion, VictoriaMetrics time-series storage, and GraphQL API delivery for the mobile client.

## Key Features
- **gRPC Ingestion**: HTTP/2 streaming on port 50051 (`h2c` behind Caddy) with keepalive enforcement (min 15s) and PSK authorization.
- **In-Memory Cache & Watchdog**: Workstation registry with an automatic Heartbeat Watchdog marking hosts as `offline` after >60s of silence.
- **VictoriaMetrics Integration**: High-throughput ingestion via Influx Line Protocol on `/write` and on-the-fly downsampled historical queries via MetricsQL (`/api/v1/query_range`).
- **GraphQL Engine**: WebSocket subscriptions (`fleetSummary`, `machineMetrics`), HTTPS historical queries, and the `deleteMachine` mutation.
- **Zero-Typing Pairing**: Terminal QR code generator utility encoding minified JSON with stripped ECDSA P-256 CA certificate bytes and PSK token.

## Responsible Subagent
- **`ancymon-server-engineer`**
