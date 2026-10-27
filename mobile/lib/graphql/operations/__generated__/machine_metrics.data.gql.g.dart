// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'machine_metrics.data.gql.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<GMachineMetricsData> _$gMachineMetricsDataSerializer =
    new _$GMachineMetricsDataSerializer();
Serializer<GMachineMetricsData_machineMetrics>
    _$gMachineMetricsDataMachineMetricsSerializer =
    new _$GMachineMetricsData_machineMetricsSerializer();
Serializer<GMachineMetricsData_machineMetrics_cpu>
    _$gMachineMetricsDataMachineMetricsCpuSerializer =
    new _$GMachineMetricsData_machineMetrics_cpuSerializer();
Serializer<GMachineMetricsData_machineMetrics_memory>
    _$gMachineMetricsDataMachineMetricsMemorySerializer =
    new _$GMachineMetricsData_machineMetrics_memorySerializer();
Serializer<GMachineMetricsData_machineMetrics_network>
    _$gMachineMetricsDataMachineMetricsNetworkSerializer =
    new _$GMachineMetricsData_machineMetrics_networkSerializer();
Serializer<GMachineMetricsData_machineMetrics_disks>
    _$gMachineMetricsDataMachineMetricsDisksSerializer =
    new _$GMachineMetricsData_machineMetrics_disksSerializer();

class _$GMachineMetricsDataSerializer
    implements StructuredSerializer<GMachineMetricsData> {
  @override
  final Iterable<Type> types = const [
    GMachineMetricsData,
    _$GMachineMetricsData
  ];
  @override
  final String wireName = 'GMachineMetricsData';

  @override
  Iterable<Object?> serialize(
      Serializers serializers, GMachineMetricsData object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      '__typename',
      serializers.serialize(object.G__typename,
          specifiedType: const FullType(String)),
      'machineMetrics',
      serializers.serialize(object.machineMetrics,
          specifiedType: const FullType(GMachineMetricsData_machineMetrics)),
    ];

    return result;
  }

  @override
  GMachineMetricsData deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new GMachineMetricsDataBuilder();

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
        case 'machineMetrics':
          result.machineMetrics.replace(serializers.deserialize(value,
                  specifiedType:
                      const FullType(GMachineMetricsData_machineMetrics))!
              as GMachineMetricsData_machineMetrics);
          break;
      }
    }

    return result.build();
  }
}

class _$GMachineMetricsData_machineMetricsSerializer
    implements StructuredSerializer<GMachineMetricsData_machineMetrics> {
  @override
  final Iterable<Type> types = const [
    GMachineMetricsData_machineMetrics,
    _$GMachineMetricsData_machineMetrics
  ];
  @override
  final String wireName = 'GMachineMetricsData_machineMetrics';

  @override
  Iterable<Object?> serialize(
      Serializers serializers, GMachineMetricsData_machineMetrics object,
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
      'timestamp',
      serializers.serialize(object.timestamp,
          specifiedType: const FullType(int)),
      'cpu',
      serializers.serialize(object.cpu,
          specifiedType:
              const FullType(GMachineMetricsData_machineMetrics_cpu)),
      'memory',
      serializers.serialize(object.memory,
          specifiedType:
              const FullType(GMachineMetricsData_machineMetrics_memory)),
      'network',
      serializers.serialize(object.network,
          specifiedType:
              const FullType(GMachineMetricsData_machineMetrics_network)),
      'disks',
      serializers.serialize(object.disks,
          specifiedType: const FullType(BuiltList, const [
            const FullType(GMachineMetricsData_machineMetrics_disks)
          ])),
    ];

    return result;
  }

  @override
  GMachineMetricsData_machineMetrics deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new GMachineMetricsData_machineMetricsBuilder();

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
        case 'timestamp':
          result.timestamp = serializers.deserialize(value,
              specifiedType: const FullType(int))! as int;
          break;
        case 'cpu':
          result.cpu.replace(serializers.deserialize(value,
                  specifiedType:
                      const FullType(GMachineMetricsData_machineMetrics_cpu))!
              as GMachineMetricsData_machineMetrics_cpu);
          break;
        case 'memory':
          result.memory.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      GMachineMetricsData_machineMetrics_memory))!
              as GMachineMetricsData_machineMetrics_memory);
          break;
        case 'network':
          result.network.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      GMachineMetricsData_machineMetrics_network))!
              as GMachineMetricsData_machineMetrics_network);
          break;
        case 'disks':
          result.disks.replace(serializers.deserialize(value,
              specifiedType: const FullType(BuiltList, const [
                const FullType(GMachineMetricsData_machineMetrics_disks)
              ]))! as BuiltList<Object?>);
          break;
      }
    }

    return result.build();
  }
}

class _$GMachineMetricsData_machineMetrics_cpuSerializer
    implements StructuredSerializer<GMachineMetricsData_machineMetrics_cpu> {
  @override
  final Iterable<Type> types = const [
    GMachineMetricsData_machineMetrics_cpu,
    _$GMachineMetricsData_machineMetrics_cpu
  ];
  @override
  final String wireName = 'GMachineMetricsData_machineMetrics_cpu';

  @override
  Iterable<Object?> serialize(
      Serializers serializers, GMachineMetricsData_machineMetrics_cpu object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      '__typename',
      serializers.serialize(object.G__typename,
          specifiedType: const FullType(String)),
      'totalUsagePercent',
      serializers.serialize(object.totalUsagePercent,
          specifiedType: const FullType(double)),
    ];
    Object? value;
    value = object.temperatureC;
    if (value != null) {
      result
        ..add('temperatureC')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(double)));
    }
    return result;
  }

  @override
  GMachineMetricsData_machineMetrics_cpu deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new GMachineMetricsData_machineMetrics_cpuBuilder();

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
        case 'totalUsagePercent':
          result.totalUsagePercent = serializers.deserialize(value,
              specifiedType: const FullType(double))! as double;
          break;
        case 'temperatureC':
          result.temperatureC = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double?;
          break;
      }
    }

    return result.build();
  }
}

class _$GMachineMetricsData_machineMetrics_memorySerializer
    implements StructuredSerializer<GMachineMetricsData_machineMetrics_memory> {
  @override
  final Iterable<Type> types = const [
    GMachineMetricsData_machineMetrics_memory,
    _$GMachineMetricsData_machineMetrics_memory
  ];
  @override
  final String wireName = 'GMachineMetricsData_machineMetrics_memory';

  @override
  Iterable<Object?> serialize(
      Serializers serializers, GMachineMetricsData_machineMetrics_memory object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      '__typename',
      serializers.serialize(object.G__typename,
          specifiedType: const FullType(String)),
      'totalBytes',
      serializers.serialize(object.totalBytes,
          specifiedType: const FullType(double)),
      'usedBytes',
      serializers.serialize(object.usedBytes,
          specifiedType: const FullType(double)),
      'usagePercent',
      serializers.serialize(object.usagePercent,
          specifiedType: const FullType(double)),
    ];

    return result;
  }

  @override
  GMachineMetricsData_machineMetrics_memory deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new GMachineMetricsData_machineMetrics_memoryBuilder();

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
        case 'totalBytes':
          result.totalBytes = serializers.deserialize(value,
              specifiedType: const FullType(double))! as double;
          break;
        case 'usedBytes':
          result.usedBytes = serializers.deserialize(value,
              specifiedType: const FullType(double))! as double;
          break;
        case 'usagePercent':
          result.usagePercent = serializers.deserialize(value,
              specifiedType: const FullType(double))! as double;
          break;
      }
    }

    return result.build();
  }
}

class _$GMachineMetricsData_machineMetrics_networkSerializer
    implements
        StructuredSerializer<GMachineMetricsData_machineMetrics_network> {
  @override
  final Iterable<Type> types = const [
    GMachineMetricsData_machineMetrics_network,
    _$GMachineMetricsData_machineMetrics_network
  ];
  @override
  final String wireName = 'GMachineMetricsData_machineMetrics_network';

  @override
  Iterable<Object?> serialize(Serializers serializers,
      GMachineMetricsData_machineMetrics_network object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      '__typename',
      serializers.serialize(object.G__typename,
          specifiedType: const FullType(String)),
      'rxBytesPerSec',
      serializers.serialize(object.rxBytesPerSec,
          specifiedType: const FullType(double)),
      'txBytesPerSec',
      serializers.serialize(object.txBytesPerSec,
          specifiedType: const FullType(double)),
    ];

    return result;
  }

  @override
  GMachineMetricsData_machineMetrics_network deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new GMachineMetricsData_machineMetrics_networkBuilder();

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
        case 'rxBytesPerSec':
          result.rxBytesPerSec = serializers.deserialize(value,
              specifiedType: const FullType(double))! as double;
          break;
        case 'txBytesPerSec':
          result.txBytesPerSec = serializers.deserialize(value,
              specifiedType: const FullType(double))! as double;
          break;
      }
    }

    return result.build();
  }
}

class _$GMachineMetricsData_machineMetrics_disksSerializer
    implements StructuredSerializer<GMachineMetricsData_machineMetrics_disks> {
  @override
  final Iterable<Type> types = const [
    GMachineMetricsData_machineMetrics_disks,
    _$GMachineMetricsData_machineMetrics_disks
  ];
  @override
  final String wireName = 'GMachineMetricsData_machineMetrics_disks';

  @override
  Iterable<Object?> serialize(
      Serializers serializers, GMachineMetricsData_machineMetrics_disks object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      '__typename',
      serializers.serialize(object.G__typename,
          specifiedType: const FullType(String)),
      'mountPoint',
      serializers.serialize(object.mountPoint,
          specifiedType: const FullType(String)),
      'fsType',
      serializers.serialize(object.fsType,
          specifiedType: const FullType(String)),
      'totalBytes',
      serializers.serialize(object.totalBytes,
          specifiedType: const FullType(double)),
      'freeBytes',
      serializers.serialize(object.freeBytes,
          specifiedType: const FullType(double)),
      'usagePercent',
      serializers.serialize(object.usagePercent,
          specifiedType: const FullType(double)),
    ];

    return result;
  }

  @override
  GMachineMetricsData_machineMetrics_disks deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new GMachineMetricsData_machineMetrics_disksBuilder();

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
        case 'mountPoint':
          result.mountPoint = serializers.deserialize(value,
              specifiedType: const FullType(String))! as String;
          break;
        case 'fsType':
          result.fsType = serializers.deserialize(value,
              specifiedType: const FullType(String))! as String;
          break;
        case 'totalBytes':
          result.totalBytes = serializers.deserialize(value,
              specifiedType: const FullType(double))! as double;
          break;
        case 'freeBytes':
          result.freeBytes = serializers.deserialize(value,
              specifiedType: const FullType(double))! as double;
          break;
        case 'usagePercent':
          result.usagePercent = serializers.deserialize(value,
              specifiedType: const FullType(double))! as double;
          break;
      }
    }

    return result.build();
  }
}

class _$GMachineMetricsData extends GMachineMetricsData {
  @override
  final String G__typename;
  @override
  final GMachineMetricsData_machineMetrics machineMetrics;

  factory _$GMachineMetricsData(
          [void Function(GMachineMetricsDataBuilder)? updates]) =>
      (new GMachineMetricsDataBuilder()..update(updates))._build();

  _$GMachineMetricsData._(
      {required this.G__typename, required this.machineMetrics})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        G__typename, r'GMachineMetricsData', 'G__typename');
    BuiltValueNullFieldError.checkNotNull(
        machineMetrics, r'GMachineMetricsData', 'machineMetrics');
  }

  @override
  GMachineMetricsData rebuild(
          void Function(GMachineMetricsDataBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GMachineMetricsDataBuilder toBuilder() =>
      new GMachineMetricsDataBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GMachineMetricsData &&
        G__typename == other.G__typename &&
        machineMetrics == other.machineMetrics;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, G__typename.hashCode);
    _$hash = $jc(_$hash, machineMetrics.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GMachineMetricsData')
          ..add('G__typename', G__typename)
          ..add('machineMetrics', machineMetrics))
        .toString();
  }
}

class GMachineMetricsDataBuilder
    implements Builder<GMachineMetricsData, GMachineMetricsDataBuilder> {
  _$GMachineMetricsData? _$v;

  String? _G__typename;
  String? get G__typename => _$this._G__typename;
  set G__typename(String? G__typename) => _$this._G__typename = G__typename;

  GMachineMetricsData_machineMetricsBuilder? _machineMetrics;
  GMachineMetricsData_machineMetricsBuilder get machineMetrics =>
      _$this._machineMetrics ??=
          new GMachineMetricsData_machineMetricsBuilder();
  set machineMetrics(
          GMachineMetricsData_machineMetricsBuilder? machineMetrics) =>
      _$this._machineMetrics = machineMetrics;

  GMachineMetricsDataBuilder() {
    GMachineMetricsData._initializeBuilder(this);
  }

  GMachineMetricsDataBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _G__typename = $v.G__typename;
      _machineMetrics = $v.machineMetrics.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GMachineMetricsData other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$GMachineMetricsData;
  }

  @override
  void update(void Function(GMachineMetricsDataBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GMachineMetricsData build() => _build();

  _$GMachineMetricsData _build() {
    _$GMachineMetricsData _$result;
    try {
      _$result = _$v ??
          new _$GMachineMetricsData._(
              G__typename: BuiltValueNullFieldError.checkNotNull(
                  G__typename, r'GMachineMetricsData', 'G__typename'),
              machineMetrics: machineMetrics.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'machineMetrics';
        machineMetrics.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'GMachineMetricsData', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

class _$GMachineMetricsData_machineMetrics
    extends GMachineMetricsData_machineMetrics {
  @override
  final String G__typename;
  @override
  final String machineId;
  @override
  final String hostname;
  @override
  final _i2.GMachineStatus status;
  @override
  final int timestamp;
  @override
  final GMachineMetricsData_machineMetrics_cpu cpu;
  @override
  final GMachineMetricsData_machineMetrics_memory memory;
  @override
  final GMachineMetricsData_machineMetrics_network network;
  @override
  final BuiltList<GMachineMetricsData_machineMetrics_disks> disks;

  factory _$GMachineMetricsData_machineMetrics(
          [void Function(GMachineMetricsData_machineMetricsBuilder)?
              updates]) =>
      (new GMachineMetricsData_machineMetricsBuilder()..update(updates))
          ._build();

  _$GMachineMetricsData_machineMetrics._(
      {required this.G__typename,
      required this.machineId,
      required this.hostname,
      required this.status,
      required this.timestamp,
      required this.cpu,
      required this.memory,
      required this.network,
      required this.disks})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        G__typename, r'GMachineMetricsData_machineMetrics', 'G__typename');
    BuiltValueNullFieldError.checkNotNull(
        machineId, r'GMachineMetricsData_machineMetrics', 'machineId');
    BuiltValueNullFieldError.checkNotNull(
        hostname, r'GMachineMetricsData_machineMetrics', 'hostname');
    BuiltValueNullFieldError.checkNotNull(
        status, r'GMachineMetricsData_machineMetrics', 'status');
    BuiltValueNullFieldError.checkNotNull(
        timestamp, r'GMachineMetricsData_machineMetrics', 'timestamp');
    BuiltValueNullFieldError.checkNotNull(
        cpu, r'GMachineMetricsData_machineMetrics', 'cpu');
    BuiltValueNullFieldError.checkNotNull(
        memory, r'GMachineMetricsData_machineMetrics', 'memory');
    BuiltValueNullFieldError.checkNotNull(
        network, r'GMachineMetricsData_machineMetrics', 'network');
    BuiltValueNullFieldError.checkNotNull(
        disks, r'GMachineMetricsData_machineMetrics', 'disks');
  }

  @override
  GMachineMetricsData_machineMetrics rebuild(
          void Function(GMachineMetricsData_machineMetricsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GMachineMetricsData_machineMetricsBuilder toBuilder() =>
      new GMachineMetricsData_machineMetricsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GMachineMetricsData_machineMetrics &&
        G__typename == other.G__typename &&
        machineId == other.machineId &&
        hostname == other.hostname &&
        status == other.status &&
        timestamp == other.timestamp &&
        cpu == other.cpu &&
        memory == other.memory &&
        network == other.network &&
        disks == other.disks;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, G__typename.hashCode);
    _$hash = $jc(_$hash, machineId.hashCode);
    _$hash = $jc(_$hash, hostname.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, timestamp.hashCode);
    _$hash = $jc(_$hash, cpu.hashCode);
    _$hash = $jc(_$hash, memory.hashCode);
    _$hash = $jc(_$hash, network.hashCode);
    _$hash = $jc(_$hash, disks.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GMachineMetricsData_machineMetrics')
          ..add('G__typename', G__typename)
          ..add('machineId', machineId)
          ..add('hostname', hostname)
          ..add('status', status)
          ..add('timestamp', timestamp)
          ..add('cpu', cpu)
          ..add('memory', memory)
          ..add('network', network)
          ..add('disks', disks))
        .toString();
  }
}

class GMachineMetricsData_machineMetricsBuilder
    implements
        Builder<GMachineMetricsData_machineMetrics,
            GMachineMetricsData_machineMetricsBuilder> {
  _$GMachineMetricsData_machineMetrics? _$v;

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

  int? _timestamp;
  int? get timestamp => _$this._timestamp;
  set timestamp(int? timestamp) => _$this._timestamp = timestamp;

  GMachineMetricsData_machineMetrics_cpuBuilder? _cpu;
  GMachineMetricsData_machineMetrics_cpuBuilder get cpu =>
      _$this._cpu ??= new GMachineMetricsData_machineMetrics_cpuBuilder();
  set cpu(GMachineMetricsData_machineMetrics_cpuBuilder? cpu) =>
      _$this._cpu = cpu;

  GMachineMetricsData_machineMetrics_memoryBuilder? _memory;
  GMachineMetricsData_machineMetrics_memoryBuilder get memory =>
      _$this._memory ??= new GMachineMetricsData_machineMetrics_memoryBuilder();
  set memory(GMachineMetricsData_machineMetrics_memoryBuilder? memory) =>
      _$this._memory = memory;

  GMachineMetricsData_machineMetrics_networkBuilder? _network;
  GMachineMetricsData_machineMetrics_networkBuilder get network =>
      _$this._network ??=
          new GMachineMetricsData_machineMetrics_networkBuilder();
  set network(GMachineMetricsData_machineMetrics_networkBuilder? network) =>
      _$this._network = network;

  ListBuilder<GMachineMetricsData_machineMetrics_disks>? _disks;
  ListBuilder<GMachineMetricsData_machineMetrics_disks> get disks =>
      _$this._disks ??=
          new ListBuilder<GMachineMetricsData_machineMetrics_disks>();
  set disks(ListBuilder<GMachineMetricsData_machineMetrics_disks>? disks) =>
      _$this._disks = disks;

  GMachineMetricsData_machineMetricsBuilder() {
    GMachineMetricsData_machineMetrics._initializeBuilder(this);
  }

  GMachineMetricsData_machineMetricsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _G__typename = $v.G__typename;
      _machineId = $v.machineId;
      _hostname = $v.hostname;
      _status = $v.status;
      _timestamp = $v.timestamp;
      _cpu = $v.cpu.toBuilder();
      _memory = $v.memory.toBuilder();
      _network = $v.network.toBuilder();
      _disks = $v.disks.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GMachineMetricsData_machineMetrics other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$GMachineMetricsData_machineMetrics;
  }

  @override
  void update(
      void Function(GMachineMetricsData_machineMetricsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GMachineMetricsData_machineMetrics build() => _build();

  _$GMachineMetricsData_machineMetrics _build() {
    _$GMachineMetricsData_machineMetrics _$result;
    try {
      _$result = _$v ??
          new _$GMachineMetricsData_machineMetrics._(
              G__typename: BuiltValueNullFieldError.checkNotNull(G__typename,
                  r'GMachineMetricsData_machineMetrics', 'G__typename'),
              machineId: BuiltValueNullFieldError.checkNotNull(machineId,
                  r'GMachineMetricsData_machineMetrics', 'machineId'),
              hostname: BuiltValueNullFieldError.checkNotNull(
                  hostname, r'GMachineMetricsData_machineMetrics', 'hostname'),
              status: BuiltValueNullFieldError.checkNotNull(
                  status, r'GMachineMetricsData_machineMetrics', 'status'),
              timestamp: BuiltValueNullFieldError.checkNotNull(timestamp,
                  r'GMachineMetricsData_machineMetrics', 'timestamp'),
              cpu: cpu.build(),
              memory: memory.build(),
              network: network.build(),
              disks: disks.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'cpu';
        cpu.build();
        _$failedField = 'memory';
        memory.build();
        _$failedField = 'network';
        network.build();
        _$failedField = 'disks';
        disks.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'GMachineMetricsData_machineMetrics', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

class _$GMachineMetricsData_machineMetrics_cpu
    extends GMachineMetricsData_machineMetrics_cpu {
  @override
  final String G__typename;
  @override
  final double totalUsagePercent;
  @override
  final double? temperatureC;

  factory _$GMachineMetricsData_machineMetrics_cpu(
          [void Function(GMachineMetricsData_machineMetrics_cpuBuilder)?
              updates]) =>
      (new GMachineMetricsData_machineMetrics_cpuBuilder()..update(updates))
          ._build();

  _$GMachineMetricsData_machineMetrics_cpu._(
      {required this.G__typename,
      required this.totalUsagePercent,
      this.temperatureC})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        G__typename, r'GMachineMetricsData_machineMetrics_cpu', 'G__typename');
    BuiltValueNullFieldError.checkNotNull(totalUsagePercent,
        r'GMachineMetricsData_machineMetrics_cpu', 'totalUsagePercent');
  }

  @override
  GMachineMetricsData_machineMetrics_cpu rebuild(
          void Function(GMachineMetricsData_machineMetrics_cpuBuilder)
              updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GMachineMetricsData_machineMetrics_cpuBuilder toBuilder() =>
      new GMachineMetricsData_machineMetrics_cpuBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GMachineMetricsData_machineMetrics_cpu &&
        G__typename == other.G__typename &&
        totalUsagePercent == other.totalUsagePercent &&
        temperatureC == other.temperatureC;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, G__typename.hashCode);
    _$hash = $jc(_$hash, totalUsagePercent.hashCode);
    _$hash = $jc(_$hash, temperatureC.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
            r'GMachineMetricsData_machineMetrics_cpu')
          ..add('G__typename', G__typename)
          ..add('totalUsagePercent', totalUsagePercent)
          ..add('temperatureC', temperatureC))
        .toString();
  }
}

class GMachineMetricsData_machineMetrics_cpuBuilder
    implements
        Builder<GMachineMetricsData_machineMetrics_cpu,
            GMachineMetricsData_machineMetrics_cpuBuilder> {
  _$GMachineMetricsData_machineMetrics_cpu? _$v;

  String? _G__typename;
  String? get G__typename => _$this._G__typename;
  set G__typename(String? G__typename) => _$this._G__typename = G__typename;

  double? _totalUsagePercent;
  double? get totalUsagePercent => _$this._totalUsagePercent;
  set totalUsagePercent(double? totalUsagePercent) =>
      _$this._totalUsagePercent = totalUsagePercent;

  double? _temperatureC;
  double? get temperatureC => _$this._temperatureC;
  set temperatureC(double? temperatureC) => _$this._temperatureC = temperatureC;

  GMachineMetricsData_machineMetrics_cpuBuilder() {
    GMachineMetricsData_machineMetrics_cpu._initializeBuilder(this);
  }

  GMachineMetricsData_machineMetrics_cpuBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _G__typename = $v.G__typename;
      _totalUsagePercent = $v.totalUsagePercent;
      _temperatureC = $v.temperatureC;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GMachineMetricsData_machineMetrics_cpu other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$GMachineMetricsData_machineMetrics_cpu;
  }

  @override
  void update(
      void Function(GMachineMetricsData_machineMetrics_cpuBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GMachineMetricsData_machineMetrics_cpu build() => _build();

  _$GMachineMetricsData_machineMetrics_cpu _build() {
    final _$result = _$v ??
        new _$GMachineMetricsData_machineMetrics_cpu._(
            G__typename: BuiltValueNullFieldError.checkNotNull(G__typename,
                r'GMachineMetricsData_machineMetrics_cpu', 'G__typename'),
            totalUsagePercent: BuiltValueNullFieldError.checkNotNull(
                totalUsagePercent,
                r'GMachineMetricsData_machineMetrics_cpu',
                'totalUsagePercent'),
            temperatureC: temperatureC);
    replace(_$result);
    return _$result;
  }
}

class _$GMachineMetricsData_machineMetrics_memory
    extends GMachineMetricsData_machineMetrics_memory {
  @override
  final String G__typename;
  @override
  final double totalBytes;
  @override
  final double usedBytes;
  @override
  final double usagePercent;

  factory _$GMachineMetricsData_machineMetrics_memory(
          [void Function(GMachineMetricsData_machineMetrics_memoryBuilder)?
              updates]) =>
      (new GMachineMetricsData_machineMetrics_memoryBuilder()..update(updates))
          ._build();

  _$GMachineMetricsData_machineMetrics_memory._(
      {required this.G__typename,
      required this.totalBytes,
      required this.usedBytes,
      required this.usagePercent})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(G__typename,
        r'GMachineMetricsData_machineMetrics_memory', 'G__typename');
    BuiltValueNullFieldError.checkNotNull(
        totalBytes, r'GMachineMetricsData_machineMetrics_memory', 'totalBytes');
    BuiltValueNullFieldError.checkNotNull(
        usedBytes, r'GMachineMetricsData_machineMetrics_memory', 'usedBytes');
    BuiltValueNullFieldError.checkNotNull(usagePercent,
        r'GMachineMetricsData_machineMetrics_memory', 'usagePercent');
  }

  @override
  GMachineMetricsData_machineMetrics_memory rebuild(
          void Function(GMachineMetricsData_machineMetrics_memoryBuilder)
              updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GMachineMetricsData_machineMetrics_memoryBuilder toBuilder() =>
      new GMachineMetricsData_machineMetrics_memoryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GMachineMetricsData_machineMetrics_memory &&
        G__typename == other.G__typename &&
        totalBytes == other.totalBytes &&
        usedBytes == other.usedBytes &&
        usagePercent == other.usagePercent;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, G__typename.hashCode);
    _$hash = $jc(_$hash, totalBytes.hashCode);
    _$hash = $jc(_$hash, usedBytes.hashCode);
    _$hash = $jc(_$hash, usagePercent.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
            r'GMachineMetricsData_machineMetrics_memory')
          ..add('G__typename', G__typename)
          ..add('totalBytes', totalBytes)
          ..add('usedBytes', usedBytes)
          ..add('usagePercent', usagePercent))
        .toString();
  }
}

class GMachineMetricsData_machineMetrics_memoryBuilder
    implements
        Builder<GMachineMetricsData_machineMetrics_memory,
            GMachineMetricsData_machineMetrics_memoryBuilder> {
  _$GMachineMetricsData_machineMetrics_memory? _$v;

  String? _G__typename;
  String? get G__typename => _$this._G__typename;
  set G__typename(String? G__typename) => _$this._G__typename = G__typename;

  double? _totalBytes;
  double? get totalBytes => _$this._totalBytes;
  set totalBytes(double? totalBytes) => _$this._totalBytes = totalBytes;

  double? _usedBytes;
  double? get usedBytes => _$this._usedBytes;
  set usedBytes(double? usedBytes) => _$this._usedBytes = usedBytes;

  double? _usagePercent;
  double? get usagePercent => _$this._usagePercent;
  set usagePercent(double? usagePercent) => _$this._usagePercent = usagePercent;

  GMachineMetricsData_machineMetrics_memoryBuilder() {
    GMachineMetricsData_machineMetrics_memory._initializeBuilder(this);
  }

  GMachineMetricsData_machineMetrics_memoryBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _G__typename = $v.G__typename;
      _totalBytes = $v.totalBytes;
      _usedBytes = $v.usedBytes;
      _usagePercent = $v.usagePercent;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GMachineMetricsData_machineMetrics_memory other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$GMachineMetricsData_machineMetrics_memory;
  }

  @override
  void update(
      void Function(GMachineMetricsData_machineMetrics_memoryBuilder)?
          updates) {
    if (updates != null) updates(this);
  }

  @override
  GMachineMetricsData_machineMetrics_memory build() => _build();

  _$GMachineMetricsData_machineMetrics_memory _build() {
    final _$result = _$v ??
        new _$GMachineMetricsData_machineMetrics_memory._(
            G__typename: BuiltValueNullFieldError.checkNotNull(G__typename,
                r'GMachineMetricsData_machineMetrics_memory', 'G__typename'),
            totalBytes: BuiltValueNullFieldError.checkNotNull(totalBytes,
                r'GMachineMetricsData_machineMetrics_memory', 'totalBytes'),
            usedBytes: BuiltValueNullFieldError.checkNotNull(usedBytes,
                r'GMachineMetricsData_machineMetrics_memory', 'usedBytes'),
            usagePercent: BuiltValueNullFieldError.checkNotNull(usagePercent,
                r'GMachineMetricsData_machineMetrics_memory', 'usagePercent'));
    replace(_$result);
    return _$result;
  }
}

class _$GMachineMetricsData_machineMetrics_network
    extends GMachineMetricsData_machineMetrics_network {
  @override
  final String G__typename;
  @override
  final double rxBytesPerSec;
  @override
  final double txBytesPerSec;

  factory _$GMachineMetricsData_machineMetrics_network(
          [void Function(GMachineMetricsData_machineMetrics_networkBuilder)?
              updates]) =>
      (new GMachineMetricsData_machineMetrics_networkBuilder()..update(updates))
          ._build();

  _$GMachineMetricsData_machineMetrics_network._(
      {required this.G__typename,
      required this.rxBytesPerSec,
      required this.txBytesPerSec})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(G__typename,
        r'GMachineMetricsData_machineMetrics_network', 'G__typename');
    BuiltValueNullFieldError.checkNotNull(rxBytesPerSec,
        r'GMachineMetricsData_machineMetrics_network', 'rxBytesPerSec');
    BuiltValueNullFieldError.checkNotNull(txBytesPerSec,
        r'GMachineMetricsData_machineMetrics_network', 'txBytesPerSec');
  }

  @override
  GMachineMetricsData_machineMetrics_network rebuild(
          void Function(GMachineMetricsData_machineMetrics_networkBuilder)
              updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GMachineMetricsData_machineMetrics_networkBuilder toBuilder() =>
      new GMachineMetricsData_machineMetrics_networkBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GMachineMetricsData_machineMetrics_network &&
        G__typename == other.G__typename &&
        rxBytesPerSec == other.rxBytesPerSec &&
        txBytesPerSec == other.txBytesPerSec;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, G__typename.hashCode);
    _$hash = $jc(_$hash, rxBytesPerSec.hashCode);
    _$hash = $jc(_$hash, txBytesPerSec.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
            r'GMachineMetricsData_machineMetrics_network')
          ..add('G__typename', G__typename)
          ..add('rxBytesPerSec', rxBytesPerSec)
          ..add('txBytesPerSec', txBytesPerSec))
        .toString();
  }
}

class GMachineMetricsData_machineMetrics_networkBuilder
    implements
        Builder<GMachineMetricsData_machineMetrics_network,
            GMachineMetricsData_machineMetrics_networkBuilder> {
  _$GMachineMetricsData_machineMetrics_network? _$v;

  String? _G__typename;
  String? get G__typename => _$this._G__typename;
  set G__typename(String? G__typename) => _$this._G__typename = G__typename;

  double? _rxBytesPerSec;
  double? get rxBytesPerSec => _$this._rxBytesPerSec;
  set rxBytesPerSec(double? rxBytesPerSec) =>
      _$this._rxBytesPerSec = rxBytesPerSec;

  double? _txBytesPerSec;
  double? get txBytesPerSec => _$this._txBytesPerSec;
  set txBytesPerSec(double? txBytesPerSec) =>
      _$this._txBytesPerSec = txBytesPerSec;

  GMachineMetricsData_machineMetrics_networkBuilder() {
    GMachineMetricsData_machineMetrics_network._initializeBuilder(this);
  }

  GMachineMetricsData_machineMetrics_networkBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _G__typename = $v.G__typename;
      _rxBytesPerSec = $v.rxBytesPerSec;
      _txBytesPerSec = $v.txBytesPerSec;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GMachineMetricsData_machineMetrics_network other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$GMachineMetricsData_machineMetrics_network;
  }

  @override
  void update(
      void Function(GMachineMetricsData_machineMetrics_networkBuilder)?
          updates) {
    if (updates != null) updates(this);
  }

  @override
  GMachineMetricsData_machineMetrics_network build() => _build();

  _$GMachineMetricsData_machineMetrics_network _build() {
    final _$result = _$v ??
        new _$GMachineMetricsData_machineMetrics_network._(
            G__typename: BuiltValueNullFieldError.checkNotNull(G__typename,
                r'GMachineMetricsData_machineMetrics_network', 'G__typename'),
            rxBytesPerSec: BuiltValueNullFieldError.checkNotNull(rxBytesPerSec,
                r'GMachineMetricsData_machineMetrics_network', 'rxBytesPerSec'),
            txBytesPerSec: BuiltValueNullFieldError.checkNotNull(
                txBytesPerSec,
                r'GMachineMetricsData_machineMetrics_network',
                'txBytesPerSec'));
    replace(_$result);
    return _$result;
  }
}

class _$GMachineMetricsData_machineMetrics_disks
    extends GMachineMetricsData_machineMetrics_disks {
  @override
  final String G__typename;
  @override
  final String mountPoint;
  @override
  final String fsType;
  @override
  final double totalBytes;
  @override
  final double freeBytes;
  @override
  final double usagePercent;

  factory _$GMachineMetricsData_machineMetrics_disks(
          [void Function(GMachineMetricsData_machineMetrics_disksBuilder)?
              updates]) =>
      (new GMachineMetricsData_machineMetrics_disksBuilder()..update(updates))
          ._build();

  _$GMachineMetricsData_machineMetrics_disks._(
      {required this.G__typename,
      required this.mountPoint,
      required this.fsType,
      required this.totalBytes,
      required this.freeBytes,
      required this.usagePercent})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(G__typename,
        r'GMachineMetricsData_machineMetrics_disks', 'G__typename');
    BuiltValueNullFieldError.checkNotNull(
        mountPoint, r'GMachineMetricsData_machineMetrics_disks', 'mountPoint');
    BuiltValueNullFieldError.checkNotNull(
        fsType, r'GMachineMetricsData_machineMetrics_disks', 'fsType');
    BuiltValueNullFieldError.checkNotNull(
        totalBytes, r'GMachineMetricsData_machineMetrics_disks', 'totalBytes');
    BuiltValueNullFieldError.checkNotNull(
        freeBytes, r'GMachineMetricsData_machineMetrics_disks', 'freeBytes');
    BuiltValueNullFieldError.checkNotNull(usagePercent,
        r'GMachineMetricsData_machineMetrics_disks', 'usagePercent');
  }

  @override
  GMachineMetricsData_machineMetrics_disks rebuild(
          void Function(GMachineMetricsData_machineMetrics_disksBuilder)
              updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GMachineMetricsData_machineMetrics_disksBuilder toBuilder() =>
      new GMachineMetricsData_machineMetrics_disksBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GMachineMetricsData_machineMetrics_disks &&
        G__typename == other.G__typename &&
        mountPoint == other.mountPoint &&
        fsType == other.fsType &&
        totalBytes == other.totalBytes &&
        freeBytes == other.freeBytes &&
        usagePercent == other.usagePercent;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, G__typename.hashCode);
    _$hash = $jc(_$hash, mountPoint.hashCode);
    _$hash = $jc(_$hash, fsType.hashCode);
    _$hash = $jc(_$hash, totalBytes.hashCode);
    _$hash = $jc(_$hash, freeBytes.hashCode);
    _$hash = $jc(_$hash, usagePercent.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
            r'GMachineMetricsData_machineMetrics_disks')
          ..add('G__typename', G__typename)
          ..add('mountPoint', mountPoint)
          ..add('fsType', fsType)
          ..add('totalBytes', totalBytes)
          ..add('freeBytes', freeBytes)
          ..add('usagePercent', usagePercent))
        .toString();
  }
}

class GMachineMetricsData_machineMetrics_disksBuilder
    implements
        Builder<GMachineMetricsData_machineMetrics_disks,
            GMachineMetricsData_machineMetrics_disksBuilder> {
  _$GMachineMetricsData_machineMetrics_disks? _$v;

  String? _G__typename;
  String? get G__typename => _$this._G__typename;
  set G__typename(String? G__typename) => _$this._G__typename = G__typename;

  String? _mountPoint;
  String? get mountPoint => _$this._mountPoint;
  set mountPoint(String? mountPoint) => _$this._mountPoint = mountPoint;

  String? _fsType;
  String? get fsType => _$this._fsType;
  set fsType(String? fsType) => _$this._fsType = fsType;

  double? _totalBytes;
  double? get totalBytes => _$this._totalBytes;
  set totalBytes(double? totalBytes) => _$this._totalBytes = totalBytes;

  double? _freeBytes;
  double? get freeBytes => _$this._freeBytes;
  set freeBytes(double? freeBytes) => _$this._freeBytes = freeBytes;

  double? _usagePercent;
  double? get usagePercent => _$this._usagePercent;
  set usagePercent(double? usagePercent) => _$this._usagePercent = usagePercent;

  GMachineMetricsData_machineMetrics_disksBuilder() {
    GMachineMetricsData_machineMetrics_disks._initializeBuilder(this);
  }

  GMachineMetricsData_machineMetrics_disksBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _G__typename = $v.G__typename;
      _mountPoint = $v.mountPoint;
      _fsType = $v.fsType;
      _totalBytes = $v.totalBytes;
      _freeBytes = $v.freeBytes;
      _usagePercent = $v.usagePercent;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GMachineMetricsData_machineMetrics_disks other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$GMachineMetricsData_machineMetrics_disks;
  }

  @override
  void update(
      void Function(GMachineMetricsData_machineMetrics_disksBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GMachineMetricsData_machineMetrics_disks build() => _build();

  _$GMachineMetricsData_machineMetrics_disks _build() {
    final _$result = _$v ??
        new _$GMachineMetricsData_machineMetrics_disks._(
            G__typename: BuiltValueNullFieldError.checkNotNull(G__typename,
                r'GMachineMetricsData_machineMetrics_disks', 'G__typename'),
            mountPoint: BuiltValueNullFieldError.checkNotNull(
                mountPoint, r'GMachineMetricsData_machineMetrics_disks', 'mountPoint'),
            fsType: BuiltValueNullFieldError.checkNotNull(
                fsType, r'GMachineMetricsData_machineMetrics_disks', 'fsType'),
            totalBytes: BuiltValueNullFieldError.checkNotNull(
                totalBytes, r'GMachineMetricsData_machineMetrics_disks', 'totalBytes'),
            freeBytes: BuiltValueNullFieldError.checkNotNull(
                freeBytes, r'GMachineMetricsData_machineMetrics_disks', 'freeBytes'),
            usagePercent: BuiltValueNullFieldError.checkNotNull(usagePercent,
                r'GMachineMetricsData_machineMetrics_disks', 'usagePercent'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
