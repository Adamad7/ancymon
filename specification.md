# ANCYMON - HOME NETWORK RESOURCE MONITORING SYSTEM
## ARCHITECTURAL DESIGN AND TECHNICAL SPECIFICATION (PRD / SYSTEM SPECIFICATION)

---

## 1. INTRODUCTION AND SYSTEM OBJECTIVES

### 1.1. Project Purpose
The project involves designing and building a cross-platform, distributed telemetry system named **AncyMon** for monitoring the hardware load of machines (desktops, laptops, home servers) operating within a local area network (LAN). AncyMon collects hardware metrics at a 1 Hz sampling frequency, aggregates them in a centralized time-series repository, processes them in real time, and presents them via a modern mobile interface.

### 1.2. Core Engineering Principles
* **Efficiency and Low Overhead:** Monitoring agents (`ancymon-agent`) must operate silently in the background with negligible CPU and RAM utilization, while network payloads must remain minimal in size.
* **Zero External Dependencies on Clients:** Host agents must not require any external runtime environments, interpreters, or dynamic system libraries to be installed on target machines.
* **Fault Tolerance and Network Resilience:** Network dropouts or server reboots must not lead to data loss or excessive RAM growth on host machines.
* **LAN Security:** Full end-to-end transport encryption (TLS) paired with pre-shared key (PSK/Token) access control.
* **Zero-Typing Onboarding UX:** Mobile client configuration and certificate trust distribution are handled entirely through a one-time scan of a server-generated QR code.

---

## 2. HIGH-LEVEL ARCHITECTURE

The AncyMon system is built upon a distributed three-tier architecture:

```
[ Host Agents: ancymon-agent (Windows / Linux) ]
             │
             │  gRPC over HTTP/2 (Client Streaming)
             │  Port 443 (TLS Encrypted)
             ▼
┌────────────────────────────────────────────────────────┐
│ LXC SERVER CONTAINER (Debian on Proxmox VE)            │
│                                                        │
│  [ Caddy Reverse Proxy ]                               │
│       │ (TLS Termination, Internal ECDSA CA, Port 443) │
│       ├──► h2c (cleartext) Port 50051 ──► [ancymon-    │
│       └──► http (cleartext) Port 8080  ──►  server]    │
│                                                 │      │
│  [ VictoriaMetrics (Time-Series Database) ] ◄───┘      │
│       (Influx Line Protocol writes, MetricsQL,         │
│        automatic dynamic rollup & retention)           │
└────────────────────────────────────────────────────────┘
             ▲
             │  GraphQL (Queries over HTTPS / Subscriptions over WSS)
             │  Port 443 (TLS Encrypted)
             │
[ Mobile Application: AncyMon Client (Flutter + Ferry) ]
```

---

## 3. HOST AGENT TIER (`ancymon-agent`)

### 3.1. Runtime Environment and Deployment Model
* **Implementation Language:** Go (Golang).
* **Binary Distribution:** Statically linked, single executable binary (one `ancymon-agent.exe` for Windows, one `ancymon-agent` ELF executable for Linux). No runtime dependencies, interpreters, or external shared libraries required.
* **OS Service Integration:**
  * **Linux:** Native `systemd` daemon unit (`ancymon-agent.service`) with automatic failure restarts.
  * **Windows:** Native `Windows Service` managed directly by the Service Control Manager.
  * Runs headless in the background, operating regardless of whether a user is logged into the graphical desktop.

### 3.2. Metrics and Sampling Frequency
* **Sampling Rate:** Fixed 1-second interval (1 Hz).
* **Monitored Hardware Subsystems:**
  * **CPU:** Total aggregate percentage utilization across all logical cores.
  * **CPU Temperature:** Package/core temperature in degrees Celsius (°C). If the platform or virtualization layer does not expose thermal sensors (e.g., VMs without thermal passthrough), this field emits `null`/optional and is gracefully handled without errors.
  * **RAM:** Total physical memory, currently used memory, and overall utilization percentage.
  * **Network I/O Rate:** Current aggregate network throughput measured in bytes per second (Download: `rx_bytes/sec`, Upload: `tx_bytes/sec`). Calculated by the agent by computing the delta between cumulative interface counters across consecutive 1-second ticks.
  * **Storage (Disks):** Dynamic discovery of mounted logical volumes/partitions, reporting mount points, filesystem types, total capacities, free space, and percentage utilization.
  * **Filesystem Whitelist Filter:** To prevent virtual and pseudo-filesystems (e.g., `tmpfs`, `devtmpfs`, `squashfs`, `overlay`, `/proc`, `/sys`) from polluting telemetry, the agent strictly filters volumes against a filesystem whitelist: `ext4`, `xfs`, `btrfs`, `zfs`, `ntfs`, `vfat`, `fat32`, `apfs`. All other types are ignored.
  * *Current Exclusions:* GPU telemetry collection is deferred to future iterations; reserve tags are maintained in the binary contract to ensure backward compatibility.

### 3.3. Agent Configuration and Identification
* **Configuration Medium:** A YAML file (`config.yaml`) placed in the same working directory as the executable.
* **Machine Identity (`machine_id` & `hostname`):**
  * `machine_id`: A globally unique, persistent UUID v4 string. On first run, if `machine_id` is missing in `config.yaml`, the agent generates a persistent UUID v4 and persists it to `config.yaml`. This guarantees identity stability across hostname changes or duplications.
  * `hostname`: Dynamic system hostname resolved via OS APIs, transmitted alongside telemetry payloads strictly as a human-readable display label.
* **Configuration Parameters:**
  * `machine_id` (UUID v4 string).
  * Server network address and port.
  * Authorization secret token (Pre-Shared Key).
  * Path to the local trusted root CA certificate.
  * Sampling interval in milliseconds (default: 1000).
  * Storage path for the offline disk buffer WAL directory (default: `./buffer/`).
  * Maximum disk buffer size limit in megabytes (default: 50 MB).

### 3.4. Offline Buffer (Segmented WAL Architecture)
* **Write Mechanism & Topology:**
  * Offline persistence is implemented via a **Segmented Write-Ahead Log (WAL)** located inside a dedicated subfolder (`./buffer/`) within the agent's working directory.
  * Telemetry frames are appended to rotating fixed-size segment files of **1 MB** each (e.g., `segment_000001.wal`).
* **Resource Bounds and FIFO Eviction:**
  * Memory footprint remains flat (~10–15 MB) under all network partition scenarios.
  * The WAL folder operates under a configurable ceiling (e.g., 50 MB = up to 50 active segment files). If disk usage hits the threshold, the oldest completed segment file is deleted (FIFO / ring eviction).
* **Buffer Draining & Ordering Guarantee:**
  * If a connection drop occurs, live incoming measurements are diverted directly to the active WAL segment file.
  * When the connection to `ancymon-server` is restored, **all new incoming 1s measurements continue to be queued at the tail of the WAL** until the entire backlog is drained.
  * A background worker drains segments sequentially in strict chronological order. Once a 1 MB segment is fully transmitted and acknowledged, it is deleted from the filesystem. Live direct streaming resumes seamlessly only when zero backlog files remain.

---

## 4. TRANSPORT AND SECURITY TIER

### 4.1. Agent-to-Server Transport (gRPC & Keepalive Specification)
* **Protocol:** gRPC running over an HTTP/2 transport channel.
* **Transmission Pattern:** Client Streaming. `ancymon-agent` establishes a persistent connection and continuously pushes binary Protocol Buffers (`.proto`) messages.
* **gRPC Keepalive Configuration (Mandatory):**
  * To guarantee that long-lived HTTP/2 streams do not get silently dropped by intermediate stateful firewalls, routers, or reverse proxy idle timeouts (Caddy), active keepalive probing is strictly enforced.
  * **Client Configuration (`ancymon-agent`):**
    * `grpc.keepalive_time_ms = 30000` (Sends a ping frame every 30 seconds of inactivity).
    * `grpc.keepalive_timeout_ms = 10000` (Waits 10 seconds for ping acknowledgment before considering the connection broken).
    * `grpc.keepalive_permit_without_stream = true` (Permits sending keepalive pings even when no active RPC call is in flight).
  * **Server Configuration (`ancymon-server`):**
    * `keepalive.EnforcementPolicy.MinTime = 15s` (Allows clients to ping as frequently as every 15 seconds without being flagged for ping flooding).
    * `keepalive.EnforcementPolicy.PermitWithoutStream = true` (Accepts pings when idle).
    * `keepalive.ServerParameters.Time = 60s` (Server-initiated pings).
    * `keepalive.ServerParameters.Timeout = 20s`.
* **Data Contract:** Strictly typed schema defined in `telemetry.proto`.

### 4.2. Transport Layer Security (One-Way TLS & Elliptic Curves)
* **Ingress Port:** Standard port 443 (all traffic entering the container must be TLS-encrypted).
* **Internal Certificate Authority (Caddy):** Caddy operates as an internal CA (`tls internal`) using **ECDSA (P-256 curve)** for key generation instead of bulky RSA keys, keeping certificate sizes minimal.
* **Reverse Proxy Architecture:**
  * Inbound connections terminate TLS at Caddy.
  * Caddy routes decrypted traffic within `localhost`: gRPC streams flow via cleartext HTTP/2 (`h2c`) to port 50051 (`ancymon-server`), while GraphQL HTTP and WebSocket traffic route to port 8080 (`ancymon-server`).
* **Certificate Trust:** Client runtimes (`ancymon-agent` and mobile app) validate server identity against the Caddy internal ECDSA Root CA.

### 4.3. Authentication and Access Control
* **Security Model:** Pre-Shared Secret Token (PSK).
* **gRPC Interception:** `ancymon-agent` attaches the bearer token to HTTP/2 stream metadata (`Authorization: Bearer <TOKEN>`). A server-side interceptor rejects unauthorized streams with `codes.Unauthenticated`.
* **GraphQL Authorization:** The mobile client attaches the token in the HTTP `Authorization` header and within `connectionParams` during WebSocket initialization.

---

## 5. SERVER TIER AND DATA STORAGE (`ancymon-server`)

### 5.1. Hardware Infrastructure and Virtualization
* **Host Platform:** Bare-metal home server running an Intel 13th Gen processor (x86_64, AES-NI).
* **Hypervisor:** Proxmox VE.
* **Production Runtime Target:** Single unprivileged LXC container (Debian). Caddy, VictoriaMetrics, and `ancymon-server` run as managed `systemd` units.
* **Development Environment:** Docker Compose on development workstation.

### 5.2. Central Server Backend (`ancymon-server`)
* **Implementation Language:** Go (Golang).
* **Core Responsibilities:**
  * Concurrent ingestion of streaming gRPC telemetry from multiple agents.
  * Authentication, validation, and asynchronous batched writes to VictoriaMetrics.
  * In-memory cache tracking real-time status and metadata of all registered UUIDs.
  * Heartbeat Watchdog: marks a host as `offline` if no telemetry arrives for > 60 seconds.
  * GraphQL engine provisioning (Queries, Subscriptions, Mutations).
  * Terminal QR-code generator utility.

### 5.3. Time-Series Storage (VictoriaMetrics)
* **Database Engine:** Single-node VictoriaMetrics binary execution.
  * Extremely low memory footprint (~30–50 MB RAM in LXC).
  * Native support for Influx Line Protocol on the `/write` endpoint for ingestion.
  * Native MetricsQL engine for historical metric queries over HTTP.
* **Retention Strategy:**
  * Configured via single flag (e.g., `-retentionPeriod=90d`).
* **Dynamic Rollup & Downsampling:**
  * VictoriaMetrics handles downsampling dynamically in-flight during query execution.
  * Historical queries utilize MetricsQL range queries (`/api/v1/query_range`) with an auto-calculated `step` parameter, eliminating the need for rigid background aggregation tasks or manual downsampled tables.

---

## 6. APPLICATION PROGRAMMING INTERFACE (GRAPHQL API)

### 6.1. Real-Time Operations (GraphQL Subscriptions over WebSockets)
* **Fleet Summary Subscription (`FleetSummary`):**
  * Emits core status: `machine_id` (UUID), `hostname`, connection state (`online`/`offline`), overall CPU percentage, CPU temperature, and live download/upload network speeds.
  * Serves the main dashboard list view with minimal network overhead.
* **Machine Metrics Subscription (`MachineMetrics`):**
  * Activated exclusively when navigating into a specific machine's detailed view.
  * Streams full telemetry (detailed CPU, CPU temp, RAM, real-time download/upload speeds, and filtered disk partitions).

### 6.2. Analytical Operations (GraphQL Queries over HTTPS POST)
* On-demand historical queries for collapsible graph panels:
  * Supported Ranges: Last 1 Hour (1h), 6 Hours (6h), 12 Hours (12h), 24 Hours (24h), 3 Days (3d), 7 Days (7d), and Custom Single-Day Picker.
  * Metrics supported for historical graphing: CPU utilization %, CPU temperature (°C), RAM utilization %, Network I/O throughput (KB/s or MB/s), and Disk utilization %.
  * Resolution is dynamically bucketed based on the requested range (mapped to VictoriaMetrics `step`), ensuring smooth continuous line charts without single-point collapses on multi-day views (~100–300 points per chart).

### 6.3. Fleet Management Operations (GraphQL Mutations)
* **Delete Machine Mutation (`deleteMachine(machineId: ID!)`):**
  * Allows the mobile client to explicitly unregister and prune an inactive/decommissioned host from the in-memory cache and fleet registry.

---

## 7. MOBILE APPLICATION (AncyMon Client)

### 7.1. Technology Stack
* **Framework:** Flutter (Android & iOS).
* **State Management:** Riverpod (binds asynchronous streams and repository states directly to presentation widgets).
* **GraphQL Client:** **Ferry** (`ferry`, `ferry_flutter`, `gql_http_link`, `gql_websocket_link`).
  * Enforces full compile-time Type-Safety and code generation via `build_runner`.
  * Generates immutable Dart models from `.graphql` files for all queries, mutations, and subscriptions.
  * Exposes reactive streams (`Stream<OperationResponse<...>>`) that integrate directly into Riverpod's `StreamProvider`.
* **Visualization Engine:** `fl_chart` (hardware-accelerated canvas rendering).
* **Camera Integration:** `mobile_scanner` (for reading pairing QR codes).
* **Key Storage:** `flutter_secure_storage` (encrypted persistence via Android Keystore / iOS Keychain).

### 7.2. User Interface and Experience (UI/UX)
* **Pairing Screen:** First-launch camera scanner reading the terminal QR code.
* **Main Dashboard:**
  * List view of all registered machines showing `hostname`, UUID subtitle, status badge (`online`/`offline`), live CPU load, CPU temperature badge, and live network I/O activity chips.
  * **Pruning Inactive Machines:** For machines marked as `offline`, a contextual option / swipe-action allows the user to delete/forget the machine via the `deleteMachine` mutation.
* **Machine Detail View:**
  * Modular cards for:
    * **CPU & Thermals:** Usage gauge/bar and package temperature reading.
    * **Memory (RAM):** Used vs. total capacity and percentage.
    * **Network I/O:** Current live upload and download throughput.
    * **Disk Partitions:** Capacity and percentage usage for whitelisted mounts.
  * Collapsible, lazy-loaded charts with interactive range chips (1h, 6h, 12h, 24h, 3d, 7d, calendar date) for each metric domain.

### 7.3. Zero-Typing Pairing Procedure & Minimal QR Footprint
1. **QR Size Optimization Strategy:**
   * Caddy uses an **ECDSA (P-256)** root certificate, reducing raw certificate size significantly compared to RSA.
   * The server extracts the raw DER/Base64 bytes of the CA (stripping `-----BEGIN CERTIFICATE-----` headers, footers, and linebreaks).
   * The pairing payload is serialized into a compact minified JSON:
     `{"ip":"192.168.1.50","port":443,"token":"<PSK>","ca":"<COMPACT_BASE64>"}`
   * This yields a payload of ~600–700 characters, rendering a clean, low-density QR code (Version 10–12) that easily fits standard terminal windows and scans instantly.
2. **Mobile Onboarding Flow:**
   * Mobile app scans the terminal QR code and parses the JSON.
   * Address and token are saved to `flutter_secure_storage`.
   * The CA certificate bytes are loaded into a runtime Dart `SecurityContext`.
   * The Ferry client initializes both HTTP Link and WebSocket Link with the custom `SecurityContext`.
   * Secure TLS connections establish immediately without system-level certificate installations.

---

## 8. ARCHITECTURAL DECISION MATRIX

| Subsystem / Module | Selected Technology / Pattern | Engineering Rationale |
|---|---|---|
| **Host Agent (`ancymon-agent`)** | Go (Golang) | Compiles to a single static binary; zero dependencies; tiny memory footprint. |
| **System Metrics Collector** | Go System Libraries (`gopsutil`) | Unified hardware inspection API for CPU, thermals, RAM, network I/O, and disks (with filesystem whitelist). |
| **Service Lifecycle Management** | `kardianos/service` | Standardized background autostart for both `systemd` and `Windows Service`. |
| **Agent-to-Server Transport** | gRPC (HTTP/2 Client Streaming) | Persistent single-socket connection; compact Protobuf binary serialization. |
| **Connection Liveness** | Strict gRPC Keepalive Ping Framing | Enforces 30s ping / 10s timeout policy to prevent silent disconnects behind Caddy or network firewalls. |
| **Offline Resilience** | Segmented Disk WAL (1 MB chunks, FIFO) | Predictable bounded disk storage (MB); zero OOM risks; safe chronological draining. |
| **Transport Layer Security** | Caddy (Internal ECDSA CA) | Automated local CA; compact P-256 keys optimize terminal QR code density. |
| **Authorization Model** | Pre-Shared Secret Token (PSK) | Robust LAN security model avoiding user accounts and session management overhead. |
| **Central Backend (`ancymon-server`)** | Go (Golang) | Native concurrency; coordinates gRPC, GraphQL, and VictoriaMetrics HTTP ingestion. |
| **Time-Series Storage** | VictoriaMetrics | Minimal resource footprint (~30–50 MB RAM); native Influx Line Protocol; on-the-fly MetricsQL rollups. |
| **Server Virtualization** | LXC Container (Debian on Proxmox) | Native execution via `systemd` without container-nesting overhead. |
| **Development Environment** | Docker Compose (Workstation) | Local reproducibility and sandboxed testing during development. |
| **Mobile API Architecture** | GraphQL (Queries + Subscriptions + Mutations) | Efficient payload splitting; real-time WebSockets; explicit machine pruning. |
| **Mobile Application Engine** | Flutter + Ferry (Riverpod + `fl_chart`) | 100% Type-Safe GraphQL client with code generation; reactive stream binding; hardware-accelerated charting. |
| **Client Onboarding** | Minified Dynamic QR Code (ECDSA CA) | Zero-typing setup; compact terminal rendering; dynamic TLS trust injection into Dart `SecurityContext`. |
