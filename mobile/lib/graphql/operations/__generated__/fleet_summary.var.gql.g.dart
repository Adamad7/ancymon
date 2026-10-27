// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fleet_summary.var.gql.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<GFleetSummaryVars> _$gFleetSummaryVarsSerializer =
    new _$GFleetSummaryVarsSerializer();

class _$GFleetSummaryVarsSerializer
    implements StructuredSerializer<GFleetSummaryVars> {
  @override
  final Iterable<Type> types = const [GFleetSummaryVars, _$GFleetSummaryVars];
  @override
  final String wireName = 'GFleetSummaryVars';

  @override
  Iterable<Object?> serialize(Serializers serializers, GFleetSummaryVars object,
      {FullType specifiedType = FullType.unspecified}) {
    return <Object?>[];
  }

  @override
  GFleetSummaryVars deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    return new GFleetSummaryVarsBuilder().build();
  }
}

class _$GFleetSummaryVars extends GFleetSummaryVars {
  factory _$GFleetSummaryVars(
          [void Function(GFleetSummaryVarsBuilder)? updates]) =>
      (new GFleetSummaryVarsBuilder()..update(updates))._build();

  _$GFleetSummaryVars._() : super._();

  @override
  GFleetSummaryVars rebuild(void Function(GFleetSummaryVarsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GFleetSummaryVarsBuilder toBuilder() =>
      new GFleetSummaryVarsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GFleetSummaryVars;
  }

  @override
  int get hashCode {
    return 1036149806;
  }

  @override
  String toString() {
    return newBuiltValueToStringHelper(r'GFleetSummaryVars').toString();
  }
}

class GFleetSummaryVarsBuilder
    implements Builder<GFleetSummaryVars, GFleetSummaryVarsBuilder> {
  _$GFleetSummaryVars? _$v;

  GFleetSummaryVarsBuilder();

  @override
  void replace(GFleetSummaryVars other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$GFleetSummaryVars;
  }

  @override
  void update(void Function(GFleetSummaryVarsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GFleetSummaryVars build() => _build();

  _$GFleetSummaryVars _build() {
    final _$result = _$v ?? new _$GFleetSummaryVars._();
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
