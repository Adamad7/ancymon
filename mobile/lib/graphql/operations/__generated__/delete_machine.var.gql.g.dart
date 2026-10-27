// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_machine.var.gql.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<GDeleteMachineVars> _$gDeleteMachineVarsSerializer =
    new _$GDeleteMachineVarsSerializer();

class _$GDeleteMachineVarsSerializer
    implements StructuredSerializer<GDeleteMachineVars> {
  @override
  final Iterable<Type> types = const [GDeleteMachineVars, _$GDeleteMachineVars];
  @override
  final String wireName = 'GDeleteMachineVars';

  @override
  Iterable<Object?> serialize(
      Serializers serializers, GDeleteMachineVars object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'machineId',
      serializers.serialize(object.machineId,
          specifiedType: const FullType(String)),
    ];

    return result;
  }

  @override
  GDeleteMachineVars deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new GDeleteMachineVarsBuilder();

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

class _$GDeleteMachineVars extends GDeleteMachineVars {
  @override
  final String machineId;

  factory _$GDeleteMachineVars(
          [void Function(GDeleteMachineVarsBuilder)? updates]) =>
      (new GDeleteMachineVarsBuilder()..update(updates))._build();

  _$GDeleteMachineVars._({required this.machineId}) : super._() {
    BuiltValueNullFieldError.checkNotNull(
        machineId, r'GDeleteMachineVars', 'machineId');
  }

  @override
  GDeleteMachineVars rebuild(
          void Function(GDeleteMachineVarsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GDeleteMachineVarsBuilder toBuilder() =>
      new GDeleteMachineVarsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GDeleteMachineVars && machineId == other.machineId;
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
    return (newBuiltValueToStringHelper(r'GDeleteMachineVars')
          ..add('machineId', machineId))
        .toString();
  }
}

class GDeleteMachineVarsBuilder
    implements Builder<GDeleteMachineVars, GDeleteMachineVarsBuilder> {
  _$GDeleteMachineVars? _$v;

  String? _machineId;
  String? get machineId => _$this._machineId;
  set machineId(String? machineId) => _$this._machineId = machineId;

  GDeleteMachineVarsBuilder();

  GDeleteMachineVarsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _machineId = $v.machineId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GDeleteMachineVars other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$GDeleteMachineVars;
  }

  @override
  void update(void Function(GDeleteMachineVarsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GDeleteMachineVars build() => _build();

  _$GDeleteMachineVars _build() {
    final _$result = _$v ??
        new _$GDeleteMachineVars._(
            machineId: BuiltValueNullFieldError.checkNotNull(
                machineId, r'GDeleteMachineVars', 'machineId'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
