import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/connection_provider.dart';
import '../../../graphql/__generated__/schema.schema.gql.dart';
import '../../../graphql/operations/__generated__/history.data.gql.dart';
import '../../../graphql/operations/__generated__/history.req.gql.dart';
import '../../../graphql/operations/__generated__/machine_metrics.data.gql.dart';
import '../../../graphql/operations/__generated__/machine_metrics.req.gql.dart';

/// StreamProvider binding the 1 Hz GraphQL machineMetrics subscription for a specific host.
final machineMetricsProvider = StreamProvider.family
    .autoDispose<GMachineMetricsData_machineMetrics, String>((ref, machineId) {
  final client = ref.watch(ferryClientProvider);
  if (client == null) {
    return const Stream.empty();
  }

  final req = GMachineMetricsReq(
    (b) => b..vars.machineId = machineId,
  );

  return client.request(req).map((response) {
    if (response.hasErrors) {
      final msg = response.graphqlErrors?.isNotEmpty == true
          ? response.graphqlErrors!.first.message
          : 'Failed to receive machine metrics';
      throw Exception(msg);
    }
    final detail = response.data?.machineMetrics;
    if (detail == null) {
      throw Exception('Workstation telemetry unavailable');
    }
    return detail;
  });
});

/// Immutable filter model for historical metrics queries.
class HistoryFilter {
  final GMetricType metric;
  final GTimeRange range;
  final DateTime? customDate;

  const HistoryFilter({
    this.metric = GMetricType.CPU_USAGE,
    this.range = GTimeRange.RANGE_1H,
    this.customDate,
  });

  HistoryFilter copyWith({
    GMetricType? metric,
    GTimeRange? range,
    DateTime? customDate,
  }) {
    return HistoryFilter(
      metric: metric ?? this.metric,
      range: range ?? this.range,
      customDate: customDate ?? this.customDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryFilter &&
          runtimeType == other.runtimeType &&
          metric == other.metric &&
          range == other.range &&
          customDate == other.customDate;

  @override
  int get hashCode => Object.hash(metric, range, customDate);
}

/// Provider managing active historical chart filters per machine.
final historyFilterProvider =
    StateProvider.family<HistoryFilter, String>((ref, machineId) {
  return const HistoryFilter();
});

/// FutureProvider querying downsampled historical points from VictoriaMetrics via GraphQL.
final machineHistoryProvider = FutureProvider.family
    .autoDispose<List<GMachineHistoryData_machineHistory>, String>((ref, machineId) async {
  final client = ref.watch(ferryClientProvider);
  if (client == null) return [];

  final filter = ref.watch(historyFilterProvider(machineId));
  final dateStr = filter.range == GTimeRange.CUSTOM_DATE && filter.customDate != null
      ? DateFormat('yyyy-MM-dd').format(filter.customDate!)
      : null;

  final req = GMachineHistoryReq(
    (b) => b
      ..vars.machineId = machineId
      ..vars.metric = filter.metric
      ..vars.range = filter.range
      ..vars.date = dateStr,
  );

  final response = await client.request(req).first;
  if (response.hasErrors) {
    final msg = response.graphqlErrors?.isNotEmpty == true
        ? response.graphqlErrors!.first.message
        : 'Failed to fetch historical telemetry';
    throw Exception(msg);
  }

  final points = response.data?.machineHistory;
  return points != null ? points.toList() : <GMachineHistoryData_machineHistory>[];
});
