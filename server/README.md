# ancymon-server

Moduł serwera centralnego w języku Go koordynujący odbiór telemetrii, zapis w bazie VictoriaMetrics oraz dostarczanie API GraphQL dla aplikacji mobilnej.

## Kluczowe Cechy
- **Ingestia gRPC**: HTTP/2 streaming na porcie 50051 (`h2c` za Caddy) z egzekwowaniem keepalive (min. 15s) i walidacją PSK.
- **Pamięć podręczna i Watchdog**: In-memory cache stacji roboczych z automatycznym oznaczaniem `offline` po >60s braku telemetrii.
- **Integracja VictoriaMetrics**: Zapis metryk Influx Line Protocol (`/write`) oraz zapytania historyczne MetricsQL (`/api/v1/query_range`) z dynamicznym parametrem `step`.
- **Silnik GraphQL**: Subskrypcje WebSockets (`FleetSummary`, `MachineMetrics`), zapytania historyczne HTTPS, mutacja `deleteMachine`.
- **Zero-Typing Pairing**: Generator terminalowego kodu QR z certyfikatem ECDSA CA i tokenem PSK.

## Odpowiedzialny Agent AI
- **`ancymon-server-engineer`**
