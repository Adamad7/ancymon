// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schema.schema.gql.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const GMetricType _$gMetricTypeCPU_USAGE = const GMetricType._('CPU_USAGE');
const GMetricType _$gMetricTypeCPU_TEMP = const GMetricType._('CPU_TEMP');
const GMetricType _$gMetricTypeMEMORY_USAGE =
    const GMetricType._('MEMORY_USAGE');
const GMetricType _$gMetricTypeNETWORK_RX = const GMetricType._('NETWORK_RX');
const GMetricType _$gMetricTypeNETWORK_TX = const GMetricType._('NETWORK_TX');
const GMetricType _$gMetricTypeDISK_USAGE = const GMetricType._('DISK_USAGE');

GMetricType _$gMetricTypeValueOf(String name) {
  switch (name) {
    case 'CPU_USAGE':
      return _$gMetricTypeCPU_USAGE;
    case 'CPU_TEMP':
      return _$gMetricTypeCPU_TEMP;
    case 'MEMORY_USAGE':
      return _$gMetricTypeMEMORY_USAGE;
    case 'NETWORK_RX':
      return _$gMetricTypeNETWORK_RX;
    case 'NETWORK_TX':
      return _$gMetricTypeNETWORK_TX;
    case 'DISK_USAGE':
      return _$gMetricTypeDISK_USAGE;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<GMetricType> _$gMetricTypeValues =
    new BuiltSet<GMetricType>(const <GMetricType>[
  _$gMetricTypeCPU_USAGE,
  _$gMetricTypeCPU_TEMP,
  _$gMetricTypeMEMORY_USAGE,
  _$gMetricTypeNETWORK_RX,
  _$gMetricTypeNETWORK_TX,
  _$gMetricTypeDISK_USAGE,
]);

const GTimeRange _$gTimeRangeRANGE_1H = const GTimeRange._('RANGE_1H');
const GTimeRange _$gTimeRangeRANGE_6H = const GTimeRange._('RANGE_6H');
const GTimeRange _$gTimeRangeRANGE_12H = const GTimeRange._('RANGE_12H');
const GTimeRange _$gTimeRangeRANGE_24H = const GTimeRange._('RANGE_24H');
const GTimeRange _$gTimeRangeRANGE_3D = const GTimeRange._('RANGE_3D');
const GTimeRange _$gTimeRangeRANGE_7D = const GTimeRange._('RANGE_7D');
const GTimeRange _$gTimeRangeCUSTOM_DATE = const GTimeRange._('CUSTOM_DATE');

GTimeRange _$gTimeRangeValueOf(String name) {
  switch (name) {
    case 'RANGE_1H':
      return _$gTimeRangeRANGE_1H;
    case 'RANGE_6H':
      return _$gTimeRangeRANGE_6H;
    case 'RANGE_12H':
      return _$gTimeRangeRANGE_12H;
    case 'RANGE_24H':
      return _$gTimeRangeRANGE_24H;
    case 'RANGE_3D':
      return _$gTimeRangeRANGE_3D;
    case 'RANGE_7D':
      return _$gTimeRangeRANGE_7D;
    case 'CUSTOM_DATE':
      return _$gTimeRangeCUSTOM_DATE;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<GTimeRange> _$gTimeRangeValues =
    new BuiltSet<GTimeRange>(const <GTimeRange>[
  _$gTimeRangeRANGE_1H,
  _$gTimeRangeRANGE_6H,
  _$gTimeRangeRANGE_12H,
  _$gTimeRangeRANGE_24H,
  _$gTimeRangeRANGE_3D,
  _$gTimeRangeRANGE_7D,
  _$gTimeRangeCUSTOM_DATE,
]);

const GMachineStatus _$gMachineStatusONLINE = const GMachineStatus._('ONLINE');
const GMachineStatus _$gMachineStatusOFFLINE =
    const GMachineStatus._('OFFLINE');

GMachineStatus _$gMachineStatusValueOf(String name) {
  switch (name) {
    case 'ONLINE':
      return _$gMachineStatusONLINE;
    case 'OFFLINE':
      return _$gMachineStatusOFFLINE;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<GMachineStatus> _$gMachineStatusValues =
    new BuiltSet<GMachineStatus>(const <GMachineStatus>[
  _$gMachineStatusONLINE,
  _$gMachineStatusOFFLINE,
]);

Serializer<GMetricType> _$gMetricTypeSerializer = new _$GMetricTypeSerializer();
Serializer<GTimeRange> _$gTimeRangeSerializer = new _$GTimeRangeSerializer();
Serializer<GMachineStatus> _$gMachineStatusSerializer =
    new _$GMachineStatusSerializer();

class _$GMetricTypeSerializer implements PrimitiveSerializer<GMetricType> {
  @override
  final Iterable<Type> types = const <Type>[GMetricType];
  @override
  final String wireName = 'GMetricType';

  @override
  Object serialize(Serializers serializers, GMetricType object,
          {FullType specifiedType = FullType.unspecified}) =>
      object.name;

  @override
  GMetricType deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      GMetricType.valueOf(serialized as String);
}

class _$GTimeRangeSerializer implements PrimitiveSerializer<GTimeRange> {
  @override
  final Iterable<Type> types = const <Type>[GTimeRange];
  @override
  final String wireName = 'GTimeRange';

  @override
  Object serialize(Serializers serializers, GTimeRange object,
          {FullType specifiedType = FullType.unspecified}) =>
      object.name;

  @override
  GTimeRange deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      GTimeRange.valueOf(serialized as String);
}

class _$GMachineStatusSerializer
    implements PrimitiveSerializer<GMachineStatus> {
  @override
  final Iterable<Type> types = const <Type>[GMachineStatus];
  @override
  final String wireName = 'GMachineStatus';

  @override
  Object serialize(Serializers serializers, GMachineStatus object,
          {FullType specifiedType = FullType.unspecified}) =>
      object.name;

  @override
  GMachineStatus deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      GMachineStatus.valueOf(serialized as String);
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
