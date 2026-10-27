// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'machine_metrics.var.gql.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<GMachineMetricsVars> _$gMachineMetricsVarsSerializer =
    new _$GMachineMetricsVarsSerializer();

class _$GMachineMetricsVarsSerializer
    implements StructuredSerializer<GMachineMetricsVars> {
  @override
  final Iterable<Type> types = const [
    GMachineMetricsVars,
    _$GMachineMetricsVars
  ];
  @override
  final String wireName = 'GMachineMetricsVars';

  @override
  Iterable<Object?> serialize(
      Serializers serializers, GMachineMetricsVars object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'machineId',
      serializers.serialize(object.machineId,
          specifiedType: const FullType(String)),
    ];

    return result;
  }

  @override
  GMachineMetricsVars deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new GMachineMetricsVarsBuilder();

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
      }
    }

    return result.build();
  }
}

class _$GMachineMetricsVars extends GMachineMetricsVars {
  @override
  final String machineId;

  factory _$GMachineMetricsVars(
          [void Function(GMachineMetricsVarsBuilder)? updates]) =>
      (new GMachineMetricsVarsBuilder()..update(updates))._build();

  _$GMachineMetricsVars._({required this.machineId}) : super._() {
    BuiltValueNullFieldError.checkNotNull(
        machineId, r'GMachineMetricsVars', 'machineId');
  }

  @override
  GMachineMetricsVars rebuild(
          void Function(GMachineMetricsVarsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GMachineMetricsVarsBuilder toBuilder() =>
      new GMachineMetricsVarsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GMachineMetricsVars && machineId == other.machineId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, machineId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GMachineMetricsVars')
          ..add('machineId', machineId))
        .toString();
  }
}

class GMachineMetricsVarsBuilder
    implements Builder<GMachineMetricsVars, GMachineMetricsVarsBuilder> {
  _$GMachineMetricsVars? _$v;

  String? _machineId;
  String? get machineId => _$this._machineId;
  set machineId(String? machineId) => _$this._machineId = machineId;

  GMachineMetricsVarsBuilder();

  GMachineMetricsVarsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _machineId = $v.machineId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GMachineMetricsVars other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$GMachineMetricsVars;
  }

  @override
  void update(void Function(GMachineMetricsVarsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GMachineMetricsVars build() => _build();

  _$GMachineMetricsVars _build() {
    final _$result = _$v ??
        new _$GMachineMetricsVars._(
            machineId: BuiltValueNullFieldError.checkNotNull(
                machineId, r'GMachineMetricsVars', 'machineId'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
