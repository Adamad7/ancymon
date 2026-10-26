---
name: ancymon-architecture
description: >-
  Architectural design, component breakdown, network contracts, ports, security specifications,
  and directory structure reference for the AncyMon telemetry monitoring project. Use when designing
  features, verifying architectural compliance, or onboarding subagents.
---

# AncyMon - System Architecture Reference

Ten dokument zawiera autorytatywne podsumowanie architektury technicznej, kontraktów i topologii sieciowej systemu **AncyMon**.

---

## 1. Topologia Trójwarstwowa (3-Tier Distributed Architecture)

```mermaid
flowchart TD
    subgraph HostAgents["Warstwa Agentów Hosta (Windows / Linux)"]
        A1["ancymon-agent 1 (Go)"]
        A2["ancymon-agent 2 (Go)"]
        WAL["Segmented WAL Buffer (1 MB Chunks, FIFO 50 MB)"]
        A1 --- WAL
    end

    subgraph ServerContainer["LXC Server Container (Debian / Proxmox VE)"]
        Caddy["Caddy Reverse Proxy<br/>Port 443 (TLS Ingress, ECDSA P-256 Internal CA)"]
        Server["ancymon-server (Go)<br/>- Ingest gRPC (h2c :50051)<br/>- GraphQL Server (HTTP/WSS :8080)<br/>- Heartbeat Watchdog (>60s offline)"]
        VM["VictoriaMetrics (TSDB)<br/>- Influx Line Protocol (/write)<br/>- MetricsQL (/query_range)"]
        
        Caddy -- "h2c (Port 50051)" --> Server
        Caddy -- "HTTP / WSS (Port 8080)" --> Server
        Server -- "Influx Line Protocol" --> VM
        Server -- "MetricsQL Queries" --> VM
    end

    subgraph MobileClient["Warstwa Prezentacji Mobilnej"]
        App["AncyMon Mobile App (Flutter)<br/>- Ferry GraphQL Client<br/>- Dynamic SecurityContext (ECDSA CA)<br/>- Riverpod State<br/>- fl_chart Visualizations"]
    end

    HostAgents -- "gRPC over HTTP/2 (Client Streaming)<br/>TLS Port 443 + PSK Bearer" --> Caddy
    MobileClient -- "GraphQL HTTPS (Queries / Mutations)<br/>GraphQL WSS (Subscriptions)<br/>TLS Port 443 + PSK Bearer" --> Caddy
```

---

## 2. Kluczowe Parametry i Wymagania Techniczne

### 2.1. Agent Hosta (`ancymon-agent`)
* **Język i kompilacja:** Go, statycznie linkowane pliki binarne (`ancymon-agent` dla Linuxa, `ancymon-agent.exe` dla Windowsa). Zero zależności zewnętrznych (brak wymogu instalowania bibliotek czy środowisk uruchomieniowych).
* **Usługa systemowa:** Obsługa `systemd` (Linux) oraz `Windows Service` przez `kardianos/service`.
* **Częstotliwość próbkowania:** Dokładnie 1 Hz (1 sekunda).
* **Biała lista systemów plików dla dysków:** `ext4`, `xfs`, `btrfs`, `zfs`, `ntfs`, `vfat`, `fat32`, `apfs`. Wszystkie wirtualne/pseudo-systemy plików (`tmpfs`, `devtmpfs`, `squashfs`, `overlay`, `/proc`, `/sys`) są ignorowane.
* **Bufor offline WAL (Write-Ahead Log):**
  - Pliki rotowane po 1 MB w katalogu `./buffer/` (np. `segment_000001.wal`).
  - Maksymalny rozmiar: 50 MB (50 segmentów).
  - Po przekroczeniu 50 MB: eksmisja FIFO (usunięcie najstarszego ukończonego segmentu).
  - RAM agenta: niezmienne ~10-15 MB bez względu na długość awarii sieci.
  - Odtwarzanie: po powrocie połączenia nowe dane trafiają na ogon WAL, worker przesyła segmenty chronologicznie, segment usuwany dopiero po potwierdzeniu przez serwer.
* **Parametry Keepalive gRPC:**
  - `grpc.keepalive_time_ms = 30000` (ping co 30s)
  - `grpc.keepalive_timeout_ms = 10000` (timeout 10s)
  - `grpc.keepalive_permit_without_stream = true`

### 2.2. Serwer Centralny (`ancymon-server` + Infra)
* **Ingestia:** gRPC z HTTP/2, egzekwowanie `MinTime = 15s`, `PermitWithoutStream = true`, `ServerTime = 60s`, `ServerTimeout = 20s`.
* **Autoryzacja:** PSK Bearer Token weryfikowany w interceptorze gRPC oraz w nagłówkach/connectionParams GraphQL.
* **Storage:** VictoriaMetrics:
  - Zapis: Influx Line Protocol na endpoint `/write`.
  - Zapytania: MetricsQL `/api/v1/query_range` z parametrem `step` wyliczanym dynamicznie pod kątem docelowej liczby punktów na wykresie (~100-300 punktów).
* **Watchdog:** Oznaczenie hosta jako `offline` po upływie > 60 sekund od ostatniej otrzymanej telemetrii.
* **GraphQL:**
  - `fleetSummary` (subskrypcja stanu maszyn dla Dashboardu)
  - `machineMetrics(machineId)` (subskrypcja szczegółowa 1 Hz dla aktywnej maszyny)
  - `machineHistory(machineId, metric, range, date)` (zapytania historyczne z filtrami 1h, 6h, 12h, 24h, 3d, 7d, kalendarz)
  - `deleteMachine(machineId)` (mutacja wyrejestrowania nieaktywnej stacji)

### 2.3. Caddy Reverse Proxy & ECDSA CA
* Caddy generuje wewnętrzny certyfikat CA oparty o krzywą eliptyczną ECDSA (P-256).
* Zapewnia to miniaturowy rozmiar certyfikatu CA (~600-700 bajtów po usunięciu nagłówków PEM i spakowaniu w JSON).
* JSON parowania generowany w terminalu:
  `{"ip":"192.168.1.50","port":443,"token":"<PSK>","ca":"<COMPACT_BASE64>"}`

### 2.4. Aplikacja Mobilna Flutter (`mobile/`)
* **State Management:** Riverpod.
* **GraphQL Client:** Ferry (`ferry`, `ferry_flutter`, generowane modele przez `build_runner`).
* **TLS Security:** Odczyt surowego Base64 z kodu QR, konwersja na DER i wstrzyknięcie do `SecurityContext` w Dart. Bez potrzeby instalacji certyfikatu w Android/iOS.
* **Wizualizacja:** `fl_chart`.

---

## 3. Struktura Katalogów Projektu

```text
ancymon/
├── .agents/                    # Konfiguracja agentów AI i workflow Antigravity
│   ├── rules/AGENTS.md         # Nadrzędne reguły przestrzeni roboczej
│   ├── agents/                 # Definicje wyspecjalizowanych pod-agentów
│   └── skills/                 # Baza wiedzy i runbooki procesowe
├── agent/                      # Host Agent w Go (ancymon-agent)
│   ├── cmd/                    # Entrypointy CLI / Service daemona
│   ├── internal/collector/     # Zbieranie metryk gopsutil + biała lista dysków
│   ├── internal/wal/           # Bufor offline WAL (segmenty 1MB, FIFO, replay)
│   └── internal/transport/     # Klient gRPC streaming + keepalive
├── server/                     # Serwer Centralny w Go (ancymon-server)
│   ├── cmd/                    # Entrypoint serwera i generatora QR
│   ├── internal/grpc/          # Serwer gRPC ingestii + interceptory PSK
│   ├── internal/storage/       # Integracja z VictoriaMetrics (Influx & MetricsQL)
│   ├── internal/watchdog/      # Pamięć RAM cache + Heartbeat Watchdog (60s)
│   └── internal/graphql/       # Silnik GraphQL (subskrypcje, zapytania, mutacje)
├── mobile/                     # Aplikacja Mobilna Flutter (AncyMon Client)
│   ├── lib/core/security/      # Dynamiczny SecurityContext z certyfikatem ECDSA
│   ├── lib/core/graphql/       # Klient Ferry + powiązanie z Riverpod
│   ├── lib/features/pairing/   # Skaner QR (mobile_scanner) + Secure Storage
│   ├── lib/features/dashboard/ # Główna lista stacji, wskaźniki online/offline
│   └── lib/features/detail/    # Karty telemetryczne + wykresy fl_chart (chipy 1h-7d)
├── proto/                      # Kontrakty Protocol Buffers (telemetry.proto)
├── graphql/                    # Schematy GraphQL (schema.graphql)
└── deploy/                     # Konfiguracja Caddyfile, Docker Compose i Proxmox LXC
```
