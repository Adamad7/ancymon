# ancymon-deploy

Deployment infrastructure configurations for production (Proxmox VE LXC Debian container) and local development (Docker Compose).

## Components
- **Caddy Reverse Proxy**: Ingress TLS termination on port 443 with internal ECDSA P-256 automated CA (`tls internal`), `h2c` proxying to gRPC (:50051), and HTTP/WebSocket proxying to GraphQL (:8080).
- **VictoriaMetrics**: Single-node TSDB binary/container execution, configured retention period (e.g. `-retentionPeriod=90d`), Influx Line Protocol on `/write`, and MetricsQL on `/api/v1/query_range`.
- **ancymon-server**: Central Go backend service.

## Responsible Subagent
- **`ancymon-server-engineer`**
