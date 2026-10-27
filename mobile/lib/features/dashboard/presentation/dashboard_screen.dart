import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/connection_provider.dart';
import '../../../../graphql/__generated__/schema.schema.gql.dart';
import '../providers/fleet_summary_provider.dart';
import 'widgets/machine_card.dart';

/// Main Fleet Dashboard displaying live statuses for all registered workstations.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _showUnpairDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect from Server'),
        content: const Text(
          'Are you sure you want to disconnect? All saved connection tokens and certificates will be removed from secure storage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(connectionConfigProvider.notifier).unpair();
            },
            child: const Text('Disconnect', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fleetAsync = ref.watch(fleetSummaryProvider);
    final deleteMachine = ref.watch(deleteMachineMutationProvider);
    final config = ref.watch(connectionConfigProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AncyMon Fleet',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
            ),
            if (config != null)
              Text(
                'Connected to ${config.ip}:${config.port}',
                style: const TextStyle(fontSize: 11, color: Colors.cyanAccent),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.link_off),
            tooltip: 'Unpair & Disconnect',
            onPressed: () => _showUnpairDialog(context, ref),
          ),
        ],
      ),
      body: fleetAsync.when(
        data: (machines) {
          if (machines.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.devices_other, size: 64, color: Colors.grey.shade600),
                  const SizedBox(height: 16),
                  const Text(
                    'No Workstations Discovered Yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ensure ancymon-agent is running on your LAN hosts.',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          // Sort ONLINE machines first, then alphabetically by hostname
          final sorted = machines.toList()
            ..sort((a, b) {
              if (a.status == GMachineStatus.ONLINE && b.status != GMachineStatus.ONLINE) return -1;
              if (a.status != GMachineStatus.ONLINE && b.status == GMachineStatus.ONLINE) return 1;
              return a.hostname.compareTo(b.hostname);
            });

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(fleetSummaryProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final machine = sorted[index];
                return MachineCard(
                  key: ValueKey(machine.machineId),
                  machine: machine,
                  onDelete: deleteMachine,
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Connecting to Fleet Telemetry Stream...'),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 54, color: Colors.redAccent),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load fleet summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(fleetSummaryProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Connection'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
