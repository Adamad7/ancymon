---
name: wal-resilience-testing
description: >-
  Runbook and validation procedures for testing the offline segmented Write-Ahead Log (WAL) buffer
  in ancymon-agent. Use when implementing or verifying disk buffering, segment rotation (1 MB),
  FIFO eviction under 50 MB ceiling, flat RAM footprint, and strict chronological replay upon network reconnection.
---

# WAL Buffer Resilience Testing Runbook

Ten skill zawiera procedury testowe dla bufora offline WAL (Segmented Write-Ahead Log) w module `ancymon-agent`.

---

## 1. Wymagania Specyfikacji dla WAL
* **Format:** Pliki segmentowe o stałym rozmiarze 1 MB w dedykowanym katalogu `./buffer/` (np. `segment_000001.wal`).
* **Pamięć RAM:** Zużycie pamięci agenta musi pozostać stałe (~10–15 MB) niezależnie od czasu trwania rozłączenia sieciowego.
* **Limit dysku:** Konfigurowalny limit (domyślnie 50 MB, co odpowiada maksymalnie 50 plikom segmentów).
* **Eksmisja FIFO:** Po osiągnięciu limitu dysku najstarszy ukończony segment jest usuwany.
* **Gwarancja kolejności (Chronological Replay):**
  1. Podczas braku połączenia nowe metryki (1 Hz) trafiają do bieżącego aktywnego segmentu.
  2. Po powrocie połączenia **nowe pomiary wciąż trafiają na ogon WAL** aż do pełnego opróżnienia zaległości.
  3. Worker w tle wysyła zaległe segmenty w ścisłej kolejności chronologicznej (od najstarszego do najnowszego).
  4. Po pełnym przesłaniu i potwierdzeniu przez serwer (gRPC ACK) segment jest usuwany z dysku.
  5. Bezpośredni live streaming wznawia się dopiero po opróżnieniu wszystkich plików zaległości.

---

## 2. Scenariusze Testowe

### Scenariusz A: Rotacja segmentów i zachowanie limitu RAM
1. Uruchom agenta ze sztucznie zablokowanym adresem serwera gRPC (lub z adresem `127.0.0.1:9999`, gdzie nic nie nasłuchuje).
2. Obserwuj katalog `./buffer/`:
   - Sprawdź, czy po zgromadzeniu 1 MB telemetrii tworzy się kolejny plik `segment_000002.wal`.
3. Monitoruj proces w systemie (`top`, `ps aux` lub test Go):
   - Weryfikacja: pamięć RSS procesu nie powinna rosnąć liniowo, lecz ustabilizować się na poziomie ~10–15 MB.

### Scenariusz B: Limit 50 MB i eksmisja FIFO
1. Wygeneruj sztuczne dane wypełniające bufor do 50 segmentów po 1 MB.
2. Wygeneruj 51. segment.
3. Weryfikacja:
   - Całkowity rozmiar katalogu `./buffer/` nie przekracza 50 MB.
   - Plik `segment_000001.wal` został bezpiecznie usunięty (eksmisja najstarszego).
   - W logach pojawia się czytelne ostrzeżenie o eksmisji FIFO.

### Scenariusz C: Chronologiczne odtwarzanie po powrocie łączności
1. Zgromadź w buforze kilka segmentów (np. 3 segmenty z pomiarami z timestampami T1, T2, T3).
2. Uruchom serwer gRPC (`ancymon-server`) i odblokuj komunikację.
3. Weryfikacja po stronie serwera:
   - Pomiary docierają w kolejności T1 -> T2 -> T3.
   - Nowe pomiary (T4) generowane podczas draining nie wyprzedzają zaległych danych.
   - Każdy segment jest usuwany z dysku agenta po odebraniu `TelemetryAck`.
   - Po wysłaniu wszystkich segmentów agent przełącza się w normalny tryb strumieniowania na żywo.
