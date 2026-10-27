import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../graphql/__generated__/schema.schema.gql.dart';
import '../../providers/machine_detail_providers.dart';

/// Interactive hardware-accelerated time-series chart component powered by fl_chart.
class HistoricalChartCard extends ConsumerWidget {
  final String machineId;

  const HistoricalChartCard({super.key, required this.machineId});

  String _formatMetricLabel(GMetricType metric) {
    switch (metric) {
      case GMetricType.CPU_USAGE:
        return 'CPU Usage';
      case GMetricType.CPU_TEMP:
        return 'CPU Temp';
      case GMetricType.MEMORY_USAGE:
        return 'RAM Usage';
      case GMetricType.NETWORK_RX:
        return 'Network Rx';
      case GMetricType.NETWORK_TX:
        return 'Network Tx';
      case GMetricType.DISK_USAGE:
        return 'Disk Usage';
      default:
        return metric.name;
    }
  }

  String _formatValueForMetric(GMetricType metric, double val) {
    switch (metric) {
      case GMetricType.CPU_USAGE:
      case GMetricType.MEMORY_USAGE:
      case GMetricType.DISK_USAGE:
        return '${val.toStringAsFixed(1)}%';
      case GMetricType.CPU_TEMP:
        return '${val.toStringAsFixed(1)}°C';
      case GMetricType.NETWORK_RX:
      case GMetricType.NETWORK_TX:
        return MetricFormatters.formatRate(val);
      default:
        return val.toStringAsFixed(1);
    }
  }

  Color _colorForMetric(GMetricType metric) {
    switch (metric) {
      case GMetricType.CPU_USAGE:
        return Colors.cyanAccent;
      case GMetricType.CPU_TEMP:
        return Colors.orangeAccent;
      case GMetricType.MEMORY_USAGE:
        return Colors.purpleAccent;
      case GMetricType.NETWORK_RX:
        return Colors.greenAccent;
      case GMetricType.NETWORK_TX:
        return Colors.blueAccent;
      case GMetricType.DISK_USAGE:
        return Colors.tealAccent;
      default:
        return Colors.cyanAccent;
    }
  }

  Future<void> _pickCustomDate(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
    );
    if (picked != null) {
      ref.read(historyFilterProvider(machineId).notifier).update(
            (f) => f.copyWith(
              range: GTimeRange.CUSTOM_DATE,
              customDate: picked,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(historyFilterProvider(machineId));
    final historyAsync = ref.watch(machineHistoryProvider(machineId));
    final chartColor = _colorForMetric(filter.metric);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF1E222D),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Active Range
            Row(
              children: [
                Icon(Icons.show_chart, color: chartColor, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Historical Telemetry',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Metric Selector Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  GMetricType.CPU_USAGE,
                  GMetricType.CPU_TEMP,
                  GMetricType.MEMORY_USAGE,
                  GMetricType.NETWORK_RX,
                  GMetricType.NETWORK_TX,
                  GMetricType.DISK_USAGE,
                ].map((m) {
                  final selected = filter.metric == m;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        _formatMetricLabel(m),
                        style: TextStyle(
                          fontSize: 12,
                          color: selected ? Colors.black : Colors.white70,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: selected,
                      selectedColor: chartColor,
                      backgroundColor: Colors.black26,
                      onSelected: (val) {
                        if (val) {
                          ref.read(historyFilterProvider(machineId).notifier).update(
                                (f) => f.copyWith(metric: m),
                              );
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),

            // Time Range Selector Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTimeChip(ref, '1h', GTimeRange.RANGE_1H, filter),
                  _buildTimeChip(ref, '6h', GTimeRange.RANGE_6H, filter),
                  _buildTimeChip(ref, '12h', GTimeRange.RANGE_12H, filter),
                  _buildTimeChip(ref, '24h', GTimeRange.RANGE_24H, filter),
                  _buildTimeChip(ref, '3d', GTimeRange.RANGE_3D, filter),
                  _buildTimeChip(ref, '7d', GTimeRange.RANGE_7D, filter),
                  // Custom Date Chip / Picker
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: const Icon(Icons.calendar_month, size: 16),
                      label: Text(
                        filter.range == GTimeRange.CUSTOM_DATE && filter.customDate != null
                            ? DateFormat('MM-dd').format(filter.customDate!)
                            : 'Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: filter.range == GTimeRange.CUSTOM_DATE
                              ? Colors.cyanAccent
                              : Colors.white70,
                        ),
                      ),
                      backgroundColor: filter.range == GTimeRange.CUSTOM_DATE
                          ? Colors.cyan.withValues(alpha: 0.2)
                          : Colors.black26,
                      onPressed: () => _pickCustomDate(context, ref),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Chart Canvas Container
            SizedBox(
              height: 220,
              child: historyAsync.when(
                data: (points) {
                  if (points.isEmpty) {
                    return const Center(
                      child: Text(
                        'No historical metrics recorded for this time range.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    );
                  }

                  // Build spots mapping index to value
                  final spots = <FlSpot>[];
                  double minY = points.first.value;
                  double maxY = points.first.value;

                  for (var i = 0; i < points.length; i++) {
                    final val = points[i].value;
                    spots.add(FlSpot(i.toDouble(), val));
                    if (val < minY) minY = val;
                    if (val > maxY) maxY = val;
                  }

                  // Provide minimum headroom on Y-axis
                  if (minY == maxY) {
                    minY = (minY * 0.8).clamp(0.0, double.infinity);
                    maxY = (maxY * 1.2).clamp(1.0, double.infinity);
                  }

                  return LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (points.length - 1).toDouble(),
                      minY: minY >= 0 ? 0 : minY,
                      maxY: maxY * 1.05,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => const FlLine(
                          color: Colors.white10,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            getTitlesWidget: (val, meta) {
                              if (val == meta.max || val == meta.min) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                _formatValueForMetric(filter.metric, val),
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 26,
                            interval: (points.length / 4).clamp(1.0, double.infinity),
                            getTitlesWidget: (val, meta) {
                              final idx = val.toInt();
                              if (idx < 0 || idx >= points.length) {
                                return const SizedBox.shrink();
                              }
                              final ts = points[idx].timestamp;
                              final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
                              return Text(
                                DateFormat('HH:mm').format(dt),
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        handleBuiltInTouches: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (spot) => const Color(0xFF2B303C),
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final idx = spot.x.toInt();
                              final ts = idx < points.length ? points[idx].timestamp : 0;
                              final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
                              final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
                              final valStr = _formatValueForMetric(filter.metric, spot.y);
                              return LineTooltipItem(
                                '$timeStr\n$valStr',
                                TextStyle(
                                  color: chartColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.2,
                          color: chartColor,
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: chartColor.withValues(alpha: 0.15),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 28),
                      const SizedBox(height: 6),
                      Text('Error loading chart: $e', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeChip(
    WidgetRef ref,
    String label,
    GTimeRange range,
    HistoryFilter currentFilter,
  ) {
    final selected = currentFilter.range == range;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.black : Colors.white70,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: selected,
        selectedColor: Colors.white,
        backgroundColor: Colors.black26,
        onSelected: (val) {
          if (val) {
            ref.read(historyFilterProvider(machineId).notifier).update(
                  (f) => f.copyWith(range: range),
                );
          }
        },
      ),
    );
  }
}
