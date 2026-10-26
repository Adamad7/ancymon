# ancymon-mobile

Aplikacja mobilna AncyMon Client stworzona we frameworku Flutter (Android & iOS).

## Kluczowe Cechy
- **Zarządzanie stanem**: Riverpod (`flutter_riverpod`).
- **Klient GraphQL**: Ferry (`ferry`, `ferry_flutter`) ze 100% bezpieczeństwem typów i generacją modeli z `graphql/schema.graphql`.
- **Dynamiczny SecurityContext**: Wstrzykiwanie certyfikatu CA ECDSA P-256 z kodu QR bez instalacji certyfikatów w systemie telefonu.
- **Onboarding UX**: Skaner kodów QR (`mobile_scanner`) i bezpieczny magazyn danych (`flutter_secure_storage`).
- **Interfejs UI**: Główny Dashboard (lista stacji, online/offline, swipe-to-delete) oraz Widok Szczegółowy (karty telemetryczne, wykresy `fl_chart` z filtrami czasowymi 1h, 6h, 12h, 24h, 3d, 7d i kalendarzem).

## Odpowiedzialny Agent AI
- **`ancymon-flutter-engineer`**
