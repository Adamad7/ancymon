// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'schema.schema.gql.g.dart';

class GMetricType extends EnumClass {
  const GMetricType._(String name) : super(name);

  static const GMetricType CPU_USAGE = _$gMetricTypeCPU_USAGE;

  static const GMetricType CPU_TEMP = _$gMetricTypeCPU_TEMP;

  static const GMetricType MEMORY_USAGE = _$gMetricTypeMEMORY_USAGE;

  static const GMetricType NETWORK_RX = _$gMetricTypeNETWORK_RX;

  static const GMetricType NETWORK_TX = _$gMetricTypeNETWORK_TX;

  static const GMetricType DISK_USAGE = _$gMetricTypeDISK_USAGE;

  static Serializer<GMetricType> get serializer => _$gMetricTypeSerializer;

  static BuiltSet<GMetricType> get values => _$gMetricTypeValues;

  static GMetricType valueOf(String name) => _$gMetricTypeValueOf(name);
}

class GTimeRange extends EnumClass {
  const GTimeRange._(String name) : super(name);

  static const GTimeRange RANGE_1H = _$gTimeRangeRANGE_1H;

  static const GTimeRange RANGE_6H = _$gTimeRangeRANGE_6H;

  static const GTimeRange RANGE_12H = _$gTimeRangeRANGE_12H;

  static const GTimeRange RANGE_24H = _$gTimeRangeRANGE_24H;

  static const GTimeRange RANGE_3D = _$gTimeRangeRANGE_3D;

  static const GTimeRange RANGE_7D = _$gTimeRangeRANGE_7D;

  static const GTimeRange CUSTOM_DATE = _$gTimeRangeCUSTOM_DATE;

  static Serializer<GTimeRange> get serializer => _$gTimeRangeSerializer;

  static BuiltSet<GTimeRange> get values => _$gTimeRangeValues;

  static GTimeRange valueOf(String name) => _$gTimeRangeValueOf(name);
}

class GMachineStatus extends EnumClass {
  const GMachineStatus._(String name) : super(name);

  static const GMachineStatus ONLINE = _$gMachineStatusONLINE;

  static const GMachineStatus OFFLINE = _$gMachineStatusOFFLINE;

  static Serializer<GMachineStatus> get serializer =>
      _$gMachineStatusSerializer;

  static BuiltSet<GMachineStatus> get values => _$gMachineStatusValues;

  static GMachineStatus valueOf(String name) => _$gMachineStatusValueOf(name);
}

const Map<String, Set<String>> possibleTypesMap = {};
