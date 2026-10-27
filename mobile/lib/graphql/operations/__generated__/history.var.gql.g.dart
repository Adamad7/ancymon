// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history.var.gql.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<GMachineHistoryVars> _$gMachineHistoryVarsSerializer =
    new _$GMachineHistoryVarsSerializer();

class _$GMachineHistoryVarsSerializer
    implements StructuredSerializer<GMachineHistoryVars> {
  @override
  final Iterable<Type> types = const [
    GMachineHistoryVars,
    _$GMachineHistoryVars
  ];
  @override
  final String wireName = 'GMachineHistoryVars';

  @override
  Iterable<Object?> serialize(
      Serializers serializers, GMachineHistoryVars object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'machineId',
      serializers.serialize(object.machineId,
          specifiedType: const FullType(String)),
      'metric',
      serializers.serialize(object.metric,
          specifiedType: const FullType(_i1.GMetricType)),
      'range',
      serializers.serialize(object.range,
          specifiedType: const FullType(_i1.GTimeRange)),
    ];
    Object? value;
    value = object.date;
    if (value != null) {
      result
        ..add('date')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  GMachineHistoryVars deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new GMachineHistoryVarsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'machineId':
          result.machineId = serializers.deserialize(value,
              specifiedType: const FullType(String))! as String;
          break;
        case 'metric':
          result.metric = serializers.deserialize(value,
                  specifiedType: const FullType(_i1.GMetricType))!
              as _i1.GMetricType;
          break;
        case 'range':
          result.range = serializers.deserialize(value,
              specifiedType: const FullType(_i1.GTimeRange))! as _i1.GTimeRange;
          break;
        case 'date':
          result.date = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
      }
    }

    return result.build();
  }
}

class _$GMachineHistoryVars extends GMachineHistoryVars {
  @override
  final String machineId;
  @override
  final _i1.GMetricType metric;
  @override
  final _i1.GTimeRange range;
  @override
  final String? date;

  factory _$GMachineHistoryVars(
          [void Function(GMachineHistoryVarsBuilder)? updates]) =>
      (new GMachineHistoryVarsBuilder()..update(updates))._build();

  _$GMachineHistoryVars._(
      {required this.machineId,
      required this.metric,
      required this.range,
      this.date})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        machineId, r'GMachineHistoryVars', 'machineId');
    BuiltValueNullFieldError.checkNotNull(
        metric, r'GMachineHistoryVars', 'metric');
    BuiltValueNullFieldError.checkNotNull(
        range, r'GMachineHistoryVars', 'range');
  }

  @override
  GMachineHistoryVars rebuild(
          void Function(GMachineHistoryVarsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GMachineHistoryVarsBuilder toBuilder() =>
      new GMachineHistoryVarsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GMachineHistoryVars &&
        machineId == other.machineId &&
        metric == other.metric &&
        range == other.range &&
        date == other.date;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, machineId.hashCode);
    _$hash = $jc(_$hash, metric.hashCode);
    _$hash = $jc(_$hash, range.hashCode);
    _$hash = $jc(_$hash, date.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GMachineHistoryVars')
          ..add('machineId', machineId)
          ..add('metric', metric)
          ..add('range', range)
          ..add('date', date))
        .toString();
  }
}

class GMachineHistoryVarsBuilder
    implements Builder<GMachineHistoryVars, GMachineHistoryVarsBuilder> {
  _$GMachineHistoryVars? _$v;

  String? _machineId;
  String? get machineId => _$this._machineId;
  set machineId(String? machineId) => _$this._machineId = machineId;

  _i1.GMetricType? _metric;
  _i1.GMetricType? get metric => _$this._metric;
  set metric(_i1.GMetricType? metric) => _$this._metric = metric;

  _i1.GTimeRange? _range;
  _i1.GTimeRange? get range => _$this._range;
  set range(_i1.GTimeRange? range) => _$this._range = range;

  String? _date;
  String? get date => _$this._date;
  set date(String? date) => _$this._date = date;

  GMachineHistoryVarsBuilder();

  GMachineHistoryVarsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _machineId = $v.machineId;
      _metric = $v.metric;
      _range = $v.range;
      _date = $v.date;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GMachineHistoryVars other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$GMachineHistoryVars;
  }

  @override
  void update(void Function(GMachineHistoryVarsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GMachineHistoryVars build() => _build();

  _$GMachineHistoryVars _build() {
    final _$result = _$v ??
        new _$GMachineHistoryVars._(
            machineId: BuiltValueNullFieldError.checkNotNull(
                machineId, r'GMachineHistoryVars', 'machineId'),
            metric: BuiltValueNullFieldError.checkNotNull(
                metric, r'GMachineHistoryVars', 'metric'),
            range: BuiltValueNullFieldError.checkNotNull(
                range, r'GMachineHistoryVars', 'range'),
            date: date);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
