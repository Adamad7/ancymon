import 'package:ancymon_mobile/features/detail/presentation/machine_detail_screen.dart';
import 'package:ancymon_mobile/features/detail/providers/machine_detail_providers.dart';
import 'package:ancymon_mobile/graphql/__generated__/schema.schema.gql.dart';
import 'package:ancymon_mobile/graphql/operations/__generated__/history.data.gql.dart';
import 'package:ancymon_mobile/graphql/operations/__generated__/machine_metrics.data.gql.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const testMachineId = 'test-host-uuid';
  const testHostname = 'gaming-workstation';

  final testMachineDetail = GMachineMetricsData_machineMetrics(
    (b) => b
      ..machineId = testMachineId
      ..hostname = testHostname
      ..status = GMachineStatus.ONLINE
      ..timestamp = 1700000000
      ..cpu.totalUsagePercent = 65.4
      ..cpu.temperatureC = 62.1
      ..memory.totalBytes = 34359738368.0 // 32 GB
      ..memory.usedBytes = 17179869184.0 // 16 GB
      ..memory.usagePercent = 50.0
      ..network.rxBytesPerSec = 5242880.0 // 5 MB/s
      ..network.txBytesPerSec = 1048576.0 // 1 MB/s
      ..disks.addAll([
        GMachineMetricsData_machineMetrics_disks(
          (d) => d
            ..mountPoint = '/'
            ..fsType = 'ext4'
            ..totalBytes = 1099511627776.0 // 1 TB
            ..freeBytes = 549755813888.0 // 512 GB
            ..usagePercent = 50.0,
        ),
      ]),
  );

  final testHistoricalPoints = [
    GMachineHistoryData_machineHistory((b) => b
      ..timestamp = 1700000000
      ..value = 45.0),
    GMachineHistoryData_machineHistory((b) => b
      ..timestamp = 1700000060
      ..value = 55.0),
    GMachineHistoryData_machineHistory((b) => b
      ..timestamp = 1700000120
      ..value = 65.4),
  ];

  group('MachineDetailScreen Widget Tests', () {
    testWidgets('renders all modular hardware cards and historical line chart', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            machineMetricsProvider(testMachineId).overrideWith(
              (ref) => Stream.value(testMachineDetail),
            ),
            machineHistoryProvider(testMachineId).overrideWith(
              (ref) => Future.value(testHistoricalPoints),
            ),
          ],
          child: const MaterialApp(
            home: MachineDetailScreen(
              machineId: testMachineId,
              hostname: testHostname,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text(testHostname), findsOneWidget);
      expect(find.text(testMachineId), findsOneWidget);

      // Verify CPU & Thermals Card
      expect(find.text('CPU & Thermals'), findsOneWidget);
      expect(find.text('65.4%'), findsWidgets); // Used in CPU card and chart
      expect(find.text('62.1°C'), findsOneWidget);

      // Verify Memory Card
      expect(find.text('Physical Memory (RAM)'), findsOneWidget);
      expect(find.text('Allocated: 16.0 GB'), findsOneWidget);
      expect(find.text('Total: 32.0 GB'), findsOneWidget);

      // Verify Network Throughput Card
      expect(find.text('Network Throughput'), findsOneWidget);
      expect(find.text('5.0 MB/s'), findsOneWidget);
      expect(find.text('1.0 MB/s'), findsOneWidget);

      // Scroll down to bring HistoricalChartCard and LineChart into viewport
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Verify LineChart rendering
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('allows toggling time range chips and metric filter chips', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            machineMetricsProvider(testMachineId).overrideWith(
              (ref) => Stream.value(testMachineDetail),
            ),
            machineHistoryProvider(testMachineId).overrideWith(
              (ref) => Future.value(testHistoricalPoints),
            ),
          ],
          child: const MaterialApp(
            home: MachineDetailScreen(
              machineId: testMachineId,
              hostname: testHostname,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to chart if needed
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      // Check Time range chips exist: 1h, 6h, 12h, 24h, 3d, 7d
      expect(find.widgetWithText(ChoiceChip, '1h'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, '6h'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, '24h'), findsOneWidget);

      // Tap '6h' chip
      await tester.tap(find.widgetWithText(ChoiceChip, '6h'));
      await tester.pumpAndSettle();

      // Tap 'RAM Usage' metric chip
      expect(find.widgetWithText(ChoiceChip, 'RAM Usage'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'RAM Usage'));
      await tester.pumpAndSettle();

      // Verify LineChart is still active and rendered
      expect(find.byType(LineChart), findsOneWidget);
    });
  });
}
