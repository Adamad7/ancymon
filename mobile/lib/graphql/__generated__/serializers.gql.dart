// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:ancymon_mobile/graphql/__generated__/schema.schema.gql.dart'
    show GMachineStatus, GMetricType, GTimeRange;
import 'package:ancymon_mobile/graphql/operations/__generated__/delete_machine.data.gql.dart'
    show GDeleteMachineData;
import 'package:ancymon_mobile/graphql/operations/__generated__/delete_machine.req.gql.dart'
    show GDeleteMachineReq;
import 'package:ancymon_mobile/graphql/operations/__generated__/delete_machine.var.gql.dart'
    show GDeleteMachineVars;
import 'package:ancymon_mobile/graphql/operations/__generated__/fleet_summary.data.gql.dart'
    show GFleetSummaryData, GFleetSummaryData_fleetSummary;
import 'package:ancymon_mobile/graphql/operations/__generated__/fleet_summary.req.gql.dart'
    show GFleetSummaryReq;
import 'package:ancymon_mobile/graphql/operations/__generated__/fleet_summary.var.gql.dart'
    show GFleetSummaryVars;
import 'package:ancymon_mobile/graphql/operations/__generated__/history.data.gql.dart'
    show GMachineHistoryData, GMachineHistoryData_machineHistory;
import 'package:ancymon_mobile/graphql/operations/__generated__/history.req.gql.dart'
    show GMachineHistoryReq;
import 'package:ancymon_mobile/graphql/operations/__generated__/history.var.gql.dart'
    show GMachineHistoryVars;
import 'package:ancymon_mobile/graphql/operations/__generated__/machine_metrics.data.gql.dart'
    show
        GMachineMetricsData,
        GMachineMetricsData_machineMetrics,
        GMachineMetricsData_machineMetrics_cpu,
        GMachineMetricsData_machineMetrics_disks,
        GMachineMetricsData_machineMetrics_memory,
        GMachineMetricsData_machineMetrics_network;
import 'package:ancymon_mobile/graphql/operations/__generated__/machine_metrics.req.gql.dart'
    show GMachineMetricsReq;
import 'package:ancymon_mobile/graphql/operations/__generated__/machine_metrics.var.gql.dart'
    show GMachineMetricsVars;
import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart' show StandardJsonPlugin;
import 'package:ferry_exec/ferry_exec.dart';
import 'package:gql_code_builder_serializers/gql_code_builder_serializers.dart'
    show OperationSerializer;

part 'serializers.gql.g.dart';

final SerializersBuilder _serializersBuilder = _$serializers.toBuilder()
  ..add(OperationSerializer())
  ..addPlugin(StandardJsonPlugin());
@SerializersFor([
  GDeleteMachineData,
  GDeleteMachineReq,
  GDeleteMachineVars,
  GFleetSummaryData,
  GFleetSummaryData_fleetSummary,
  GFleetSummaryReq,
  GFleetSummaryVars,
  GMachineHistoryData,
  GMachineHistoryData_machineHistory,
  GMachineHistoryReq,
  GMachineHistoryVars,
  GMachineMetricsData,
  GMachineMetricsData_machineMetrics,
  GMachineMetricsData_machineMetrics_cpu,
  GMachineMetricsData_machineMetrics_disks,
  GMachineMetricsData_machineMetrics_memory,
  GMachineMetricsData_machineMetrics_network,
  GMachineMetricsReq,
  GMachineMetricsVars,
  GMachineStatus,
  GMetricType,
  GTimeRange,
])
final Serializers serializers = _serializersBuilder.build();
