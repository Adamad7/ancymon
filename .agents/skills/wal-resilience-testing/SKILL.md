---
name: wal-resilience-testing
description: >-
  Runbook and validation procedures for testing the offline segmented Write-Ahead Log (WAL) buffer
  in ancymon-agent. Use when implementing or verifying disk buffering, segment rotation (1 MB),
  FIFO eviction under 50 MB ceiling, flat RAM footprint, and strict chronological replay upon network reconnection.
---

# WAL Buffer Resilience Testing Runbook

This skill outlines testing procedures and validation criteria for the offline segmented Write-Ahead Log (WAL) buffer in `ancymon-agent`.

---

## 1. Specification Requirements for WAL
* **Storage Format**: Fixed-size 1 MB segment files stored in a dedicated `./buffer/` folder (e.g., `segment_000001.wal`).
* **RAM Ceiling**: Memory footprint must remain strictly flat (~10–15 MB RSS) regardless of disconnection duration.
* **Disk Ceiling**: Configurable maximum threshold (default: 50 MB, corresponding to up to 50 active segment files).
* **FIFO Eviction Policy**: When directory reaches 50 MB, the oldest completed segment file must be deleted.
* **Chronological Replay Guarantees**:
  1. During network outage, incoming 1 Hz metrics divert into the active WAL segment.
  2. Upon network restoration, **new measurements continue to append to the tail of the WAL** until backlog drains.
  3. A background worker drains segments sequentially in strict chronological order (oldest to newest).
  4. Each segment is unlinked from disk only after receiving a server acknowledgement (`TelemetryAck`).
  5. Direct live streaming resumes seamlessly only when zero backlog files remain.

---

## 2. Test Scenarios

### Scenario A: Segment Rotation & Flat RAM Footprint
1. Start the agent with an unreachable server target (e.g., `127.0.0.1:9999` with nothing listening).
2. Monitor `./buffer/`:
   - Confirm that once a segment reaches 1 MB of telemetry, `segment_000002.wal` is opened.
3. Track process memory via system tools or Go benchmarks:
   - Verification: Process RSS memory must stabilize around ~10–15 MB without linear growth.

### Scenario B: 50 MB Ceiling & FIFO Eviction
1. Populate the buffer directory with synthetic data up to 50 segments of 1 MB.
2. Emit the 51st segment.
3. Verification:
   - Total directory size of `./buffer/` remains $\le 50$ MB.
   - The oldest file `segment_000001.wal` is deleted.
   - An explicit FIFO eviction warning is logged.

### Scenario C: Chronological Replay on Reconnect
1. Accumulate several segments in the buffer with timestamps $T_1, T_2, T_3$.
2. Launch `ancymon-server` and unblock network traffic.
3. Verification:
   - Server ingests metrics in exact order: $T_1 \to T_2 \to T_3$.
   - New incoming frames ($T_4$) during replay do not leapfrog earlier frames.
   - Each segment is removed only after `TelemetryAck` is received.
   - The agent transitions to direct live streaming once backlog is completely drained.
