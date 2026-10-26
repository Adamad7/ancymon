---
name: ferry-graphql-codegen
description: >-
  Runbook for configuring and generating type-safe GraphQL client code using Ferry in Flutter,
  binding streams to Riverpod, and injecting a custom ECDSA root CA into Dart's SecurityContext
  for zero-typing QR code onboarding without OS-level certificate installation.
---

# Ferry GraphQL Client & Custom TLS SecurityContext Runbook

This skill describes how to set up the strongly typed **Ferry** GraphQL client in `mobile/` and dynamically inject the custom ECDSA CA certificate scanned from the onboarding QR code.

---

## 1. `pubspec.yaml` Dependencies

The Flutter client requires the following packages:

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

## 2. Dynamic `SecurityContext` with ECDSA CA

Since Caddy runs an internal CA with elliptic curve keys (ECDSA P-256), the mobile app receives the certificate as raw Base64 from the pairing QR scan:

```dart
import 'dart:convert';
import 'dart:io';

SecurityContext createCustomSecurityContext(String caBase64) {
  final securityContext = SecurityContext(withTrustedRoots: false);
  // Decode minified Base64 into raw DER certificate bytes
  final certBytes = base64Decode(caBase64);
  securityContext.setTrustedCertificatesBytes(certBytes);
  return securityContext;
}
```

### Ferry Link Setup:
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
  
  // Custom HttpClient with injected CA for HTTPS queries
  final httpClient = HttpClient(context: securityContext);
  final httpLink = HttpLink(
    'https://$host:$port/graphql',
    httpClient: httpClient,
    defaultHeaders: {'Authorization': 'Bearer $token'},
  );

  // Custom WebSocket with injected CA for WSS subscriptions
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

## 3. Model Code Generation (`build_runner`)

1. Define GraphQL operations (`fleet_summary.graphql`, `machine_metrics.graphql`, `history.graphql`, `delete_machine.graphql`).
2. Run code generation:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
3. Use the generated `*.req.gql.dart`, `*.data.gql.dart`, and `*.var.gql.dart` files exclusively for network operations.

---

## 4. Binding with Riverpod

Bind Ferry streams directly to Riverpod's `StreamProvider`:

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
This guarantees compile-time type safety, zero manual JSON parsing, and automatic reactive UI rebuilds.
