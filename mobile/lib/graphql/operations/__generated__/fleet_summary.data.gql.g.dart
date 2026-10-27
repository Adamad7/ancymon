// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fleet_summary.data.gql.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<GFleetSummaryData> _$gFleetSummaryDataSerializer =
    new _$GFleetSummaryDataSerializer();
Serializer<GFleetSummaryData_fleetSummary>
    _$gFleetSummaryDataFleetSummarySerializer =
    new _$GFleetSummaryData_fleetSummarySerializer();

class _$GFleetSummaryDataSerializer
    implements StructuredSerializer<GFleetSummaryData> {
  @override
  final Iterable<Type> types = const [GFleetSummaryData, _$GFleetSummaryData];
  @override
  final String wireName = 'GFleetSummaryData';

  @override
  Iterable<Object?> serialize(Serializers serializers, GFleetSummaryData object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      '__typename',
      serializers.serialize(object.G__typename,
          specifiedType: const FullType(String)),
      'fleetSummary',
      serializers.serialize(object.fleetSummary,
          specifiedType: const FullType(BuiltList,
              const [const FullType(GFleetSummaryData_fleetSummary)])),
    ];

    return result;
  }

  @override
  GFleetSummaryData deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new GFleetSummaryDataBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case '__typename':
          result.G__typename = serializers.deserialize(value,
              specifiedType: const FullType(String))! as String;
          break;
        case 'fleetSummary':
          result.fleetSummary.replace(serializers.deserialize(value,
              specifiedType: const FullType(BuiltList, const [
                const FullType(GFleetSummaryData_fleetSummary)
              ]))! as BuiltList<Object?>);
          break;
      }
    }

    return result.build();
  }
}

class _$GFleetSummaryData_fleetSummarySerializer
    implements StructuredSerializer<GFleetSummaryData_fleetSummary> {
  @override
  final Iterable<Type> types = const [
    GFleetSummaryData_fleetSummary,
    _$GFleetSummaryData_fleetSummary
  ];
  @override
  final String wireName = 'GFleetSummaryData_fleetSummary';

  @override
  Iterable<Object?> serialize(
      Serializers serializers, GFleetSummaryData_fleetSummary object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      '__typename',
      serializers.serialize(object.G__typename,
          specifiedType: const FullType(String)),
      'machineId',
      serializers.serialize(object.machineId,
          specifiedType: const FullType(String)),
      'hostname',
      serializers.serialize(object.hostname,
          specifiedType: const FullType(String)),
      'status',
      serializers.serialize(object.status,
          specifiedType: const FullType(_i2.GMachineStatus)),
      'lastSeenTimestamp',
      serializers.serialize(object.lastSeenTimestamp,
          specifiedType: const FullType(int)),
    ];
    Object? value;
    value = object.cpuUsagePercent;
    if (value != null) {
      result
        ..add('cpuUsagePercent')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(double)));
    }
    value = object.cpuTemperatureC;
    if (value != null) {
      result
        ..add('cpuTemperatureC')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(double)));
    }
    value = object.networkRxBytesPerSec;
    if (value != null) {
      result
        ..add('networkRxBytesPerSec')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(double)));
    }
    value = object.networkTxBytesPerSec;
    if (value != null) {
      result
        ..add('networkTxBytesPerSec')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(double)));
    }
    return result;
  }

  @override
  GFleetSummaryData_fleetSummary deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new GFleetSummaryData_fleetSummaryBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case '__typename':
          result.G__typename = serializers.deserialize(value,
              specifiedType: const FullType(String))! as String;
          break;
        case 'machineId':
          result.machineId = serializers.deserialize(value,
              specifiedType: const FullType(String))! as String;
          break;
        case 'hostname':
          result.hostname = serializers.deserialize(value,
              specifiedType: const FullType(String))! as String;
          break;
        case 'status':
          result.status = serializers.deserialize(value,
                  specifiedType: const FullType(_i2.GMachineStatus))!
              as _i2.GMachineStatus;
          break;
        case 'lastSeenTimestamp':
          result.lastSeenTimestamp = serializers.deserialize(value,
              specifiedType: const FullType(int))! as int;
          break;
        case 'cpuUsagePercent':
          result.cpuUsagePercent = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double?;
          break;
        case 'cpuTemperatureC':
          result.cpuTemperatureC = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double?;
          break;
        case 'networkRxBytesPerSec':
          result.networkRxBytesPerSec = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double?;
          break;
        case 'networkTxBytesPerSec':
          result.networkTxBytesPerSec = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double?;
          break;
      }
    }

    return result.build();
  }
}

class _$GFleetSummaryData extends GFleetSummaryData {
  @override
  final String G__typename;
  @override
  final BuiltList<GFleetSummaryData_fleetSummary> fleetSummary;

  factory _$GFleetSummaryData(
          [void Function(GFleetSummaryDataBuilder)? updates]) =>
      (new GFleetSummaryDataBuilder()..update(updates))._build();

  _$GFleetSummaryData._({required this.G__typename, required this.fleetSummary})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        G__typename, r'GFleetSummaryData', 'G__typename');
    BuiltValueNullFieldError.checkNotNull(
        fleetSummary, r'GFleetSummaryData', 'fleetSummary');
  }

  @override
  GFleetSummaryData rebuild(void Function(GFleetSummaryDataBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GFleetSummaryDataBuilder toBuilder() =>
      new GFleetSummaryDataBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GFleetSummaryData &&
        G__typename == other.G__typename &&
        fleetSummary == other.fleetSummary;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, G__typename.hashCode);
    _$hash = $jc(_$hash, fleetSummary.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GFleetSummaryData')
          ..add('G__typename', G__typename)
          ..add('fleetSummary', fleetSummary))
        .toString();
  }
}

class GFleetSummaryDataBuilder
    implements Builder<GFleetSummaryData, GFleetSummaryDataBuilder> {
  _$GFleetSummaryData? _$v;

  String? _G__typename;
  String? get G__typename => _$this._G__typename;
  set G__typename(String? G__typename) => _$this._G__typename = G__typename;

  ListBuilder<GFleetSummaryData_fleetSummary>? _fleetSummary;
  ListBuilder<GFleetSummaryData_fleetSummary> get fleetSummary =>
      _$this._fleetSummary ??=
          new ListBuilder<GFleetSummaryData_fleetSummary>();
  set fleetSummary(ListBuilder<GFleetSummaryData_fleetSummary>? fleetSummary) =>
      _$this._fleetSummary = fleetSummary;

  GFleetSummaryDataBuilder() {
    GFleetSummaryData._initializeBuilder(this);
  }

  GFleetSummaryDataBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _G__typename = $v.G__typename;
      _fleetSummary = $v.fleetSummary.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GFleetSummaryData other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$GFleetSummaryData;
  }

  @override
  void update(void Function(GFleetSummaryDataBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GFleetSummaryData build() => _build();

  _$GFleetSummaryData _build() {
    _$GFleetSummaryData _$result;
    try {
      _$result = _$v ??
          new _$GFleetSummaryData._(
              G__typename: BuiltValueNullFieldError.checkNotNull(
                  G__typename, r'GFleetSummaryData', 'G__typename'),
              fleetSummary: fleetSummary.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'fleetSummary';
        fleetSummary.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'GFleetSummaryData', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

class _$GFleetSummaryData_fleetSummary extends GFleetSummaryData_fleetSummary {
  @override
  final String G__typename;
  @override
  final String machineId;
  @override
  final String hostname;
  @override
  final _i2.GMachineStatus status;
  @override
  final int lastSeenTimestamp;
  @override
  final double? cpuUsagePercent;
  @override
  final double? cpuTemperatureC;
  @override
  final double? networkRxBytesPerSec;
  @override
  final double? networkTxBytesPerSec;

  factory _$GFleetSummaryData_fleetSummary(
          [void Function(GFleetSummaryData_fleetSummaryBuilder)? updates]) =>
      (new GFleetSummaryData_fleetSummaryBuilder()..update(updates))._build();

  _$GFleetSummaryData_fleetSummary._(
      {required this.G__typename,
      required this.machineId,
      required this.hostname,
      required this.status,
      required this.lastSeenTimestamp,
      this.cpuUsagePercent,
      this.cpuTemperatureC,
      this.networkRxBytesPerSec,
      this.networkTxBytesPerSec})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        G__typename, r'GFleetSummaryData_fleetSummary', 'G__typename');
    BuiltValueNullFieldError.checkNotNull(
        machineId, r'GFleetSummaryData_fleetSummary', 'machineId');
    BuiltValueNullFieldError.checkNotNull(
        hostname, r'GFleetSummaryData_fleetSummary', 'hostname');
    BuiltValueNullFieldError.checkNotNull(
        status, r'GFleetSummaryData_fleetSummary', 'status');
    BuiltValueNullFieldError.checkNotNull(lastSeenTimestamp,
        r'GFleetSummaryData_fleetSummary', 'lastSeenTimestamp');
  }

  @override
  GFleetSummaryData_fleetSummary rebuild(
          void Function(GFleetSummaryData_fleetSummaryBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GFleetSummaryData_fleetSummaryBuilder toBuilder() =>
      new GFleetSummaryData_fleetSummaryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GFleetSummaryData_fleetSummary &&
        G__typename == other.G__typename &&
        machineId == other.machineId &&
        hostname == other.hostname &&
        status == other.status &&
        lastSeenTimestamp == other.lastSeenTimestamp &&
        cpuUsagePercent == other.cpuUsagePercent &&
        cpuTemperatureC == other.cpuTemperatureC &&
        networkRxBytesPerSec == other.networkRxBytesPerSec &&
        networkTxBytesPerSec == other.networkTxBytesPerSec;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, G__typename.hashCode);
    _$hash = $jc(_$hash, machineId.hashCode);
    _$hash = $jc(_$hash, hostname.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, lastSeenTimestamp.hashCode);
    _$hash = $jc(_$hash, cpuUsagePercent.hashCode);
    _$hash = $jc(_$hash, cpuTemperatureC.hashCode);
    _$hash = $jc(_$hash, networkRxBytesPerSec.hashCode);
    _$hash = $jc(_$hash, networkTxBytesPerSec.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GFleetSummaryData_fleetSummary')
          ..add('G__typename', G__typename)
          ..add('machineId', machineId)
          ..add('hostname', hostname)
          ..add('status', status)
          ..add('lastSeenTimestamp', lastSeenTimestamp)
          ..add('cpuUsagePercent', cpuUsagePercent)
          ..add('cpuTemperatureC', cpuTemperatureC)
          ..add('networkRxBytesPerSec', networkRxBytesPerSec)
          ..add('networkTxBytesPerSec', networkTxBytesPerSec))
        .toString();
  }
}

class GFleetSummaryData_fleetSummaryBuilder
    implements
        Builder<GFleetSummaryData_fleetSummary,
            GFleetSummaryData_fleetSummaryBuilder> {
  _$GFleetSummaryData_fleetSummary? _$v;

  String? _G__typename;
  String? get G__typename => _$this._G__typename;
  set G__typename(String? G__typename) => _$this._G__typename = G__typename;

  String? _machineId;
  String? get machineId => _$this._machineId;
  set machineId(String? machineId) => _$this._machineId = machineId;

  String? _hostname;
  String? get hostname => _$this._hostname;
  set hostname(String? hostname) => _$this._hostname = hostname;

  _i2.GMachineStatus? _status;
  _i2.GMachineStatus? get status => _$this._status;
  set status(_i2.GMachineStatus? status) => _$this._status = status;

  int? _lastSeenTimestamp;
  int? get lastSeenTimestamp => _$this._lastSeenTimestamp;
  set lastSeenTimestamp(int? lastSeenTimestamp) =>
      _$this._lastSeenTimestamp = lastSeenTimestamp;

  double? _cpuUsagePercent;
  double? get cpuUsagePercent => _$this._cpuUsagePercent;
  set cpuUsagePercent(double? cpuUsagePercent) =>
      _$this._cpuUsagePercent = cpuUsagePercent;

  double? _cpuTemperatureC;
  double? get cpuTemperatureC => _$this._cpuTemperatureC;
  set cpuTemperatureC(double? cpuTemperatureC) =>
      _$this._cpuTemperatureC = cpuTemperatureC;

  double? _networkRxBytesPerSec;
  double? get networkRxBytesPerSec => _$this._networkRxBytesPerSec;
  set networkRxBytesPerSec(double? networkRxBytesPerSec) =>
      _$this._networkRxBytesPerSec = networkRxBytesPerSec;

  double? _networkTxBytesPerSec;
  double? get networkTxBytesPerSec => _$this._networkTxBytesPerSec;
  set networkTxBytesPerSec(double? networkTxBytesPerSec) =>
      _$this._networkTxBytesPerSec = networkTxBytesPerSec;

  GFleetSummaryData_fleetSummaryBuilder() {
    GFleetSummaryData_fleetSummary._initializeBuilder(this);
  }

  GFleetSummaryData_fleetSummaryBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _G__typename = $v.G__typename;
      _machineId = $v.machineId;
      _hostname = $v.hostname;
      _status = $v.status;
      _lastSeenTimestamp = $v.lastSeenTimestamp;
      _cpuUsagePercent = $v.cpuUsagePercent;
      _cpuTemperatureC = $v.cpuTemperatureC;
      _networkRxBytesPerSec = $v.networkRxBytesPerSec;
      _networkTxBytesPerSec = $v.networkTxBytesPerSec;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GFleetSummaryData_fleetSummary other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$GFleetSummaryData_fleetSummary;
  }

  @override
  void update(void Function(GFleetSummaryData_fleetSummaryBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GFleetSummaryData_fleetSummary build() => _build();

  _$GFleetSummaryData_fleetSummary _build() {
    final _$result = _$v ??
        new _$GFleetSummaryData_fleetSummary._(
            G__typename: BuiltValueNullFieldError.checkNotNull(
                G__typename, r'GFleetSummaryData_fleetSummary', 'G__typename'),
            machineId: BuiltValueNullFieldError.checkNotNull(
                machineId, r'GFleetSummaryData_fleetSummary', 'machineId'),
            hostname: BuiltValueNullFieldError.checkNotNull(
                hostname, r'GFleetSummaryData_fleetSummary', 'hostname'),
            status: BuiltValueNullFieldError.checkNotNull(
                status, r'GFleetSummaryData_fleetSummary', 'status'),
            lastSeenTimestamp: BuiltValueNullFieldError.checkNotNull(
                lastSeenTimestamp,
                r'GFleetSummaryData_fleetSummary',
                'lastSeenTimestamp'),
            cpuUsagePercent: cpuUsagePercent,
            cpuTemperatureC: cpuTemperatureC,
            networkRxBytesPerSec: networkRxBytesPerSec,
            networkTxBytesPerSec: networkTxBytesPerSec);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
