import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../graphql/__generated__/schema.schema.gql.dart';
import '../providers/machine_detail_providers.dart';
import 'widgets/historical_chart.dart';
import 'widgets/metric_card.dart';

/// Detailed live hardware telemetry and historical analytics view for a monitored workstation.
class MachineDetailScreen extends ConsumerWidget {
  final String machineId;
  final String hostname;

  const MachineDetailScreen({
    super.key,
    required this.machineId,
    required this.hostname,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(machineMetricsProvider(machineId));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(hostname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              machineId,
              style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          detailAsync.maybeWhen(
            data: (detail) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: detail.status == GMachineStatus.ONLINE
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: detail.status == GMachineStatus.ONLINE
                          ? Colors.greenAccent
                          : Colors.grey,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: detail.status == GMachineStatus.ONLINE
                              ? Colors.greenAccent
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        detail.status.name,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: detail.status == GMachineStatus.ONLINE
                              ? Colors.greenAccent
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: detailAsync.when(
        data: (detail) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(machineMetricsProvider(machineId));
              ref.invalidate(machineHistoryProvider(machineId));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Real-time CPU Card
                CpuMetricCard(cpu: detail.cpu),
                const SizedBox(height: 12),

                // Real-time RAM Card
                MemoryMetricCard(memory: detail.memory),
                const SizedBox(height: 12),

                // Real-time Network Throughput Card
                NetworkMetricCard(network: detail.network),
                const SizedBox(height: 12),

                // Whitelisted Disks Card
                DisksMetricCard(disks: detail.disks),
                const SizedBox(height: 16),

                // Historical Line Chart with Filters
                HistoricalChartCard(machineId: machineId),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Subscribing to 1 Hz live telemetry...'),
            ],
          ),
        ),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.signal_wifi_off, size: 52, color: Colors.redAccent),
                const SizedBox(height: 16),
                const Text(
                  'Workstation Connection Lost',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(machineMetricsProvider(machineId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reconnect'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
