// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:ancymon_mobile/graphql/__generated__/schema.schema.gql.dart'
    as _i2;
import 'package:ancymon_mobile/graphql/__generated__/serializers.gql.dart'
    as _i1;
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'machine_metrics.data.gql.g.dart';

abstract class GMachineMetricsData
    implements Built<GMachineMetricsData, GMachineMetricsDataBuilder> {
  GMachineMetricsData._();

  factory GMachineMetricsData(
          [void Function(GMachineMetricsDataBuilder b) updates]) =
      _$GMachineMetricsData;

  static void _initializeBuilder(GMachineMetricsDataBuilder b) =>
      b..G__typename = 'Subscription';

  @BuiltValueField(wireName: '__typename')
  String get G__typename;
  GMachineMetricsData_machineMetrics get machineMetrics;
  static Serializer<GMachineMetricsData> get serializer =>
      _$gMachineMetricsDataSerializer;

  Map<String, dynamic> toJson() => (_i1.serializers.serializeWith(
        GMachineMetricsData.serializer,
        this,
      ) as Map<String, dynamic>);

  static GMachineMetricsData? fromJson(Map<String, dynamic> json) =>
      _i1.serializers.deserializeWith(
        GMachineMetricsData.serializer,
        json,
      );
}

abstract class GMachineMetricsData_machineMetrics
    implements
        Built<GMachineMetricsData_machineMetrics,
            GMachineMetricsData_machineMetricsBuilder> {
  GMachineMetricsData_machineMetrics._();

  factory GMachineMetricsData_machineMetrics(
      [void Function(GMachineMetricsData_machineMetricsBuilder b)
          updates]) = _$GMachineMetricsData_machineMetrics;

  static void _initializeBuilder(GMachineMetricsData_machineMetricsBuilder b) =>
      b..G__typename = 'MachineDetail';

  @BuiltValueField(wireName: '__typename')
  String get G__typename;
  String get machineId;
  String get hostname;
  _i2.GMachineStatus get status;
  int get timestamp;
  GMachineMetricsData_machineMetrics_cpu get cpu;
  GMachineMetricsData_machineMetrics_memory get memory;
  GMachineMetricsData_machineMetrics_network get network;
  BuiltList<GMachineMetricsData_machineMetrics_disks> get disks;
  static Serializer<GMachineMetricsData_machineMetrics> get serializer =>
      _$gMachineMetricsDataMachineMetricsSerializer;

  Map<String, dynamic> toJson() => (_i1.serializers.serializeWith(
        GMachineMetricsData_machineMetrics.serializer,
        this,
      ) as Map<String, dynamic>);

  static GMachineMetricsData_machineMetrics? fromJson(
          Map<String, dynamic> json) =>
      _i1.serializers.deserializeWith(
        GMachineMetricsData_machineMetrics.serializer,
        json,
      );
}

abstract class GMachineMetricsData_machineMetrics_cpu
    implements
        Built<GMachineMetricsData_machineMetrics_cpu,
            GMachineMetricsData_machineMetrics_cpuBuilder> {
  GMachineMetricsData_machineMetrics_cpu._();

  factory GMachineMetricsData_machineMetrics_cpu(
      [void Function(GMachineMetricsData_machineMetrics_cpuBuilder b)
          updates]) = _$GMachineMetricsData_machineMetrics_cpu;

  static void _initializeBuilder(
          GMachineMetricsData_machineMetrics_cpuBuilder b) =>
      b..G__typename = 'DetailedCpuMetrics';

  @BuiltValueField(wireName: '__typename')
  String get G__typename;
  double get totalUsagePercent;
  double? get temperatureC;
  static Serializer<GMachineMetricsData_machineMetrics_cpu> get serializer =>
      _$gMachineMetricsDataMachineMetricsCpuSerializer;

  Map<String, dynamic> toJson() => (_i1.serializers.serializeWith(
        GMachineMetricsData_machineMetrics_cpu.serializer,
        this,
      ) as Map<String, dynamic>);

  static GMachineMetricsData_machineMetrics_cpu? fromJson(
          Map<String, dynamic> json) =>
      _i1.serializers.deserializeWith(
        GMachineMetricsData_machineMetrics_cpu.serializer,
        json,
      );
}

abstract class GMachineMetricsData_machineMetrics_memory
    implements
        Built<GMachineMetricsData_machineMetrics_memory,
            GMachineMetricsData_machineMetrics_memoryBuilder> {
  GMachineMetricsData_machineMetrics_memory._();

  factory GMachineMetricsData_machineMetrics_memory(
      [void Function(GMachineMetricsData_machineMetrics_memoryBuilder b)
          updates]) = _$GMachineMetricsData_machineMetrics_memory;

  static void _initializeBuilder(
          GMachineMetricsData_machineMetrics_memoryBuilder b) =>
      b..G__typename = 'DetailedMemoryMetrics';

  @BuiltValueField(wireName: '__typename')
  String get G__typename;
  double get totalBytes;
  double get usedBytes;
  double get usagePercent;
  static Serializer<GMachineMetricsData_machineMetrics_memory> get serializer =>
      _$gMachineMetricsDataMachineMetricsMemorySerializer;

  Map<String, dynamic> toJson() => (_i1.serializers.serializeWith(
        GMachineMetricsData_machineMetrics_memory.serializer,
        this,
      ) as Map<String, dynamic>);

  static GMachineMetricsData_machineMetrics_memory? fromJson(
          Map<String, dynamic> json) =>
      _i1.serializers.deserializeWith(
        GMachineMetricsData_machineMetrics_memory.serializer,
        json,
      );
}

abstract class GMachineMetricsData_machineMetrics_network
    implements
        Built<GMachineMetricsData_machineMetrics_network,
            GMachineMetricsData_machineMetrics_networkBuilder> {
  GMachineMetricsData_machineMetrics_network._();

  factory GMachineMetricsData_machineMetrics_network(
      [void Function(GMachineMetricsData_machineMetrics_networkBuilder b)
          updates]) = _$GMachineMetricsData_machineMetrics_network;

  static void _initializeBuilder(
          GMachineMetricsData_machineMetrics_networkBuilder b) =>
      b..G__typename = 'DetailedNetworkMetrics';

  @BuiltValueField(wireName: '__typename')
  String get G__typename;
  double get rxBytesPerSec;
  double get txBytesPerSec;
  static Serializer<GMachineMetricsData_machineMetrics_network>
      get serializer => _$gMachineMetricsDataMachineMetricsNetworkSerializer;

  Map<String, dynamic> toJson() => (_i1.serializers.serializeWith(
        GMachineMetricsData_machineMetrics_network.serializer,
        this,
      ) as Map<String, dynamic>);

  static GMachineMetricsData_machineMetrics_network? fromJson(
          Map<String, dynamic> json) =>
      _i1.serializers.deserializeWith(
        GMachineMetricsData_machineMetrics_network.serializer,
        json,
      );
}

abstract class GMachineMetricsData_machineMetrics_disks
    implements
        Built<GMachineMetricsData_machineMetrics_disks,
            GMachineMetricsData_machineMetrics_disksBuilder> {
  GMachineMetricsData_machineMetrics_disks._();

  factory GMachineMetricsData_machineMetrics_disks(
      [void Function(GMachineMetricsData_machineMetrics_disksBuilder b)
          updates]) = _$GMachineMetricsData_machineMetrics_disks;

  static void _initializeBuilder(
          GMachineMetricsData_machineMetrics_disksBuilder b) =>
      b..G__typename = 'DiskPartitionInfo';

  @BuiltValueField(wireName: '__typename')
  String get G__typename;
  String get mountPoint;
  String get fsType;
  double get totalBytes;
  double get freeBytes;
  double get usagePercent;
  static Serializer<GMachineMetricsData_machineMetrics_disks> get serializer =>
      _$gMachineMetricsDataMachineMetricsDisksSerializer;

  Map<String, dynamic> toJson() => (_i1.serializers.serializeWith(
        GMachineMetricsData_machineMetrics_disks.serializer,
        this,
      ) as Map<String, dynamic>);

  static GMachineMetricsData_machineMetrics_disks? fromJson(
          Map<String, dynamic> json) =>
      _i1.serializers.deserializeWith(
        GMachineMetricsData_machineMetrics_disks.serializer,
        json,
      );
}
