// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_machine.data.gql.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<GDeleteMachineData> _$gDeleteMachineDataSerializer =
    new _$GDeleteMachineDataSerializer();

class _$GDeleteMachineDataSerializer
    implements StructuredSerializer<GDeleteMachineData> {
  @override
  final Iterable<Type> types = const [GDeleteMachineData, _$GDeleteMachineData];
  @override
  final String wireName = 'GDeleteMachineData';

  @override
  Iterable<Object?> serialize(
      Serializers serializers, GDeleteMachineData object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      '__typename',
      serializers.serialize(object.G__typename,
          specifiedType: const FullType(String)),
      'deleteMachine',
      serializers.serialize(object.deleteMachine,
          specifiedType: const FullType(bool)),
    ];

    return result;
  }

  @override
  GDeleteMachineData deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new GDeleteMachineDataBuilder();

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
        case 'deleteMachine':
          result.deleteMachine = serializers.deserialize(value,
              specifiedType: const FullType(bool))! as bool;
          break;
      }
    }

    return result.build();
  }
}

class _$GDeleteMachineData extends GDeleteMachineData {
  @override
  final String G__typename;
  @override
  final bool deleteMachine;

  factory _$GDeleteMachineData(
          [void Function(GDeleteMachineDataBuilder)? updates]) =>
      (new GDeleteMachineDataBuilder()..update(updates))._build();

  _$GDeleteMachineData._(
      {required this.G__typename, required this.deleteMachine})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        G__typename, r'GDeleteMachineData', 'G__typename');
    BuiltValueNullFieldError.checkNotNull(
        deleteMachine, r'GDeleteMachineData', 'deleteMachine');
  }

  @override
  GDeleteMachineData rebuild(
          void Function(GDeleteMachineDataBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GDeleteMachineDataBuilder toBuilder() =>
      new GDeleteMachineDataBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GDeleteMachineData &&
        G__typename == other.G__typename &&
        deleteMachine == other.deleteMachine;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, G__typename.hashCode);
    _$hash = $jc(_$hash, deleteMachine.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GDeleteMachineData')
          ..add('G__typename', G__typename)
          ..add('deleteMachine', deleteMachine))
        .toString();
  }
}

class GDeleteMachineDataBuilder
    implements Builder<GDeleteMachineData, GDeleteMachineDataBuilder> {
  _$GDeleteMachineData? _$v;

  String? _G__typename;
  String? get G__typename => _$this._G__typename;
  set G__typename(String? G__typename) => _$this._G__typename = G__typename;

  bool? _deleteMachine;
  bool? get deleteMachine => _$this._deleteMachine;
  set deleteMachine(bool? deleteMachine) =>
      _$this._deleteMachine = deleteMachine;

  GDeleteMachineDataBuilder() {
    GDeleteMachineData._initializeBuilder(this);
  }

  GDeleteMachineDataBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _G__typename = $v.G__typename;
      _deleteMachine = $v.deleteMachine;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GDeleteMachineData other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$GDeleteMachineData;
  }

  @override
  void update(void Function(GDeleteMachineDataBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GDeleteMachineData build() => _build();

  _$GDeleteMachineData _build() {
    final _$result = _$v ??
        new _$GDeleteMachineData._(
            G__typename: BuiltValueNullFieldError.checkNotNull(
                G__typename, r'GDeleteMachineData', 'G__typename'),
            deleteMachine: BuiltValueNullFieldError.checkNotNull(
                deleteMachine, r'GDeleteMachineData', 'deleteMachine'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
