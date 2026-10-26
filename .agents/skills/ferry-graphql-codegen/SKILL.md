---
name: ferry-graphql-codegen
description: >-
  Runbook for configuring and generating type-safe GraphQL client code using Ferry in Flutter,
  binding streams to Riverpod, and injecting a custom ECDSA root CA into Dart's SecurityContext
  for zero-typing QR code onboarding without OS-level certificate installation.
---

# Ferry GraphQL Client & Custom TLS SecurityContext Runbook

Ten skill opisuje procedurę konfiguracji silnie typowanego klienta GraphQL **Ferry** w projekcie `mobile/` oraz wstrzykiwania niestandardowego certyfikatu CA ECDSA z kodu QR.

---

## 1. Zależności `pubspec.yaml`

W aplikacji Flutter wymagane są następujące pakiety:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.0
  ferry: ^0.16.0
  ferry_flutter: ^0.9.0
  gql_http_link: ^1.1.0
  gql_websocket_link: ^1.1.0
  web_socket_channel: ^2.4.0
  flutter_secure_storage: ^9.0.0
  mobile_scanner: ^5.0.0
  fl_chart: ^0.68.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  ferry_generator: ^0.10.0
```

---

## 2. Dynamiczny `SecurityContext` z Certyfikatem ECDSA

Ponieważ Caddy używa wewnętrznego CA z kluczami ECDSA (P-256), a aplikacja mobilna pobiera certyfikat ze skanu kodu QR w postaci surowego Base64:

```dart
import 'dart:convert';
import 'dart:io';

SecurityContext createCustomSecurityContext(String caBase64) {
  final securityContext = SecurityContext(withTrustedRoots: false);
  // Dekodowanie zminifikowanego Base64 na surowe bajty DER certyfikatu
  final certBytes = base64Decode(caBase64);
  securityContext.setTrustedCertificatesBytes(certBytes);
  return securityContext;
}
```

### Konfiguracja Linków Ferry:
```dart
import 'dart:io';
import 'package:ferry/ferry.dart';
import 'package:gql_http_link/gql_http_link.dart';
import 'package:gql_websocket_link/gql_websocket_link.dart';
import 'package:web_socket_channel/io.dart';

Client buildFerryClient({
  required String host,
  required int port,
  required String token,
  required String caBase64,
}) {
  final securityContext = createCustomSecurityContext(caBase64);
  
  // Customowy HttpClient z wstrzykniętym CA dla zapytań HTTPS
  final httpClient = HttpClient(context: securityContext);
  final httpLink = HttpLink(
    'https://$host:$port/graphql',
    httpClient: httpClient,
    defaultHeaders: {'Authorization': 'Bearer $token'},
  );

  // Customowy WebSocket z wstrzykniętym CA dla subskrypcji WSS
  final wsUrl = Uri.parse('wss://$host:$port/graphql');
  final wsLink = WebSocketLink(
    null,
    channelFunc: () => IOWebSocketChannel.connect(
      wsUrl,
      headers: {'Authorization': 'Bearer $token'},
      customClient: httpClient,
    ),
    initialPayload: () => {'Authorization': 'Bearer $token'},
  );

  final link = Link.split((request) => request.isSubscription, wsLink, httpLink);
  return Client(link: link);
}
```

---

## 3. Generowanie Modeli (`build_runner`)

1. Umieść pliki operacji GraphQL (`fleet_summary.graphql`, `machine_metrics.graphql`, `history.graphql`, `delete_machine.graphql`) w odpowiednich katalogach funkcjonalnych.
2. Zbuduj silnie typowane modele:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
3. Generowane pliki `*.req.gql.dart`, `*.data.gql.dart`, `*.var.gql.dart` stanowią wyłączną podstawę do komunikacji z serwerem.

---

## 4. Powiązanie z Riverpod

Zwiąż strumienie Ferry z `StreamProvider` w Riverpod:

```dart
final fleetSummaryProvider = StreamProvider.autoDispose<List<GviewModelSummaryData>>((ref) {
  final client = ref.watch(ferryClientProvider);
  final req = GFleetSummaryReq();
  return client.request(req).map((response) {
    if (response.hasErrors) {
      throw Exception(response.graphqlErrors?.first.message ?? 'GraphQL Error');
    }
    return response.data?.fleetSummary ?? [];
  });
});
```
To podejście gwarantuje brak ręcznego parsowania JSON-ów, bezpieczeństwo typów w czasie kompilacji oraz reaktywne odświeżanie interfejsu.
