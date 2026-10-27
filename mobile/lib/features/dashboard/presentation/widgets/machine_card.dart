import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../graphql/__generated__/schema.schema.gql.dart';
import '../../../../graphql/operations/__generated__/fleet_summary.data.gql.dart';
import '../../../detail/presentation/machine_detail_screen.dart';
import 'gauge_widget.dart';

/// Interactive card widget for a workstation in the fleet summary dashboard.
/// Supports swipe-to-delete when the workstation is offline.
class MachineCard extends StatelessWidget {
  final GFleetSummaryData_fleetSummary machine;
  final Future<bool> Function(String machineId)? onDelete;

  const MachineCard({
    super.key,
    required this.machine,
    this.onDelete,
  });

  bool get isOnline => machine.status == GMachineStatus.ONLINE;

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Workstation'),
        content: Text(
          'Are you sure you want to unregister and remove "${machine.hostname}" (${machine.machineId})? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardContent = Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOnline ? Colors.cyan.withValues(alpha: 0.3) : Colors.white12,
        ),
      ),
      color: const Color(0xFF1E222D),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => MachineDetailScreen(
                machineId: machine.machineId,
                hostname: machine.hostname,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Hostname, UUID, and Status badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.computer,
                    color: isOnline ? Colors.cyanAccent : Colors.grey,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          machine.hostname,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          machine.machineId,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                            fontFamily: 'monospace',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(isOnline),
                ],
              ),
              const Divider(color: Colors.white12, height: 20),
              // Metrics Row: Gauge, Thermals, Network
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircularLoadGauge(
                    percentage: machine.cpuUsagePercent ?? 0.0,
                    size: 58,
                    strokeWidth: 5,
                    label: 'CPU',
                  ),
                  // Thermals Badge
                  _buildMetricTile(
                    icon: Icons.thermostat,
                    iconColor: Colors.orangeAccent,
                    label: 'Package Temp',
                    value: MetricFormatters.formatTemp(machine.cpuTemperatureC),
                  ),
                  // Network Throughput
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_downward, size: 14, color: Colors.greenAccent),
                          const SizedBox(width: 4),
                          Text(
                            MetricFormatters.formatRate(machine.networkRxBytesPerSec),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_upward, size: 14, color: Colors.blueAccent),
                          const SizedBox(width: 4),
                          Text(
                            MetricFormatters.formatRate(machine.networkTxBytesPerSec),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Seen: ${MetricFormatters.formatTimestamp(machine.lastSeenTimestamp)}',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // If offline, enable swipe-to-delete Dismissible
    if (!isOnline && onDelete != null) {
      return Dismissible(
        key: Key('machine_${machine.machineId}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) => _confirmDelete(context),
        onDismissed: (direction) async {
          try {
            await onDelete!(machine.machineId);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Removed workstation "${machine.hostname}"'),
                  backgroundColor: Colors.blueGrey,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deletion failed: $e'),
                  backgroundColor: Colors.red.shade700,
                ),
              );
            }
          }
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          color: Colors.red.shade900,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_forever, color: Colors.white, size: 28),
              SizedBox(width: 8),
              Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        child: cardContent,
      );
    }

    return cardContent;
  }

  Widget _buildStatusBadge(bool online) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: online ? Colors.green.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: online ? Colors.greenAccent : Colors.grey,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: online ? Colors.greenAccent : Colors.grey,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            online ? 'ONLINE' : 'OFFLINE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: online ? Colors.greenAccent : Colors.grey.shade300,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }
}
