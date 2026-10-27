// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history.data.gql.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<GMachineHistoryData> _$gMachineHistoryDataSerializer =
    new _$GMachineHistoryDataSerializer();
Serializer<GMachineHistoryData_machineHistory>
    _$gMachineHistoryDataMachineHistorySerializer =
    new _$GMachineHistoryData_machineHistorySerializer();

class _$GMachineHistoryDataSerializer
    implements StructuredSerializer<GMachineHistoryData> {
  @override
  final Iterable<Type> types = const [
    GMachineHistoryData,
    _$GMachineHistoryData
  ];
  @override
  final String wireName = 'GMachineHistoryData';

  @override
  Iterable<Object?> serialize(
      Serializers serializers, GMachineHistoryData object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      '__typename',
      serializers.serialize(object.G__typename,
          specifiedType: const FullType(String)),
      'machineHistory',
      serializers.serialize(object.machineHistory,
          specifiedType: const FullType(BuiltList,
              const [const FullType(GMachineHistoryData_machineHistory)])),
    ];

    return result;
  }

  @override
  GMachineHistoryData deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new GMachineHistoryDataBuilder();

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
        case 'machineHistory':
          result.machineHistory.replace(serializers.deserialize(value,
              specifiedType: const FullType(BuiltList, const [
                const FullType(GMachineHistoryData_machineHistory)
              ]))! as BuiltList<Object?>);
          break;
      }
    }

    return result.build();
  }
}

class _$GMachineHistoryData_machineHistorySerializer
    implements StructuredSerializer<GMachineHistoryData_machineHistory> {
  @override
  final Iterable<Type> types = const [
    GMachineHistoryData_machineHistory,
    _$GMachineHistoryData_machineHistory
  ];
  @override
  final String wireName = 'GMachineHistoryData_machineHistory';

  @override
  Iterable<Object?> serialize(
      Serializers serializers, GMachineHistoryData_machineHistory object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      '__typename',
      serializers.serialize(object.G__typename,
          specifiedType: const FullType(String)),
      'timestamp',
      serializers.serialize(object.timestamp,
          specifiedType: const FullType(int)),
      'value',
      serializers.serialize(object.value,
          specifiedType: const FullType(double)),
    ];

    return result;
  }

  @override
  GMachineHistoryData_machineHistory deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new GMachineHistoryData_machineHistoryBuilder();

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
        case 'timestamp':
          result.timestamp = serializers.deserialize(value,
              specifiedType: const FullType(int))! as int;
          break;
        case 'value':
          result.value = serializers.deserialize(value,
              specifiedType: const FullType(double))! as double;
          break;
      }
    }

    return result.build();
  }
}

class _$GMachineHistoryData extends GMachineHistoryData {
  @override
  final String G__typename;
  @override
  final BuiltList<GMachineHistoryData_machineHistory> machineHistory;

  factory _$GMachineHistoryData(
          [void Function(GMachineHistoryDataBuilder)? updates]) =>
      (new GMachineHistoryDataBuilder()..update(updates))._build();

  _$GMachineHistoryData._(
      {required this.G__typename, required this.machineHistory})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        G__typename, r'GMachineHistoryData', 'G__typename');
    BuiltValueNullFieldError.checkNotNull(
        machineHistory, r'GMachineHistoryData', 'machineHistory');
  }

  @override
  GMachineHistoryData rebuild(
          void Function(GMachineHistoryDataBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GMachineHistoryDataBuilder toBuilder() =>
      new GMachineHistoryDataBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GMachineHistoryData &&
        G__typename == other.G__typename &&
        machineHistory == other.machineHistory;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, G__typename.hashCode);
    _$hash = $jc(_$hash, machineHistory.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GMachineHistoryData')
          ..add('G__typename', G__typename)
          ..add('machineHistory', machineHistory))
        .toString();
  }
}

class GMachineHistoryDataBuilder
    implements Builder<GMachineHistoryData, GMachineHistoryDataBuilder> {
  _$GMachineHistoryData? _$v;

  String? _G__typename;
  String? get G__typename => _$this._G__typename;
  set G__typename(String? G__typename) => _$this._G__typename = G__typename;

  ListBuilder<GMachineHistoryData_machineHistory>? _machineHistory;
  ListBuilder<GMachineHistoryData_machineHistory> get machineHistory =>
      _$this._machineHistory ??=
          new ListBuilder<GMachineHistoryData_machineHistory>();
  set machineHistory(
          ListBuilder<GMachineHistoryData_machineHistory>? machineHistory) =>
      _$this._machineHistory = machineHistory;

  GMachineHistoryDataBuilder() {
    GMachineHistoryData._initializeBuilder(this);
  }

  GMachineHistoryDataBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _G__typename = $v.G__typename;
      _machineHistory = $v.machineHistory.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GMachineHistoryData other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$GMachineHistoryData;
  }

  @override
  void update(void Function(GMachineHistoryDataBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GMachineHistoryData build() => _build();

  _$GMachineHistoryData _build() {
    _$GMachineHistoryData _$result;
    try {
      _$result = _$v ??
          new _$GMachineHistoryData._(
              G__typename: BuiltValueNullFieldError.checkNotNull(
                  G__typename, r'GMachineHistoryData', 'G__typename'),
              machineHistory: machineHistory.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'machineHistory';
        machineHistory.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'GMachineHistoryData', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

class _$GMachineHistoryData_machineHistory
    extends GMachineHistoryData_machineHistory {
  @override
  final String G__typename;
  @override
  final int timestamp;
  @override
  final double value;

  factory _$GMachineHistoryData_machineHistory(
          [void Function(GMachineHistoryData_machineHistoryBuilder)?
              updates]) =>
      (new GMachineHistoryData_machineHistoryBuilder()..update(updates))
          ._build();

  _$GMachineHistoryData_machineHistory._(
      {required this.G__typename, required this.timestamp, required this.value})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        G__typename, r'GMachineHistoryData_machineHistory', 'G__typename');
    BuiltValueNullFieldError.checkNotNull(
        timestamp, r'GMachineHistoryData_machineHistory', 'timestamp');
    BuiltValueNullFieldError.checkNotNull(
        value, r'GMachineHistoryData_machineHistory', 'value');
  }

  @override
  GMachineHistoryData_machineHistory rebuild(
          void Function(GMachineHistoryData_machineHistoryBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GMachineHistoryData_machineHistoryBuilder toBuilder() =>
      new GMachineHistoryData_machineHistoryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GMachineHistoryData_machineHistory &&
        G__typename == other.G__typename &&
        timestamp == other.timestamp &&
        value == other.value;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, G__typename.hashCode);
    _$hash = $jc(_$hash, timestamp.hashCode);
    _$hash = $jc(_$hash, value.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GMachineHistoryData_machineHistory')
          ..add('G__typename', G__typename)
          ..add('timestamp', timestamp)
          ..add('value', value))
        .toString();
  }
}

class GMachineHistoryData_machineHistoryBuilder
    implements
        Builder<GMachineHistoryData_machineHistory,
            GMachineHistoryData_machineHistoryBuilder> {
  _$GMachineHistoryData_machineHistory? _$v;

  String? _G__typename;
  String? get G__typename => _$this._G__typename;
  set G__typename(String? G__typename) => _$this._G__typename = G__typename;

  int? _timestamp;
  int? get timestamp => _$this._timestamp;
  set timestamp(int? timestamp) => _$this._timestamp = timestamp;

  double? _value;
  double? get value => _$this._value;
  set value(double? value) => _$this._value = value;

  GMachineHistoryData_machineHistoryBuilder() {
    GMachineHistoryData_machineHistory._initializeBuilder(this);
  }

  GMachineHistoryData_machineHistoryBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _G__typename = $v.G__typename;
      _timestamp = $v.timestamp;
      _value = $v.value;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GMachineHistoryData_machineHistory other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$GMachineHistoryData_machineHistory;
  }

  @override
  void update(
      void Function(GMachineHistoryData_machineHistoryBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GMachineHistoryData_machineHistory build() => _build();

  _$GMachineHistoryData_machineHistory _build() {
    final _$result = _$v ??
        new _$GMachineHistoryData_machineHistory._(
            G__typename: BuiltValueNullFieldError.checkNotNull(G__typename,
                r'GMachineHistoryData_machineHistory', 'G__typename'),
            timestamp: BuiltValueNullFieldError.checkNotNull(
                timestamp, r'GMachineHistoryData_machineHistory', 'timestamp'),
            value: BuiltValueNullFieldError.checkNotNull(
                value, r'GMachineHistoryData_machineHistory', 'value'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
