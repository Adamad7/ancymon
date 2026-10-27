// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:ancymon_mobile/graphql/__generated__/serializers.gql.dart'
    as _i6;
import 'package:ancymon_mobile/graphql/operations/__generated__/delete_machine.ast.gql.dart'
    as _i5;
import 'package:ancymon_mobile/graphql/operations/__generated__/delete_machine.data.gql.dart'
    as _i2;
import 'package:ancymon_mobile/graphql/operations/__generated__/delete_machine.var.gql.dart'
    as _i3;
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:ferry_exec/ferry_exec.dart' as _i1;
import 'package:gql_exec/gql_exec.dart' as _i4;

part 'delete_machine.req.gql.g.dart';

abstract class GDeleteMachineReq
    implements
        Built<GDeleteMachineReq, GDeleteMachineReqBuilder>,
        _i1.OperationRequest<_i2.GDeleteMachineData, _i3.GDeleteMachineVars> {
  GDeleteMachineReq._();

  factory GDeleteMachineReq(
          [void Function(GDeleteMachineReqBuilder b) updates]) =
      _$GDeleteMachineReq;

  static void _initializeBuilder(GDeleteMachineReqBuilder b) => b
    ..operation = _i4.Operation(
      document: _i5.document,
      operationName: 'DeleteMachine',
    )
    ..executeOnListen = true;

  @override
  _i3.GDeleteMachineVars get vars;
  @override
  _i4.Operation get operation;
  @override
  _i4.Request get execRequest => _i4.Request(
        operation: operation,
        variables: vars.toJson(),
        context: context ?? const _i4.Context(),
      );

  @override
  String? get requestId;
  @override
  @BuiltValueField(serialize: false)
  _i2.GDeleteMachineData? Function(
    _i2.GDeleteMachineData?,
    _i2.GDeleteMachineData?,
  )? get updateResult;
  @override
  _i2.GDeleteMachineData? get optimisticResponse;
  @override
  String? get updateCacheHandlerKey;
  @override
  Map<String, dynamic>? get updateCacheHandlerContext;
  @override
  _i1.FetchPolicy? get fetchPolicy;
  @override
  bool get executeOnListen;
  @override
  @BuiltValueField(serialize: false)
  _i4.Context? get context;
  @override
  _i2.GDeleteMachineData? parseData(Map<String, dynamic> json) =>
      _i2.GDeleteMachineData.fromJson(json);

  @override
  Map<String, dynamic> varsToJson() => vars.toJson();

  @override
  Map<String, dynamic> dataToJson(_i2.GDeleteMachineData data) => data.toJson();

  @override
  _i1.OperationRequest<_i2.GDeleteMachineData, _i3.GDeleteMachineVars>
      transformOperation(_i4.Operation Function(_i4.Operation) transform) =>
          this.rebuild((b) => b..operation = transform(operation));

  static Serializer<GDeleteMachineReq> get serializer =>
      _$gDeleteMachineReqSerializer;

  Map<String, dynamic> toJson() => (_i6.serializers.serializeWith(
        GDeleteMachineReq.serializer,
        this,
      ) as Map<String, dynamic>);

  static GDeleteMachineReq? fromJson(Map<String, dynamic> json) =>
      _i6.serializers.deserializeWith(
        GDeleteMachineReq.serializer,
        json,
      );
}
