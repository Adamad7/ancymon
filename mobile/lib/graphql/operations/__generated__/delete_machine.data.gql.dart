// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:ancymon_mobile/graphql/__generated__/serializers.gql.dart'
    as _i1;
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'delete_machine.data.gql.g.dart';

abstract class GDeleteMachineData
    implements Built<GDeleteMachineData, GDeleteMachineDataBuilder> {
  GDeleteMachineData._();

  factory GDeleteMachineData(
          [void Function(GDeleteMachineDataBuilder b) updates]) =
      _$GDeleteMachineData;

  static void _initializeBuilder(GDeleteMachineDataBuilder b) =>
      b..G__typename = 'Mutation';

  @BuiltValueField(wireName: '__typename')
  String get G__typename;
  bool get deleteMachine;
  static Serializer<GDeleteMachineData> get serializer =>
      _$gDeleteMachineDataSerializer;

  Map<String, dynamic> toJson() => (_i1.serializers.serializeWith(
        GDeleteMachineData.serializer,
        this,
      ) as Map<String, dynamic>);

  static GDeleteMachineData? fromJson(Map<String, dynamic> json) =>
      _i1.serializers.deserializeWith(
        GDeleteMachineData.serializer,
        json,
      );
}
