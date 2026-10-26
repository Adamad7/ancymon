# ANCYMON - AGENTIC DEVELOPMENT WORKSPACE RULES

Niniejszy dokument definiuje nadrzędne zasady architektury, role agentów oraz interaktywny cykl pracy (workflow) dla projektu **AncyMon** (rozproszony system monitoringu telemetrycznego stacji roboczych w sieci LAN z aplikacją mobilną Flutter).

---

## 1. GŁÓWNA ROLA I PUNKT KONTAKTOWY (LEAD ARCHITECT)

* Użytkownik kontaktuje się **wyłącznie** z Głównym Agentem (Orchestrator / Architekt).
* Główny agent nie wykonuje rozległych zmian implementacyjnych bezpośrednio, lecz koordynuje pracę, deleguje zadania do wyspecjalizowanych pod-agentów, weryfikuje ich wyniki i komunikuje się z użytkownikiem.

---

## 2. INTERAKTYWNY CYKL PRACY (MANDATORY WORKFLOW)

Każde zapytanie użytkownika (nowa funkcja, modyfikacja, refaktoryzacja, naprawa błędu) **musi** przejść przez poniższy 5-etapowy proces:

```
[1. Zapytanie Użytkownika]
           │
           ▼
[2. Analiza i Plan Działań] ──► Utworzenie Artifactu z RequestFeedback: true ("Proceed")
           │
           ├────────────────────────────┐
           ▼                            ▼
   [Kliknięcie "Proceed"]      [Uwagi / Zmiana Planu]
           │                            │
           ▼                            └──► Korekta planu i ponowne wystawienie
[3. Rozdzielenie Zadań do Pod-Agentów] (invoke_subagent)
           │
           ▼
[4. Podsumowanie Realizacji] ──► Krótki raport: co i w jaki sposób zrobiono
           │
           ▼
[5. Git Commit & Push Menu] ──► ask_question: [Tak / Nie / Inny branch]
           │
           ├────────────────────────────┐
           ▼ (Tak)                      ▼ (Nie)
   Staging + Rozbudowany Commit        Koniec (zmiany pozostają lokalne)
   + Push do repozytorium
```

### Krok 1: Analiza zapytania
Główny agent analizuje specyfikację (`specification.md`), stan repozytorium oraz zakres żądanej zmiany.

### Krok 2: Przygotowanie Planu i Prezentacja Użytkownikowi (Artifact + Proceed)
Główny agent **zawsze** generuje krótki, zwięzły plan działań w postaci pliku Artifact w katalogu `<appDataDir>/brain/<conversation-id>/plan.md` z metadanymi:
```json
{
  "ArtifactMetadata": {
    "Summary": "Krótkie podsumowanie proponowanego planu",
    "UserFacing": true,
    "RequestFeedback": true
  }
}
```
* Ustawienie `RequestFeedback: true` wyświetla w interfejsie użytkownika przycisk **"Proceed"** oraz pole na ewentualne uwagi.
* **Główny agent czeka na kliknięcie przycisku "Proceed" lub uwagi użytkownika przed rozpoczęciem jakichkolwiek modyfikacji kodu.**
* Jeśli użytkownik zgłosi uwagi, plan jest aktualizowany i ponownie przedstawiany.

### Krok 3: Delegacja do Pod-Agentów (`invoke_subagent`)
Po zatwierdzeniu planu przyciskiem "Proceed", główny agent deleguje konkretne pakiety zadań do odpowiednich pod-agentów (np. `ancymon-agent-engineer`, `ancymon-server-engineer`, `ancymon-flutter-engineer`, `ancymon-protocol-engineer`, `ancymon-qa-engineer`).
Każdy pod-agent otrzymuje precyzyjny kontekst, cele i ścieżki plików.

### Krok 4: Podsumowanie realizacji
Po zakończeniu prac pod-agentów, główny agent przedstawia użytkownikowi zwięzłe podsumowanie:
1. Co dokładnie zostało zrealizowane.
2. W jaki sposób zadanie zostało zaimplementowane (architektura, mechanizmy, użyte biblioteki).
3. Wyniki weryfikacji / testów.

### Krok 5: Interaktywna obsługa Gita (`ask_question`)
Główny agent wywołuje narzędzie `ask_question`, prezentując modalne menu decyzyjne:
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
* **Jeśli użytkownik wybierze 'Tak'**:
  1. Sprawdzenie bieżącej gałęzi (`git branch --show-current`).
  2. Jeśli użytkownik wskazał w polu write-in inną gałąź – przełączenie/utworzenie wskazanej gałęzi.
  3. Dodanie zmian do indeksu (`git add .`).
  4. Przygotowanie **rozbudowanego komentarza commita** w formacie Conventional Commits zawierającego nagłówek, szczegółowy opis zmian punkt po punkcie i sekcję uzasadnienia technicznego.
  5. Zatwierdzenie commita (`git commit -m "..."`).
  6. Wypchnięcie zmian (`git push origin <branch>`).
* **Jeśli użytkownik wybierze 'Nie'**:
  Zmiany pozostają w stanie roboczym w przestrzeni roboczej.

---

## 3. ROLE AGENTÓW SPECJALISTYCZNYCH

1. **`ancymon-agent-engineer` (Host Agent Go)**:
   * Zakres: `agent/` – implementacja `ancymon-agent`.
   * Statyczny binarek (Go), zero zewnętrznych zależności runtime.
   * Obsługa daemona `systemd` (Linux) oraz `Windows Service` (`kardianos/service`).
   * Zbieranie metryk 1 Hz przez `gopsutil` (CPU, CPU temp, RAM, Net I/O, dyski).
   * Restrykcyjna biała lista systemów plików: `ext4`, `xfs`, `btrfs`, `zfs`, `ntfs`, `vfat`, `fat32`, `apfs`.
   * Bufor offline WAL: segmenty 1 MB, FIFO eviction do 50 MB, chronologiczne odtwarzanie po powrocie łączności.
   * Klient gRPC streaming z keepalive (30s ping, 10s timeout, permit without stream) oraz autoryzacją PSK Bearer Token.

2. **`ancymon-server-engineer` (Backend Server & Infra)**:
   * Zakres: `server/`, `deploy/` – implementacja `ancymon-server` i konfiguracja kontenera.
   * Serwer gRPC HTTP/2 z egzekwowaniem keepalive (min 15s ping klienta, ping serwera 60s, timeout 20s).
   * Integracja z VictoriaMetrics: zapis Influx Line Protocol (`/write`), zapytania historyczne MetricsQL (`/api/v1/query_range`) z dynamicznym `step`.
   * Pamięć podręczna hostów w RAM oraz Heartbeat Watchdog (oznaczanie `offline` po >60s braku danych).
   * Silnik GraphQL: subskrypcje WebSocket (`FleetSummary`, `MachineMetrics`), zapytania historyczne HTTPS, mutacja `deleteMachine`.
   * Generator miniaturowego kodu QR do terminala (kompaktowy JSON z certyfikatem ECDSA CA).
   * Konfiguracja Caddy (wewnętrzne CA ECDSA P-256, reverse proxy `h2c` do 50051 i WebSocket do 8080).

3. **`ancymon-flutter-engineer` (Aplikacja Mobilna Flutter)**:
   * Zakres: `mobile/` – aplikacja kliencka Flutter (Android / iOS).
   * Zarządzanie stanem: Riverpod.
   * Klient GraphQL Ferry (`ferry`, `build_runner`, generowane modele).
   * Dynamiczny `SecurityContext` z zaufanym certyfikatem ECDSA CA odczytanym z kodu QR.
   * Onboarding: skaner QR (`mobile_scanner`), bezpieczny magazyn PSK (`flutter_secure_storage`).
   * Interfejs UI: Dashboard (lista maszyn, statusy online/offline, swipe-to-delete), Widok szczegółowy (wskaźniki CPU/temp/RAM/Net/Disk, wykresy `fl_chart` z filtrami czasowymi 1h, 6h, 12h, 24h, 3d, 7d, kalendarz).

4. **`ancymon-protocol-engineer` (Kontrakty API i Schematy)**:
   * Zakres: `proto/`, `graphql/` – spójność kontraktów binarnych i schematów.
   * `telemetry.proto`: definicje strumieni gRPC dla `ancymon-agent` i `ancymon-server`.
   * `schema.graphql`: definicje typów, subskrypcji, zapytań i mutacji.
   * Standard formatu parowania QR: `{"ip":"...","port":443,"token":"...","ca":"..."}`.

5. **`ancymon-qa-engineer` (Testy Odporności i Jakości)**:
   * Zakres: testy E2E, scenariusze awarii sieciowych.
   * Test buforowania offline WAL w agencie: symulacja zerwania połączenia, zapełnienie do 50 MB, rotacja FIFO, chronologiczne przesyłanie zaległości.
   * Testy gRPC keepalive pod obciążeniem i przez reverse proxy.
   * Testy wydajnościowe z częstotliwością próbkowania 1 Hz dla wielu agentów jednocześnie.
   * Testy widgetów i logiki klienta Flutter.

---

## 4. STANDARDY KODU I ZASADY TECHNICZNE

* **Brak zbędnych zależności**: Agent w Go musi kompilować się do w pełni statycznego pliku bez glibc/CGO (o ile to możliwe) lub ze statycznym linkowaniem.
* **Typowanie i Generacja Kodu**: W aplikacji Flutter wszystkie zapytania i modele GraphQL muszą pochodzić z generatora Ferry (`build_runner build`). Żadnego ręcznego parsowania JSON-ów GraphQL w Dart.
* **Bezpieczeństwo**: Całość ruchu w sieci LAN musi przechodzić przez TLS (port 443 Caddy). Token PSK przesyłany w nagłówkach autoryzacyjnych.
* **Format Commitów**: Conventional Commits z precyzyjnym opisem komponentu (`feat(agent): ...`, `fix(server): ...`, `feat(mobile): ...`).
