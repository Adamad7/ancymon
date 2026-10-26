# ancymon-deploy

Infrastruktura wdrożeniowa dla środowiska produkcyjnego (Proxmox VE LXC Debian) oraz środowiska deweloperskiego (Docker Compose).

## Komponenty
- **Caddy Reverse Proxy**: Terminacja TLS (port 443), automatyczne wewnętrzne CA ECDSA P-256 (`tls internal`), routing `h2c` do gRPC (:50051) oraz HTTP/WebSocket do GraphQL (:8080).
- **VictoriaMetrics**: Pojedynczy binarek / kontener TSDB, retention period (np. `-retentionPeriod=90d`), Influx Line Protocol na `/write`, MetricsQL na `/api/v1/query_range`.
- **ancymon-server**: Serwer centralny Go.

## Odpowiedzialny Agent AI
- **`ancymon-server-engineer`**
