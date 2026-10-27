// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:ancymon_mobile/graphql/__generated__/serializers.gql.dart'
    as _i1;
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'history.data.gql.g.dart';

abstract class GMachineHistoryData
    implements Built<GMachineHistoryData, GMachineHistoryDataBuilder> {
  GMachineHistoryData._();

  factory GMachineHistoryData(
          [void Function(GMachineHistoryDataBuilder b) updates]) =
      _$GMachineHistoryData;

  static void _initializeBuilder(GMachineHistoryDataBuilder b) =>
      b..G__typename = 'Query';

  @BuiltValueField(wireName: '__typename')
  String get G__typename;
  BuiltList<GMachineHistoryData_machineHistory> get machineHistory;
  static Serializer<GMachineHistoryData> get serializer =>
      _$gMachineHistoryDataSerializer;

  Map<String, dynamic> toJson() => (_i1.serializers.serializeWith(
        GMachineHistoryData.serializer,
        this,
      ) as Map<String, dynamic>);

  static GMachineHistoryData? fromJson(Map<String, dynamic> json) =>
      _i1.serializers.deserializeWith(
        GMachineHistoryData.serializer,
        json,
      );
}

abstract class GMachineHistoryData_machineHistory
    implements
        Built<GMachineHistoryData_machineHistory,
            GMachineHistoryData_machineHistoryBuilder> {
  GMachineHistoryData_machineHistory._();

  factory GMachineHistoryData_machineHistory(
      [void Function(GMachineHistoryData_machineHistoryBuilder b)
          updates]) = _$GMachineHistoryData_machineHistory;

  static void _initializeBuilder(GMachineHistoryData_machineHistoryBuilder b) =>
      b..G__typename = 'HistoricalPoint';

  @BuiltValueField(wireName: '__typename')
  String get G__typename;
  int get timestamp;
  double get value;
  static Serializer<GMachineHistoryData_machineHistory> get serializer =>
      _$gMachineHistoryDataMachineHistorySerializer;

  Map<String, dynamic> toJson() => (_i1.serializers.serializeWith(
        GMachineHistoryData_machineHistory.serializer,
        this,
      ) as Map<String, dynamic>);

  static GMachineHistoryData_machineHistory? fromJson(
          Map<String, dynamic> json) =>
      _i1.serializers.deserializeWith(
        GMachineHistoryData_machineHistory.serializer,
        json,
      );
}
