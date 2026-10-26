# ancymon-mobile

Cross-platform mobile client application for Android and iOS built with Flutter and Dart.

## Key Features
- **State Management**: Reactive state binding via `flutter_riverpod`.
- **Ferry GraphQL Client**: 100% compile-time type safety with code generated from `graphql/schema.graphql` via `build_runner`.
- **Dynamic SecurityContext**: Dynamic runtime injection of the server's ECDSA P-256 CA certificate from QR scan without OS-level root installation.
- **Onboarding UX**: Camera QR code scanning (`mobile_scanner`) and secure credential persistence (`flutter_secure_storage`).
- **User Interface**: Main Fleet Dashboard (online/offline badges, swipe-to-delete) and Workstation Detail View (hardware metric cards, interactive `fl_chart` historical views with 1h, 6h, 12h, 24h, 3d, 7d, and calendar filters).

## Responsible Subagent
- **`ancymon-flutter-engineer`**
