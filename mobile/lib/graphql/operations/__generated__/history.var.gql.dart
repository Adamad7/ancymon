// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:ancymon_mobile/graphql/__generated__/schema.schema.gql.dart'
    as _i1;
import 'package:ancymon_mobile/graphql/__generated__/serializers.gql.dart'
    as _i2;
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'history.var.gql.g.dart';

abstract class GMachineHistoryVars
    implements Built<GMachineHistoryVars, GMachineHistoryVarsBuilder> {
  GMachineHistoryVars._();

  factory GMachineHistoryVars(
          [void Function(GMachineHistoryVarsBuilder b) updates]) =
      _$GMachineHistoryVars;

  String get machineId;
  _i1.GMetricType get metric;
  _i1.GTimeRange get range;
  String? get date;
  static Serializer<GMachineHistoryVars> get serializer =>
      _$gMachineHistoryVarsSerializer;

  Map<String, dynamic> toJson() => (_i2.serializers.serializeWith(
        GMachineHistoryVars.serializer,
        this,
      ) as Map<String, dynamic>);

  static GMachineHistoryVars? fromJson(Map<String, dynamic> json) =>
      _i2.serializers.deserializeWith(
        GMachineHistoryVars.serializer,
        json,
      );
}
