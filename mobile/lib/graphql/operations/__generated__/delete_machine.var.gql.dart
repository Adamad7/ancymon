// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:ancymon_mobile/graphql/__generated__/serializers.gql.dart'
    as _i1;
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'delete_machine.var.gql.g.dart';

abstract class GDeleteMachineVars
    implements Built<GDeleteMachineVars, GDeleteMachineVarsBuilder> {
  GDeleteMachineVars._();

  factory GDeleteMachineVars(
          [void Function(GDeleteMachineVarsBuilder b) updates]) =
      _$GDeleteMachineVars;

  String get machineId;
  static Serializer<GDeleteMachineVars> get serializer =>
      _$gDeleteMachineVarsSerializer;

  Map<String, dynamic> toJson() => (_i1.serializers.serializeWith(
        GDeleteMachineVars.serializer,
        this,
      ) as Map<String, dynamic>);

  static GDeleteMachineVars? fromJson(Map<String, dynamic> json) =>
      _i1.serializers.deserializeWith(
        GDeleteMachineVars.serializer,
        json,
      );
}
