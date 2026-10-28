import 'package:ancymon_mobile/core/models/connection_config.dart';
import 'package:ancymon_mobile/core/providers/connection_provider.dart';
import 'package:ancymon_mobile/features/dashboard/presentation/dashboard_screen.dart';
import 'package:ancymon_mobile/features/dashboard/providers/fleet_summary_provider.dart';
import 'package:ancymon_mobile/graphql/__generated__/schema.schema.gql.dart';
import 'package:ancymon_mobile/graphql/operations/__generated__/fleet_summary.data.gql.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const testValidCa =
      'MIIBkTCCATegAwIBAgIUOD+0iYHm45WuhwZre1LNL4sn8cYwCgYIKoZIzj0EAwIw'
      'HjEcMBoGA1UEAwwTQW5jeU1vbiBJbnRlcm5hbCBDQTAeFw0yNjEwMjcxMDI1MTJa'
      'Fw0yNzEwMjcxMDI1MTJaMB4xHDAaBgNVBAMME0FuY3lNb24gSW50ZXJuYWwgQ0Ew'
      'WTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAATJvlNovr82UbNMgVpuHfczmEfxvE7d'
      '43j/fdmyoFQXBO/X6SxPvTbgvIoHAENq1kF5pnshwtvFKihzNNYoHEYEo1MwUTAd'
      'BgNVHQ4EFgQUcYp6gKh7BejwwPD4QSo4bWGA824wHwYDVR0jBBgwFoAUcYp6gKh7'
      'BejwwPD4QSo4bWGA824wDwYDVR0TAQH/BAUwAwEB/zAKBggqhkjOPQQDAgNIADBF'
      'AiEAsFjvEZaVbw/+4u6LSM03ktxighxPkXsNJzHfn6UeejcCIA2He28qo6z6kwiw'
      '0riJyLngbNVJUlEmvGXWfBzoHzJf';

  const testConfig = ConnectionConfig(
    ip: '192.168.1.100',
    port: 443,
    token: 'test-token',
    ca: testValidCa,
  );

  final onlineMachine = GFleetSummaryData_fleetSummary(
    (b) => b
      ..machineId = 'host-uuid-1'
      ..hostname = 'workstation-alpha'
      ..status = GMachineStatus.ONLINE
      ..lastSeenTimestamp = 1700000000
      ..cpuUsagePercent = 45.0
      ..cpuTemperatureC = 52.4
      ..networkRxBytesPerSec = 1048576.0 // 1 MB/s
      ..networkTxBytesPerSec = 524288.0, // 512 KB/s
  );

  final offlineMachine = GFleetSummaryData_fleetSummary(
    (b) => b
      ..machineId = 'host-uuid-2'
      ..hostname = 'backup-server-beta'
      ..status = GMachineStatus.OFFLINE
      ..lastSeenTimestamp = 1699990000
      ..cpuUsagePercent = 0.0
      ..cpuTemperatureC = 35.0
      ..networkRxBytesPerSec = 0.0
      ..networkTxBytesPerSec = 0.0,
  );

  group('DashboardScreen Widget Tests', () {
    testWidgets('renders loading state when fleet stream is connecting', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fleetSummaryProvider.overrideWith((ref) => const Stream.empty()),
            connectionConfigProvider.overrideWith(
              (ref) => _DummyConnectionNotifier(const AsyncValue.data(testConfig)),
            ),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Connecting to Fleet Telemetry Stream...'), findsOneWidget);
    });

    testWidgets('renders empty state when no workstations exist', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fleetSummaryProvider.overrideWith((ref) => Stream.value([])),
            connectionConfigProvider.overrideWith(
              (ref) => _DummyConnectionNotifier(const AsyncValue.data(testConfig)),
            ),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Workstations Discovered Yet'), findsOneWidget);
      expect(find.text('Ensure ancymon-agent is running on your LAN hosts.'), findsOneWidget);
    });

    testWidgets('renders workstation cards with online/offline badges, gauges, and network throughput',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fleetSummaryProvider.overrideWith(
              (ref) => Stream.value([onlineMachine, offlineMachine]),
            ),
            connectionConfigProvider.overrideWith(
              (ref) => _DummyConnectionNotifier(const AsyncValue.data(testConfig)),
            ),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Verify workstation hostnames rendered
      expect(find.text('workstation-alpha'), findsOneWidget);
      expect(find.text('backup-server-beta'), findsOneWidget);

      // Verify status badges
      expect(find.text('ONLINE'), findsOneWidget);
      expect(find.text('OFFLINE'), findsOneWidget);

      // Verify CPU gauges
      expect(find.text('45%'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);

      // Verify temperatures
      expect(find.text('52.4°C'), findsOneWidget);
      expect(find.text('35.0°C'), findsOneWidget);

      // Verify network rate
      expect(find.text('1.0 MB/s'), findsOneWidget);
    });

    testWidgets('offline workstation has Dismissible and triggers delete confirmation dialog',
        (tester) async {
      var deleteCalled = false;
      String? deletedId;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fleetSummaryProvider.overrideWith(
              (ref) => Stream.value([onlineMachine, offlineMachine]),
            ),
            deleteMachineMutationProvider.overrideWithValue((id) async {
              deleteCalled = true;
              deletedId = id;
              return true;
            }),
            connectionConfigProvider.overrideWith(
              (ref) => _DummyConnectionNotifier(const AsyncValue.data(testConfig)),
            ),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Online machine card does NOT have Dismissible wrapper
      expect(find.byKey(const Key('machine_host-uuid-1')), findsNothing);

      // Offline machine card DOES have Dismissible wrapper
      final dismissibleFinder = find.byKey(const Key('machine_host-uuid-2'));
      expect(dismissibleFinder, findsOneWidget);

      // Swipe offline card from right to left
      await tester.drag(dismissibleFinder, const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Verify confirmation dialog appeared
      expect(find.text('Delete Workstation'), findsOneWidget);
      expect(find.textContaining('Are you sure you want to unregister'), findsOneWidget);

      // Tap confirm Delete button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(deleteCalled, isTrue);
      expect(deletedId, equals('host-uuid-2'));
    });

    testWidgets(
        'Seen timestamp is hidden for online machines seen < 10s ago, but visible for >= 10s or offline',
        (tester) async {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final activelyBroadcastingMachine = GFleetSummaryData_fleetSummary(
        (b) => b
          ..machineId = 'host-active'
          ..hostname = 'active-node'
          ..status = GMachineStatus.ONLINE
          ..lastSeenTimestamp = nowSec - 2 // Seen 2s ago (< 10s)
          ..cpuUsagePercent = 20.0
          ..cpuTemperatureC = 40.0
          ..networkRxBytesPerSec = 1000.0
          ..networkTxBytesPerSec = 2000.0,
      );

      final delayedOnlineMachine = GFleetSummaryData_fleetSummary(
        (b) => b
          ..machineId = 'host-delayed'
          ..hostname = 'delayed-node'
          ..status = GMachineStatus.ONLINE
          ..lastSeenTimestamp = nowSec - 15 // Seen 15s ago (>= 10s)
          ..cpuUsagePercent = 10.0
          ..cpuTemperatureC = 38.0
          ..networkRxBytesPerSec = 500.0
          ..networkTxBytesPerSec = 500.0,
      );

      final offlineRecentMachine = GFleetSummaryData_fleetSummary(
        (b) => b
          ..machineId = 'host-offline-recent'
          ..hostname = 'offline-node'
          ..status = GMachineStatus.OFFLINE
          ..lastSeenTimestamp = nowSec - 3 // Seen 3s ago (< 10s) but offline
          ..cpuUsagePercent = 0.0
          ..cpuTemperatureC = 30.0
          ..networkRxBytesPerSec = 0.0
          ..networkTxBytesPerSec = 0.0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fleetSummaryProvider.overrideWith(
              (ref) => Stream.value([
                activelyBroadcastingMachine,
                delayedOnlineMachine,
                offlineRecentMachine,
              ]),
            ),
            connectionConfigProvider.overrideWith(
              (ref) => _DummyConnectionNotifier(const AsyncValue.data(testConfig)),
            ),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Find all Seen text widgets:
      // Should find exactly 2 widgets: for delayed-node and offline-node, NOT for active-node
      final seenFinder = find.textContaining('Seen:');
      expect(seenFinder, findsNWidgets(2));
      expect(find.textContaining('15s ago'), findsOneWidget);
    });
  });
}

class _DummyConnectionNotifier extends StateNotifier<AsyncValue<ConnectionConfig?>>
    implements ConnectionConfigNotifier {
  _DummyConnectionNotifier(super.state);

  @override
  Future<void> loadStoredConfig() async {}

  @override
  Future<void> pair(ConnectionConfig config) async {}

  @override
  Future<void> unpair() async {}
}
