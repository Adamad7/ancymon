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

part 'fleet_summary.data.gql.g.dart';

abstract class GFleetSummaryData
    implements Built<GFleetSummaryData, GFleetSummaryDataBuilder> {
  GFleetSummaryData._();

  factory GFleetSummaryData(
          [void Function(GFleetSummaryDataBuilder b) updates]) =
      _$GFleetSummaryData;

  static void _initializeBuilder(GFleetSummaryDataBuilder b) =>
      b..G__typename = 'Subscription';

  @BuiltValueField(wireName: '__typename')
  String get G__typename;
  BuiltList<GFleetSummaryData_fleetSummary> get fleetSummary;
  static Serializer<GFleetSummaryData> get serializer =>
      _$gFleetSummaryDataSerializer;

  Map<String, dynamic> toJson() => (_i1.serializers.serializeWith(
        GFleetSummaryData.serializer,
        this,
      ) as Map<String, dynamic>);

  static GFleetSummaryData? fromJson(Map<String, dynamic> json) =>
      _i1.serializers.deserializeWith(
        GFleetSummaryData.serializer,
        json,
      );
}

abstract class GFleetSummaryData_fleetSummary
    implements
        Built<GFleetSummaryData_fleetSummary,
            GFleetSummaryData_fleetSummaryBuilder> {
  GFleetSummaryData_fleetSummary._();

  factory GFleetSummaryData_fleetSummary(
          [void Function(GFleetSummaryData_fleetSummaryBuilder b) updates]) =
      _$GFleetSummaryData_fleetSummary;

  static void _initializeBuilder(GFleetSummaryData_fleetSummaryBuilder b) =>
      b..G__typename = 'MachineSummary';

  @BuiltValueField(wireName: '__typename')
  String get G__typename;
  String get machineId;
  String get hostname;
  _i2.GMachineStatus get status;
  int get lastSeenTimestamp;
  double? get cpuUsagePercent;
  double? get cpuTemperatureC;
  double? get networkRxBytesPerSec;
  double? get networkTxBytesPerSec;
  static Serializer<GFleetSummaryData_fleetSummary> get serializer =>
      _$gFleetSummaryDataFleetSummarySerializer;

  Map<String, dynamic> toJson() => (_i1.serializers.serializeWith(
        GFleetSummaryData_fleetSummary.serializer,
        this,
      ) as Map<String, dynamic>);

  static GFleetSummaryData_fleetSummary? fromJson(Map<String, dynamic> json) =>
      _i1.serializers.deserializeWith(
        GFleetSummaryData_fleetSummary.serializer,
        json,
      );
}
