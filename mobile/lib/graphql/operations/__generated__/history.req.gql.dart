// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:ancymon_mobile/graphql/__generated__/serializers.gql.dart'
    as _i6;
import 'package:ancymon_mobile/graphql/operations/__generated__/history.ast.gql.dart'
    as _i5;
import 'package:ancymon_mobile/graphql/operations/__generated__/history.data.gql.dart'
    as _i2;
import 'package:ancymon_mobile/graphql/operations/__generated__/history.var.gql.dart'
    as _i3;
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:ferry_exec/ferry_exec.dart' as _i1;
import 'package:gql_exec/gql_exec.dart' as _i4;

part 'history.req.gql.g.dart';

abstract class GMachineHistoryReq
    implements
        Built<GMachineHistoryReq, GMachineHistoryReqBuilder>,
        _i1.OperationRequest<_i2.GMachineHistoryData, _i3.GMachineHistoryVars> {
  GMachineHistoryReq._();

  factory GMachineHistoryReq(
          [void Function(GMachineHistoryReqBuilder b) updates]) =
      _$GMachineHistoryReq;

  static void _initializeBuilder(GMachineHistoryReqBuilder b) => b
    ..operation = _i4.Operation(
      document: _i5.document,
      operationName: 'MachineHistory',
    )
    ..executeOnListen = true;

  @override
  _i3.GMachineHistoryVars get vars;
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
  _i2.GMachineHistoryData? Function(
    _i2.GMachineHistoryData?,
    _i2.GMachineHistoryData?,
  )? get updateResult;
  @override
  _i2.GMachineHistoryData? get optimisticResponse;
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
  _i2.GMachineHistoryData? parseData(Map<String, dynamic> json) =>
      _i2.GMachineHistoryData.fromJson(json);

  @override
  Map<String, dynamic> varsToJson() => vars.toJson();

  @override
  Map<String, dynamic> dataToJson(_i2.GMachineHistoryData data) =>
      data.toJson();

  @override
  _i1.OperationRequest<_i2.GMachineHistoryData, _i3.GMachineHistoryVars>
      transformOperation(_i4.Operation Function(_i4.Operation) transform) =>
          this.rebuild((b) => b..operation = transform(operation));

  static Serializer<GMachineHistoryReq> get serializer =>
      _$gMachineHistoryReqSerializer;

  Map<String, dynamic> toJson() => (_i6.serializers.serializeWith(
        GMachineHistoryReq.serializer,
        this,
      ) as Map<String, dynamic>);

  static GMachineHistoryReq? fromJson(Map<String, dynamic> json) =>
      _i6.serializers.deserializeWith(
        GMachineHistoryReq.serializer,
        json,
      );
}
