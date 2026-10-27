# AncyMon Deployment & Operations Manual

This guide provides exhaustive, production-grade instructions for deploying, configuring, and operating the **AncyMon** telemetry infrastructure across both local development environments (Docker Compose) and dedicated production environments (Proxmox VE LXC Debian container).

---

## Architecture & Communication Topology

```
                         LAN Workstations & Mobile Clients
                                         │
                                         │ Port 443 (TLS Encrypted)
                                         ▼
                 ┌───────────────────────────────────────────────┐
                 │       Caddy Reverse Proxy & Internal CA       │
                 │   (TLS Termination, ECDSA P-256 Certificates) │
                 └───────┬───────────────────────────────┬───────┘
                         │                               │
       gRPC HTTP/2 (h2c) │ Port 50051       GraphQL HTTP │ Port 8080
       Client Streaming  │                  & WebSocket  │
                         ▼                               ▼
                 ┌───────────────────────────────────────────────┐
                 │                ancymon-server                 │
                 │   - Workstation Registry & Watchdog (>60s)    │
                 │   - Asynchronous TSDB Batch Ingestion Buffer  │
                 │   - Dynamic MetricsQL Range Query Downsampler │
                 │   - Terminal Pairing QR Generator Engine      │
                 └───────────────────────┬───────────────────────┘
                                         │ Influx Line Protocol
                                         │ HTTP POST /write (:8428)
                                         ▼
                 ┌───────────────────────────────────────────────┐
                 │                VictoriaMetrics                │
                 │          (Single-Node Time-Series TSDB)       │
                 │   - 90-day Retention Period                   │
                 │   - On-the-fly MetricsQL Rollups              │
                 └───────────────────────────────────────────────┘
```

---

## Section 1: Local Test / Development Environment (Docker Compose)

The local test environment allows developers to spin up the supporting infrastructure (VictoriaMetrics and Caddy) with a single command, compile and run `ancymon-server` on the host, pair mobile or testing clients via terminal QR code, and attach `ancymon-agent` instances locally.

### 1.1. Prerequisites

Ensure the following tools are installed on your workstation:
* **Docker Engine** (v24.0+) & **Docker Compose** (v2.20+)
* **Go** (v1.22+ with `CGO_ENABLED=0` capability)
* Standard CLI utilities: `curl`, `openssl`, `bash`, `make`

### 1.2. Local Stack Components

| Service | Container Name | Host Binding | Function |
|---|---|---|---|
| **VictoriaMetrics** | `ancymon-victoriametrics` | `:8428` | Single-node TSDB storing telemetry metrics (`vmdata` volume). |
| **Caddy** | `ancymon-caddy` | `:443` (host net) | TLS gateway terminating LAN connections with an internal ECDSA P-256 CA. |
| **ancymon-server** | Native host process | `:50051`, `:8080` | Central backend processing gRPC stream ingestion and GraphQL API. |
| **ancymon-agent** | Native host process | - | Workstation telemetry agent running at 1 Hz with offline WAL buffer. |

### 1.3. Step-by-Step Local Deployment

#### Step 1: Start the Docker Infrastructure
From the project root directory, launch VictoriaMetrics and Caddy in the background:

```bash
docker compose -f deploy/docker-compose.yml up -d
```

Verify that both containers are running and healthy:

```bash
docker compose -f deploy/docker-compose.yml ps
```

*Expected output:*
```text
NAME                     IMAGE                                COMMAND                  SERVICE             CREATED         STATUS         PORTS
ancymon-caddy            caddy:2.7.6-alpine                   "caddy run --config …"   caddy               5 seconds ago   Up 4 seconds   
ancymon-victoriametrics  victoriametrics/victoria-metrics:... "-storageDataPath=/v…"   victoriametrics     5 seconds ago   Up 4 seconds   0.0.0.0:8428->8428/tcp
```

#### Step 2: Run Automated Infrastructure Verification
Execute the automated test script to validate VictoriaMetrics ingestion, MetricsQL range queries, Caddy TLS termination, and the internal ECDSA P-256 certificate:

```bash
./deploy/test_vm.sh
```

*Expected output:*
```text
[INFO] 1. Verifying VictoriaMetrics health status on port 8428...
[PASS] VictoriaMetrics is healthy (http://localhost:8428/health returned 'OK').
[INFO] 2. Ingesting telemetry sample via Influx Line Protocol...
[PASS] Metric successfully ingested (HTTP 204 No Content).
[INFO] 3. Querying VictoriaMetrics with MetricsQL (/api/v1/query_range and /api/v1/query)...
[PASS] Instantaneous MetricsQL query returned matching series and metric value (25.5).
[PASS] MetricsQL query_range successfully retrieved historical time-series points.
[INFO] 4. Testing Caddy reverse proxy on port 443...
[PASS] Caddy ingress gateway responded with 200 OK: 'AncyMon Telemetry Gateway Online'.
[INFO] 5. Verifying internal ECDSA P-256 CA and TLS certificate negotiation...
[PASS] Caddy TLS certificate is confirmed ECDSA P-256 (prime256v1).
[PASS] Internal Root CA certificate exists in persistent storage and uses ECDSA P-256.

======================================================================
All AncyMon Phase 1 infrastructure tests PASSED successfully!
======================================================================
```

#### Step 3: Extract the Caddy Internal Root CA Certificate
Because Caddy generates its internal ECDSA P-256 Root CA inside the persistent Docker volume, copy the root certificate to the workspace so that `ancymon-agent` and `ancymon-qr` can locate it:

```bash
docker cp ancymon-caddy:/data/caddy/pki/authorities/local/root.crt deploy/root.crt
```

Inspect the certificate properties:

```bash
openssl x509 -in deploy/root.crt -text -noout | grep -E "(Issuer|Subject|Public Key Algorithm|ASN1 OID)"
```

#### Step 4: Run `ancymon-server` Locally
Run the central server using the default configuration file:

```bash
# Using Makefile
make -C server run

# Or directly with go run:
go run ./server/cmd/ancymon-server -config server/config.example.yaml
```

*Server console output:*
```text
[Config] gRPC Port: :50051 | GraphQL Port: :8080 | VM URL: http://127.0.0.1:8428
[gRPC] Telemetry ingestion server listening on :50051 (h2c)
[GraphQL] Mobile client API listening on :8080 (HTTP/WS)
[Watchdog] Background heartbeat watchdog started (interval: 5s, timeout: 60s)
```

#### Step 5: Generate Mobile Pairing QR Code
To pair a mobile client in local development, generate the pairing QR code in another terminal:

```bash
# Using Makefile
make -C server qr

# Or specifying the copied root CA:
go run ./server/cmd/ancymon-qr -ca deploy/root.crt
```

The CLI renders a high-contrast Unicode half-block QR code directly in the terminal, encoding the minified JSON payload containing the LAN IP, port 443, PSK token, and stripped raw Base64 ECDSA root certificate.

#### Step 6: Build and Run Host Agent Locally
In a new terminal window, build the static Linux agent binary and start telemetry streaming:

```bash
# Build the agent static binary
make -C agent build-linux

# Prepare local test configuration
cp agent/config.example.yaml agent/config.local.yaml
```

Edit `agent/config.local.yaml` to point to localhost port 443 and the extracted root CA:
```yaml
machine_id: ""
server_address: "127.0.0.1:443"
auth_token: "ancymon-secret-psk-change-me"
tls_ca_path: "deploy/root.crt"
insecure: false
sampling_interval_ms: 1000
buffer_dir: "./buffer/"
buffer_max_mb: 50
```

Start the agent in foreground mode:

```bash
./agent/bin/ancymon-agent run -config agent/config.local.yaml
```

*Agent console output:*
```text
Starting ancymon-agent with config at agent/config.local.yaml
[WAL] Initialized Write-Ahead Log in ./buffer (segment: 1048576 bytes, max: 52428800 bytes)
[Collector] Initialized hardware collectors for machine_id: 8c35d9a1-0f2c-497b-891d-e59341ba8df0
[Dispatcher] Connected to gRPC upstream at 127.0.0.1:443 with TLS
[Dispatcher] Telemetry streaming active at 1000ms interval
```

Verify that `ancymon-server` logs show the inbound gRPC stream from the new machine and that metrics are batched to VictoriaMetrics:
```text
[gRPC] StreamTelemetry connection established from dev-workstation (uuid: 8c35d9a1-...)
[Watchdog] Machine 8c35d9a1-... (dev-workstation) registered as ONLINE
[Writer] Flushed 100 metrics to VictoriaMetrics TSDB (HTTP 204)
```

#### Step 7: Clean Teardown
To cleanly stop the local test environment and purge persistent test volumes:

```bash
docker compose -f deploy/docker-compose.yml down -v
rm -f deploy/root.crt
```

---

## Section 2: Production Environment (Proxmox VE LXC Debian Container)

In production, the AncyMon server stack runs inside a dedicated, unprivileged Debian 12 (Bookworm) LXC container on Proxmox VE. All three core services (`victoriametrics`, `caddy`, and `ancymon-server`) run as native systemd units without Docker nesting overhead.

### 2.1. System Requirements & Host Sizing

| Resource | Minimum | Recommended | Notes |
|---|---|---|---|
| **CPU** | 1 vCPU (x86_64) | 2 vCPUs | Intel 8th Gen+ / AMD Zen 2+ with AES-NI. |
| **RAM** | 512 MB | 1024 MB | Combined runtime footprint is ~100–120 MB. |
| **Swap** | 512 MB | 1024 MB | For absorption of temporary memory spikes. |
| **Storage** | 10 GB | 20 GB (SSD/NVMe)| Single-node VictoriaMetrics 90d retention. |
| **Network** | 1x VirtIO vNIC | Static LAN IP | e.g. `192.168.1.50/24` on bridge `vmbr0`. |

### 2.2. LXC Container Creation on Proxmox VE

You can provision the container via the Proxmox Web GUI or via the PVE host shell using `pct`:

```bash
# Execute on the Proxmox VE host shell
pct create 105 local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst \
  --ostype debian \
  --hostname ancymon-server \
  --cores 2 \
  --memory 1024 \
  --swap 512 \
  --rootfs local-lvm:20 \
  --net0 name=eth0,bridge=vmbr0,ip=192.168.1.50/24,gw=192.168.1.1 \
  --unprivileged 1 \
  --features nesting=1 \
  --start 1
```

Enter the container console:

```bash
pct enter 105
```

Inside the LXC container, update packages and install essential dependencies:

```bash
apt update && apt upgrade -y
apt install -y curl tar wget git build-essential ca-certificates openssl
```

---

### 2.3. VictoriaMetrics Installation & Setup

VictoriaMetrics is deployed as a single-node static binary running as an unprivileged system daemon.

#### 1. Download and Install Binary
```bash
VM_VERSION="v1.99.0"
wget https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/${VM_VERSION}/victoria-metrics-linux-amd64-${VM_VERSION}.tar.gz
tar -xzf victoria-metrics-linux-amd64-${VM_VERSION}.tar.gz -C /usr/local/bin/
rm -f victoria-metrics-linux-amd64-${VM_VERSION}.tar.gz
chmod +x /usr/local/bin/victoria-metrics-prod
ln -sf /usr/local/bin/victoria-metrics-prod /usr/local/bin/victoria-metrics
```

#### 2. Create Service User and Storage Directory
```bash
useradd --system --no-create-home --shell /bin/false victoriametrics
mkdir -p /var/lib/victoria-metrics-data
chown -R victoriametrics:victoriametrics /var/lib/victoria-metrics-data
chmod 750 /var/lib/victoria-metrics-data
```

#### 3. Create Systemd Unit (`/etc/systemd/system/victoriametrics.service`)
Write the production unit file:

```ini
[Unit]
Description=VictoriaMetrics Time-Series Database
Documentation=https://docs.victoriametrics.com/
After=network.target

[Service]
Type=simple
User=victoriametrics
Group=victoriametrics
ExecStart=/usr/local/bin/victoria-metrics \
  -storageDataPath=/var/lib/victoria-metrics-data \
  -retentionPeriod=90d \
  -httpListenAddr=127.0.0.1:8428
Restart=always
RestartSec=5s
LimitNOFILE=65536
KillMode=mixed
TimeoutStopSec=30s

[Install]
WantedBy=multi-user.target
```

Enable and start VictoriaMetrics:

```bash
systemctl daemon-reload
systemctl enable --now victoriametrics.service
systemctl status victoriametrics.service
```

Verify local health:

```bash
curl -fsS http://127.0.0.1:8428/health
# Output: OK
```

---

### 2.4. Caddy Reverse Proxy & Internal ECDSA CA Setup

Caddy provides TLS termination on LAN port 443 and acts as the internal automated Certificate Authority using the compact ECDSA P-256 curve (`secp256r1`).

#### 1. Install Caddy from Official Debian Repository
```bash
apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
apt update
apt install -y caddy
```

#### 2. Configure `/etc/caddy/Caddyfile`
Replace `/etc/caddy/Caddyfile` with the AncyMon production configuration:

```caddy
# /etc/caddy/Caddyfile - AncyMon Reverse Proxy & Internal ECDSA CA
{
	# Enable internal automated Certificate Authority
	local_certs
}

# Production Ingress listening on LAN TLS port 443
:443 {
	tls internal {
		on_demand
		# Enforce elliptic curve ECDSA P-256 (secp256r1) for minimal certificate size
		curves secp256r1
	}

	# Direct gRPC HTTP/2 client streaming to ancymon-server (cleartext h2c)
	@grpc protocol grpc
	handle @grpc {
		reverse_proxy h2c://127.0.0.1:50051
	}

	# Direct GraphQL HTTPS queries and WebSocket subscriptions to ancymon-server
	handle /graphql* {
		reverse_proxy 127.0.0.1:8080
	}

	# Default health and diagnostic gateway probe
	respond "AncyMon Telemetry Gateway Online" 200
}
```

Validate and restart Caddy:

```bash
caddy validate --config /etc/caddy/Caddyfile
systemctl enable --now caddy.service
systemctl restart caddy.service
```

#### 3. Locate the Internal Root CA
When Caddy starts with `local_certs`, it automatically generates the internal Root CA at:
`/var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt`

Verify the Root CA exists and uses ECDSA P-256:

```bash
openssl x509 -in /var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt -text -noout | grep -E "(Public Key Algorithm|ASN1 OID)"
```

Make a standardized copy accessible to `ancymon-server`:

```bash
mkdir -p /etc/ancymon
cp /var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt /etc/ancymon/root.crt
chmod 644 /etc/ancymon/root.crt
```

---

### 2.5. `ancymon-server` Build & Deployment

#### 1. Compile Static Binaries
On your development workstation (or directly inside the LXC container if Go 1.22+ is installed), compile statically linked binaries:

```bash
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -ldflags="-s -w" -o ancymon-server ./server/cmd/ancymon-server
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -ldflags="-s -w" -o ancymon-qr ./server/cmd/ancymon-qr
```

Copy the binaries into the LXC container:

```bash
install -m 755 ancymon-server /usr/local/bin/ancymon-server
install -m 755 ancymon-qr /usr/local/bin/ancymon-qr
```

#### 2. Create Service User & Configuration
```bash
useradd --system --no-create-home --shell /bin/false ancymon
mkdir -p /etc/ancymon
```

Create `/etc/ancymon/server.yaml`:

```yaml
# /etc/ancymon/server.yaml - Production Server Configuration
server:
  # Internal cleartext gRPC port proxied by Caddy (h2c)
  grpc_port: 50051

  # Internal HTTP/WebSocket GraphQL port proxied by Caddy
  graphql_port: 8080

  # Pre-Shared Key (PSK) secret token required for gRPC ingestion and GraphQL access
  # Generate a cryptographically strong token: openssl rand -hex 24
  auth_token: "d41d8cd98f00b204e9800998ecf8427e9a4f61b2c83d5a10"

  # Public IP / Hostname of the LXC container presented in the QR pairing payload
  public_ip: "192.168.1.50"

  # Public TLS ingress port terminated by Caddy reverse proxy
  public_port: 443

  # Path to Caddy's internal ECDSA root CA certificate
  ca_cert_path: "/etc/ancymon/root.crt"

victoriametrics:
  # VictoriaMetrics HTTP base URL
  url: "http://127.0.0.1:8428"

  # Number of telemetry frames to buffer before flushing to /write
  batch_size: 100

  # Maximum duration in milliseconds before flushing pending telemetry frames
  flush_interval_ms: 500

watchdog:
  # Interval in seconds between heartbeat evaluations
  check_interval_sec: 5

  # Silence duration in seconds after which an online machine is marked offline
  offline_timeout_sec: 60
```

Secure configuration permissions:

```bash
chown -R ancymon:ancymon /etc/ancymon
chmod 600 /etc/ancymon/server.yaml
chmod 644 /etc/ancymon/root.crt
```

#### 3. Create Systemd Unit (`/etc/systemd/system/ancymon-server.service`)

Write the production unit file:

```ini
[Unit]
Description=AncyMon Telemetry Ingestion and GraphQL Engine
Documentation=https://github.com/your-org/ancymon
After=network.target victoriametrics.service caddy.service
Requires=victoriametrics.service
Wants=caddy.service

[Service]
Type=simple
User=ancymon
Group=ancymon
ExecStart=/usr/local/bin/ancymon-server -config /etc/ancymon/server.yaml
Restart=always
RestartSec=5s
LimitNOFILE=65536
KillMode=mixed
TimeoutStopSec=15s

[Install]
WantedBy=multi-user.target
```

Enable and start the service:

```bash
systemctl daemon-reload
systemctl enable --now ancymon-server.service
systemctl status ancymon-server.service
```

---

## Section 3: Workstation Host Agent Production Deployment (`ancymon-agent`)

The `ancymon-agent` is deployed across your LAN workstations (desktops, laptops, micro-servers). It runs silently as a native OS service, consumes ~10–15 MB RAM, and maintains a 50 MB segmented WAL buffer on disk for offline network resilience.

### 3.1. Linux Workstation Deployment

#### Step 1: Install Binary and Root Certificate
On each monitored Linux workstation:

```bash
# Copy binary from build workstation
install -m 755 ancymon-agent /usr/local/bin/ancymon-agent

# Create configuration and buffer directories
mkdir -p /etc/ancymon
mkdir -p /var/lib/ancymon-agent/buffer

# Secure copy Caddy's root CA from LXC container
scp root@192.168.1.50:/etc/ancymon/root.crt /etc/ancymon/root.crt
chmod 644 /etc/ancymon/root.crt
```

#### Step 2: Configure `/etc/ancymon/agent.yaml`
```yaml
# /etc/ancymon/agent.yaml
# Leave machine_id empty on first start to auto-generate persistent UUID v4
machine_id: ""

# Target LXC container Caddy ingress
server_address: "192.168.1.50:443"

# Must match server.yaml auth_token
auth_token: "d41d8cd98f00b204e9800998ecf8427e9a4f61b2c83d5a10"

# Path to trusted Caddy ECDSA root certificate
tls_ca_path: "/etc/ancymon/root.crt"

# Transport encryption mode (never true in production)
insecure: false

# 1 Hz sampling frequency
sampling_interval_ms: 1000

# Offline segmented WAL directory
buffer_dir: "/var/lib/ancymon-agent/buffer"

# 50 MB ceiling for offline buffering (~50 segments of 1 MB)
buffer_max_mb: 50
```

#### Step 3: Register and Start via Built-in Service Commands
The `ancymon-agent` includes native OS service registration commands powered by `kardianos/service`:

```bash
# Install as systemd service
ancymon-agent install -config /etc/ancymon/agent.yaml

# Start the service
ancymon-agent start

# Verify running state
ancymon-agent status
# Output: ancymon-agent service is running.

# Follow live systemd logs
journalctl -u ancymon-agent -f
```

---

### 3.2. Windows Workstation Deployment

#### Step 1: Prepare Directory Structure
On the target Windows workstation, open an **Administrator PowerShell** session:

```powershell
New-Item -ItemType Directory -Path "C:\Program Files\AncyMon" -Force
New-Item -ItemType Directory -Path "C:\Program Files\AncyMon\buffer" -Force
```

Copy `ancymon-agent.exe` and `root.crt` into `C:\Program Files\AncyMon\`.

#### Step 2: Configure `C:\Program Files\AncyMon\config.yaml`
Create `C:\Program Files\AncyMon\config.yaml`:

```yaml
# C:\Program Files\AncyMon\config.yaml
machine_id: ""
server_address: "192.168.1.50:443"
auth_token: "d41d8cd98f00b204e9800998ecf8427e9a4f61b2c83d5a10"
tls_ca_path: "C:\\Program Files\\AncyMon\\root.crt"
insecure: false
sampling_interval_ms: 1000
buffer_dir: "C:\\Program Files\\AncyMon\\buffer"
buffer_max_mb: 50
```

#### Step 3: Install as Windows Service
In Administrator PowerShell:

```powershell
cd "C:\Program Files\AncyMon"

# Register native Windows Service
.\ancymon-agent.exe install -config "C:\Program Files\AncyMon\config.yaml"

# Start the service
.\ancymon-agent.exe start

# Verify service state
Get-Service ancymon-agent
```

*Expected output:*
```text
Status   Name               DisplayName
------   ----               -----------
Running  ancymon-agent      AncyMon Host Telemetry Agent
```

To view diagnostic logs, open Windows **Event Viewer** (`eventvwr.msc`) -> **Windows Logs** -> **Application** -> Source: `ancymon-agent`.

---

### 3.3. Offline WAL Buffer Resilience & Verification

The offline WAL architecture ensures zero data loss during network partitions, server reboots, or WiFi drops:

1. **Segment Rotation:** Telemetry frames are packed into fixed 1 MB binary chunks (`segment_000001.wal`).
2. **Ceiling & FIFO Eviction:** The buffer directory enforces a maximum bound (default `50 MB`). If the host remains disconnected for days and reaches 50 MB, the oldest segment is safely pruned to prevent unbounded disk growth.
3. **Flat RAM Footprint:** Agent memory usage stays flat at ~10–15 MB even during multi-hour disconnections.
4. **Chronological Replay:** When the connection to port 443 restores, new telemetry continues appending to the tail of the WAL, while a background drainer streams historical segments sequentially in strict timestamp order.

**Verifying WAL Replay:**
```bash
# 1. Simulate network failure on agent host:
iptables -A OUTPUT -p tcp --dport 443 -j DROP

# 2. Watch agent buffer populate:
ls -lh /var/lib/ancymon-agent/buffer/

# 3. Restore connectivity:
iptables -D OUTPUT -p tcp --dport 443 -j DROP

# 4. Observe agent logs draining segments:
journalctl -u ancymon-agent -f
# Notice segments being drained and removed one by one until live streaming resumes!
```

---

## Section 4: Mobile Client Pairing & Operations

AncyMon features a zero-typing onboarding UX. Monitored mobile clients establish secure TLS communication without installing self-signed certificates into the Android or iOS operating system trust stores.

### 4.1. Generating the Pairing QR Code
On the server (inside the LXC container or development terminal), run `ancymon-qr`:

```bash
ancymon-qr -config /etc/ancymon/server.yaml
```

*Example Terminal Rendering:*

```text
=======================================================
             AncyMon Mobile Pairing QR Code            
=======================================================
▄▄▄▄▄▄▄ ▄ ▄  ▄▄ ▄▄ ▄▄▄▄▄▄▄
█ ▄▄▄ █ █ ▄▀█▄█▀▄█ █ ▄▄▄ █
█ ███ █ ▄▀██▄▄█ ▀▄ █ ███ █
█▄▄▄▄▄█ █ █ █ █ █▀ █▄▄▄▄▄█
█ ▄ ▄▄▄▄▀█▄▀ ▀▄█▄▄   ▄▄▄ ▄
█▄█ █▄█ ▀ ▀▄█▀▄ ▀█▀█▀▄ ▄██
███▄▄ █▄▄ ▄▄ █▄█ ▄▀█ █ █▄█
█▄▄█▄▄█▄█▀▀█▄▀ ▄ ▄ ▄ ▄▄▀██
▄▄▄▄▄▄▄ █ ▄ ▀▀▄▀▀█ █ ▄ █▄▀
█ ▄▄▄ █ ▄█▄▄▄ ▀█ ▄ █▄▄▄█▀█
█ ███ █ █▀█ █▄██▄▀ ▄▄ ▀▀▀█
█▄▄▄▄▄█ █ ▄▀▄  ▀█▄█ █ █▄▄█
-------------------------------------------------------
Server Host: 192.168.1.50:443
PSK Token:   d41d8cd98f00b204e9800998ecf8427e9a4f61b2c83d5a10
Payload JSON:
{"ip":"192.168.1.50","port":443,"token":"d41d8cd98f00b204e9800998ecf8427e9a4f61b2c83d5a10","ca":"MIIBbjCCARWgAwIBAgIRAM..."}
=======================================================
```

### 4.2. Mobile Onboarding & Dynamic Trust Flow
1. **Camera Scanning:** The Flutter mobile app opens the camera via `mobile_scanner` and scans the QR code.
2. **Payload Parsing:** The app decodes the JSON payload matching `graphql/pairing.schema.json`.
3. **Secure Persistence:** The target IP, port, and Bearer token are securely saved into hardware-backed keystore (`flutter_secure_storage`).
4. **Dynamic `SecurityContext` Injection:** The raw Base64 DER bytes of Caddy's ECDSA Root CA are decoded in Dart and injected into a custom `SecurityContext`:
   ```dart
   final SecurityContext clientContext = SecurityContext(withTrustedRoots: false);
   clientContext.setTrustedCertificatesBytes(base64Decode(pairingData.ca));
   ```
5. **Ferry Client Initialization:** The Ferry GraphQL HTTP client and WebSocket link attach the custom `SecurityContext`. All HTTPS requests and WebSocket streams immediately authenticate and validate the server TLS certificate without any system warnings or manual profile installations.

---

## Section 5: Maintenance, Monitoring & Troubleshooting

### 5.1. Service Inspection & Log Streaming

Inspect real-time logs across all production services using `journalctl`:

```bash
# Central backend logs
journalctl -u ancymon-server -f

# VictoriaMetrics storage engine logs
journalctl -u victoriametrics -f

# Caddy reverse proxy logs
journalctl -u caddy -f

# Combined multi-service stream
journalctl -u caddy -u ancymon-server -u victoriametrics -f
```

### 5.2. Health Check & Diagnostic Endpoints

| Component | Target URL | Expected Response | Description |
|---|---|---|---|
| **VictoriaMetrics** | `http://127.0.0.1:8428/health` | `OK` (HTTP 200) | TSDB process health. |
| **VictoriaMetrics Metrics** | `http://127.0.0.1:8428/metrics` | Prometheus metrics | Ingestion counters and disk stats. |
| **Caddy Ingress** | `https://192.168.1.50:443/` | `AncyMon Telemetry Gateway Online` | TLS handshake & reverse proxy listener. |
| **ancymon-server** | `http://127.0.0.1:8080/health` | `OK` (HTTP 200) | Internal server listener health. |
| **GraphQL Schema** | `https://192.168.1.50/graphql` | HTTP 200 (POST) | GraphQL query execution endpoint. |

**Command Line Smoke Tests:**

```bash
# 1. Test VictoriaMetrics Health
curl -fsS http://127.0.0.1:8428/health

# 2. Test Ingress Gateway over TLS (using internal CA)
curl --cacert /etc/ancymon/root.crt https://192.168.1.50/

# 3. Test GraphQL Fleet Query
curl -X POST https://192.168.1.50/graphql \
  --cacert /etc/ancymon/root.crt \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer d41d8cd98f00b204e9800998ecf8427e9a4f61b2c83d5a10" \
  -d '{"query": "query { fleetSummary { machineId hostname status cpuUsagePercent } }"}'
```

### 5.3. Backup & Disaster Recovery Procedures

To ensure painless disaster recovery, back up both the time-series storage and Caddy's PKI authority keys.

#### 1. VictoriaMetrics Instantaneous Snapshot Backup
VictoriaMetrics provides atomic, point-in-time snapshots without downtime:

```bash
# Create an atomic snapshot
SNAPSHOT_PATH=$(curl -fsS "http://127.0.0.1:8428/snapshot/create" | grep -o '/var/lib/victoria-metrics-data/snapshots/[^"]*')
echo "Created snapshot at: ${SNAPSHOT_PATH}"

# Archive snapshot to backup location
tar -czf /var/backups/vm-snapshot-$(date +%F).tar.gz -C "${SNAPSHOT_PATH}" .

# Delete the snapshot marker
curl -fsS "http://127.0.0.1:8428/snapshot/delete?snapshot=${SNAPSHOT_PATH##*/}"
```

#### 2. Caddy Internal CA Backup
> [!IMPORTANT]
> Always back up Caddy's Root CA keys (`root.crt` and `root.key`). If you rebuild the container without preserving these keys, mobile clients and agents will reject the new TLS certificates and will require re-pairing.

```bash
tar -czf /var/backups/caddy-pki-$(date +%F).tar.gz \
  -C /var/lib/caddy/.local/share/caddy/pki/authorities/local root.crt root.key
```

#### 3. Restoration Procedure
To restore on a clean LXC container:
1. Extract Caddy PKI backup to `/var/lib/caddy/.local/share/caddy/pki/authorities/local/`.
2. Extract VictoriaMetrics data to `/var/lib/victoria-metrics-data/`.
3. Correct ownership (`chown -R caddy:caddy ...`, `chown -R victoriametrics:victoriametrics ...`).
4. Start services (`systemctl start victoriametrics caddy ancymon-server`).

### 5.4. Common Troubleshooting Scenarios

#### Scenario 1: Agent reports `rpc error: code = Unauthenticated`
* **Cause:** The `auth_token` in `agent.yaml` does not match the `server.yaml` Pre-Shared Key.
* **Resolution:** Synchronize the `auth_token` string between `/etc/ancymon/server.yaml` and `/etc/ancymon/agent.yaml`, then restart the agent (`ancymon-agent restart`).

#### Scenario 2: Agent reports `x509: certificate signed by unknown authority`
* **Cause:** The agent is unable to verify Caddy's self-issued TLS certificate.
* **Resolution:** Ensure `tls_ca_path` in `agent.yaml` points to a valid copy of Caddy's `root.crt`. Verify that the certificate has not been regenerated following a Caddy data purge.

#### Scenario 3: Port 443 Already in Use on Host
* **Cause:** Another web server (e.g. Apache, Nginx, or an existing reverse proxy) is bound to port 443.
* **Resolution:** Inside a dedicated LXC container with its own IP (`192.168.1.50`), port 443 is exclusively dedicated to Caddy. If testing locally on Docker with host networking, ensure local web servers are stopped (`sudo systemctl stop nginx apache2`).

#### Scenario 4: Workstation Shows as `OFFLINE` in Mobile App
* **Cause:** No telemetry frame was received by `ancymon-server` within the watchdog window (default 60 seconds).
* **Resolution:**
  1. Check if the workstation is powered off or sleeping.
  2. Inspect the agent status: `ancymon-agent status` or `Get-Service ancymon-agent`.
  3. Verify network routing to `https://192.168.1.50:443`.
  4. Inspect the agent buffer directory to see if frames are accumulating offline.
