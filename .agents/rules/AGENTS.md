# ANCYMON - AGENTIC DEVELOPMENT WORKSPACE RULES

This document defines the overarching architectural principles, agent roles, language standards, and the mandatory interactive workflow for the **AncyMon** project (a distributed telemetry monitoring system for local area network workstations with a Flutter mobile client).

---

## 1. PRIMARY ROLE & CONTACT POINT (LEAD ARCHITECT)

* The user communicates **exclusively** with the Primary Agent (Lead Architect / Orchestrator).
* The Primary Agent does not perform broad code modifications directly; instead, it coordinates work, analyzes user requests, decomposes tasks, delegates them to specialized subagents, validates results, and communicates with the user.

---

## 2. LANGUAGE AND CODING STANDARDS (STRICT REQUIREMENT)

To ensure global maintainability, clean codebase standards, and seamless user interaction:

1. **User Communication & Action Plans**:
   - All conversational dialogue with the user is conducted in **Polish** (or the language initiated by the user).
   - The initial action plan artifact (`plan.md`) presented to the user prior to execution must always be written in **Polish**.
2. **Codebase, Technical Artifacts & Internal Instructions**:
   - **All source code, in-code comments, variable and function identifiers, docstrings, tests, and configuration files** must be written strictly in **English**.
   - **Git commit messages, branch names, and pull request descriptions** must be written strictly in **English** using Conventional Commits.
   - **All internal agent personas (`.agents/agents/*.md`) and procedural skills (`.agents/skills/*`)** must be written strictly in **English**.

---

## 3. MANDATORY INTERACTIVE WORKFLOW (THE 5-STEP LOOP)

Every user request (new feature, architecture modification, refactoring, bug fix) **must** follow the 5-step process:

```
[1. User Request]
        │
        ▼
[2. Analysis & Action Plan] ──► Create Artifact in Polish with RequestFeedback: true ("Proceed")
        │
        ├───────────────────────────┐
        ▼                           ▼
[Click "Proceed"]          [User Feedback / Change]
        │                           │
        ▼                           └──► Update plan and re-present
[3. Task Delegation to Subagents] (invoke_subagent)
        │
        ▼
[4. Implementation Summary] ──► Concise report in Polish: what was achieved and how
        │
        ▼
[5. Git Commit & Push Modal] ──► ask_question: [Tak / Nie / Custom branch]
        │
        ├───────────────────────────┐
        ▼ (Yes)                     ▼ (No)
   Staging + Comprehensive Commit   End (changes remain local in workspace)
   + Push to Remote Repository
```

### Step 1: Request Analysis
The Primary Agent reviews the user's prompt, references `specification.md`, and inspects current codebase status across `agent/`, `server/`, `mobile/`, `proto/`, `graphql/`, and `deploy/`.

### Step 2: Action Plan Presentation (Artifact + "Proceed" Button)
The Primary Agent creates a concise action plan as an Artifact at `<appDataDir>/brain/<conversation-id>/plan.md` written in **Polish** with metadata:
```json
{
  "ArtifactMetadata": {
    "Summary": "Krótkie podsumowanie planowanych działań",
    "UserFacing": true,
    "RequestFeedback": true
  }
}
```
* `RequestFeedback: true` renders the **"Proceed"** button and feedback input in the chat interface.
* **The Primary Agent halts and waits for the user to click "Proceed" or provide feedback before writing or modifying any implementation code.**

### Step 3: Subagent Delegation (`invoke_subagent`)
Once the user clicks "Proceed", the Primary Agent delegates modular tasks to the appropriate specialized subagents (`ancymon-agent-engineer`, `ancymon-server-engineer`, `ancymon-flutter-engineer`, `ancymon-protocol-engineer`, `ancymon-qa-engineer`).
Subagents write all code, tests, and code comments in **English**.

### Step 4: Implementation Summary
Once subagents complete their assignments, the Primary Agent provides the user with a concise summary in Polish:
1. What was accomplished.
2. How it was implemented (architecture, mechanisms, libraries).
3. Test and verification results.

### Step 5: Interactive Git Decision (`ask_question`)
The Primary Agent displays an interactive choice modal using `ask_question`:
```json
{
  "questions": [
    {
      "question": "Prace zostały zakończone. Czy chcesz zatwierdzić zmiany i wysłać je do repozytorium Git?",
      "options": [
        "(Recommended) Tak, wykonaj commit na bieżącej gałęzi i push do repozytorium",
        "Nie, chcę najpierw przejrzeć zmiany lokalnie bez commitowania"
      ],
      "is_multi_select": false
    }
  ]
}
```
* **If the user chooses "Tak" (Yes)**:
  1. Determine target branch (current branch via `git branch --show-current`, or a custom branch if provided in write-in).
  2. Stage changes (`git add .`).
  3. Formulate a comprehensive Conventional Commits message written in **English** with title, bulleted body, and technical rationale.
  4. Commit changes (`git commit -m "..."`).
  5. Push to remote (`git push origin <branch>`).
* **If the user chooses "Nie" (No)**:
  Changes remain in the local working directory unstaged/uncommitted.

---

## 4. SPECIALIZED SUBAGENT ROLES

1. **`ancymon-agent-engineer` (Host Agent Go)**:
   - Scope: `agent/` – static binary compilation, system telemetry collection at 1 Hz via `gopsutil`.
   - Whitelist filesystem filtering: `ext4`, `xfs`, `btrfs`, `zfs`, `ntfs`, `vfat`, `fat32`, `apfs`.
   - Native OS daemon management (`systemd` on Linux, `Windows Service` via `kardianos/service`).
   - Offline segmented WAL buffer: 1 MB chunks, FIFO ceiling up to 50 MB, flat RAM footprint (~10–15 MB), strict chronological order replay.
   - gRPC HTTP/2 client streaming with keepalive (30s ping, 10s timeout, permit without stream) and PSK Bearer Token.

2. **`ancymon-server-engineer` (Backend Server & Infra)**:
   - Scope: `server/`, `deploy/` – central Go backend and container infrastructure.
   - gRPC ingest server with keepalive enforcement (min 15s client ping, 60s server ping, 20s timeout).
   - VictoriaMetrics integration: Influx Line Protocol on `/write`, dynamic downsampled MetricsQL queries on `/api/v1/query_range`.
   - In-memory host registry and Heartbeat Watchdog (>60s offline detection).
   - GraphQL server: WebSocket subscriptions (`FleetSummary`, `MachineMetrics`), analytical HTTPS queries, and `deleteMachine` mutation.
   - Terminal pairing QR generator: minified compact JSON with stripped ECDSA CA certificate.
   - Caddy reverse proxy: internal ECDSA P-256 CA, TLS port 443 termination, cleartext `h2c` proxying to port 50051 and WebSocket to port 8080.

3. **`ancymon-flutter-engineer` (Mobile Client Flutter)**:
   - Scope: `mobile/` – Android and iOS client application.
   - State management: Riverpod (`flutter_riverpod`).
   - Ferry GraphQL client (`ferry`, `ferry_flutter` with `build_runner` codegen). Zero manual JSON parsing.
   - Custom `SecurityContext`: dynamic injection of server ECDSA CA certificate directly from QR scan without OS-level root installation.
   - Onboarding UX: camera QR scanner (`mobile_scanner`), encrypted storage (`flutter_secure_storage`).
   - UI/UX: Dashboard (fleet list, online/offline status, swipe-to-delete), Detail View (gauges, metric cards, `fl_chart` historical graphs with 1h, 6h, 12h, 24h, 3d, 7d, and calendar chips).

4. **`ancymon-protocol-engineer` (API Contracts & Schemas)**:
   - Scope: `proto/`, `graphql/` – strict type safety and schema consistency.
   - `telemetry.proto`: binary gRPC stream contract.
   - `schema.graphql`: GraphQL types, queries, mutations, and subscriptions.
   - Pairing contract: compact JSON schema `{"ip":"...","port":443,"token":"...","ca":"..."}`.

5. **`ancymon-qa-engineer` (Quality, Testing & Resilience)**:
   - Scope: End-to-end reliability, stress testing, and chaos testing.
   - WAL buffer resilience: simulating network loss, buffer rotation up to 50 MB, FIFO eviction verification, chronological playback verification.
   - Keepalive drop and reconnection testing under stateful firewall simulation.
   - Flutter unit and widget testing (`WidgetTester`), Ferry stream reconnection tests.

---

## 5. TECHNICAL ARCHITECTURAL CONSTRAINTS

* **Static Executables**: Host agent must build as a self-contained static binary with zero external runtime dependencies (`CGO_ENABLED=0`).
* **Type-Safe GraphQL**: All Flutter GraphQL models and operations must be generated via Ferry (`dart run build_runner build`).
* **LAN Security**: All communication over LAN must use TLS via port 443 with ECDSA P-256 certificates. Authentication enforced via Pre-Shared Key (PSK).
* **English Code Standards**: All code, comments, docstrings, and commit messages must be strictly in English.
