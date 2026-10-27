import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../graphql/operations/__generated__/machine_metrics.data.gql.dart';

/// Card displaying CPU usage percentage and package thermal temperature.
class CpuMetricCard extends StatelessWidget {
  final GMachineMetricsData_machineMetrics_cpu cpu;

  const CpuMetricCard({super.key, required this.cpu});

  Color _loadColor(double val) {
    if (val < 60) return Colors.greenAccent;
    if (val < 85) return Colors.amberAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final usage = cpu.totalUsagePercent;
    final color = _loadColor(usage);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF1E222D),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.memory, color: Colors.cyanAccent, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'CPU & Thermals',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Spacer(),
                if (cpu.temperatureC != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.thermostat, color: Colors.orangeAccent, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          MetricFormatters.formatTemp(cpu.temperatureC),
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Utilization', style: TextStyle(color: Colors.grey, fontSize: 13)),
                Text(
                  MetricFormatters.formatPercent(usage),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (usage / 100).clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card displaying Memory consumption (used vs total) and utilization bar.
class MemoryMetricCard extends StatelessWidget {
  final GMachineMetricsData_machineMetrics_memory memory;

  const MemoryMetricCard({super.key, required this.memory});

  @override
  Widget build(BuildContext context) {
    final usedStr = MetricFormatters.formatBytes(memory.usedBytes);
    final totalStr = MetricFormatters.formatBytes(memory.totalBytes);
    final usage = memory.usagePercent;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF1E222D),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storage, color: Colors.purpleAccent, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Physical Memory (RAM)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Spacer(),
                Text(
                  MetricFormatters.formatPercent(usage),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.purpleAccent),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Allocated: $usedStr', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                Text('Total: $totalStr', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (usage / 100).clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.purpleAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card displaying live network I/O throughput (Download / Upload).
class NetworkMetricCard extends StatelessWidget {
  final GMachineMetricsData_machineMetrics_network network;

  const NetworkMetricCard({super.key, required this.network});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF1E222D),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.swap_vert, color: Colors.blueAccent, size: 22),
                SizedBox(width: 8),
                Text(
                  'Network Throughput',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.arrow_downward, color: Colors.greenAccent, size: 16),
                            SizedBox(width: 4),
                            Text('Rx (Download)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          MetricFormatters.formatRate(network.rxBytesPerSec),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.arrow_upward, color: Colors.blueAccent, size: 16),
                            SizedBox(width: 4),
                            Text('Tx (Upload)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          MetricFormatters.formatRate(network.txBytesPerSec),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Card displaying whitelisted disk partitions with mount points, fs types, and usages.
class DisksMetricCard extends StatelessWidget {
  final Iterable<GMachineMetricsData_machineMetrics_disks> disks;

  const DisksMetricCard({super.key, required this.disks});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF1E222D),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pie_chart, color: Colors.tealAccent, size: 22),
                SizedBox(width: 8),
                Text(
                  'Whitelisted Disk Partitions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (disks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No whitelisted partitions reported.', style: TextStyle(color: Colors.grey)),
              )
            else
              ...disks.map((d) {
                final usedStr = MetricFormatters.formatBytes(d.totalBytes - d.freeBytes);
                final totalStr = MetricFormatters.formatBytes(d.totalBytes);
                final usage = d.usagePercent;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            d.mountPoint,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              d.fsType.toUpperCase(),
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$usedStr / $totalStr (${MetricFormatters.formatPercent(usage)})',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (usage / 100).clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            usage > 90 ? Colors.redAccent : Colors.tealAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
