// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:ancymon_mobile/graphql/__generated__/serializers.gql.dart'
    as _i1;
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'fleet_summary.var.gql.g.dart';

abstract class GFleetSummaryVars
    implements Built<GFleetSummaryVars, GFleetSummaryVarsBuilder> {
  GFleetSummaryVars._();

  factory GFleetSummaryVars(
          [void Function(GFleetSummaryVarsBuilder b) updates]) =
      _$GFleetSummaryVars;

  static Serializer<GFleetSummaryVars> get serializer =>
      _$gFleetSummaryVarsSerializer;

  Map<String, dynamic> toJson() => (_i1.serializers.serializeWith(
        GFleetSummaryVars.serializer,
        this,
      ) as Map<String, dynamic>);

  static GFleetSummaryVars? fromJson(Map<String, dynamic> json) =>
      _i1.serializers.deserializeWith(
        GFleetSummaryVars.serializer,
        json,
      );
}
