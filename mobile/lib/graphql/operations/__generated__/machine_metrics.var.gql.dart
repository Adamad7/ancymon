// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:ancymon_mobile/graphql/__generated__/serializers.gql.dart'
    as _i1;
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'machine_metrics.var.gql.g.dart';

abstract class GMachineMetricsVars
    implements Built<GMachineMetricsVars, GMachineMetricsVarsBuilder> {
  GMachineMetricsVars._();

  factory GMachineMetricsVars(
          [void Function(GMachineMetricsVarsBuilder b) updates]) =
      _$GMachineMetricsVars;

  String get machineId;
  static Serializer<GMachineMetricsVars> get serializer =>
      _$gMachineMetricsVarsSerializer;

  Map<String, dynamic> toJson() => (_i1.serializers.serializeWith(
        GMachineMetricsVars.serializer,
        this,
      ) as Map<String, dynamic>);

  static GMachineMetricsVars? fromJson(Map<String, dynamic> json) =>
      _i1.serializers.deserializeWith(
        GMachineMetricsVars.serializer,
        json,
      );
}
