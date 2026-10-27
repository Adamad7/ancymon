// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:gql/ast.dart' as _i1;

const MachineHistory = _i1.OperationDefinitionNode(
  type: _i1.OperationType.query,
  name: _i1.NameNode(value: 'MachineHistory'),
  variableDefinitions: [
    _i1.VariableDefinitionNode(
      variable: _i1.VariableNode(name: _i1.NameNode(value: 'machineId')),
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'ID'),
        isNonNull: true,
      ),
      defaultValue: _i1.DefaultValueNode(value: null),
      directives: [],
    ),
    _i1.VariableDefinitionNode(
      variable: _i1.VariableNode(name: _i1.NameNode(value: 'metric')),
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'MetricType'),
        isNonNull: true,
      ),
      defaultValue: _i1.DefaultValueNode(value: null),
      directives: [],
    ),
    _i1.VariableDefinitionNode(
      variable: _i1.VariableNode(name: _i1.NameNode(value: 'range')),
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'TimeRange'),
        isNonNull: true,
      ),
      defaultValue: _i1.DefaultValueNode(value: null),
      directives: [],
    ),
    _i1.VariableDefinitionNode(
      variable: _i1.VariableNode(name: _i1.NameNode(value: 'date')),
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'String'),
        isNonNull: false,
      ),
      defaultValue: _i1.DefaultValueNode(value: null),
      directives: [],
    ),
  ],
  directives: [],
  selectionSet: _i1.SelectionSetNode(selections: [
    _i1.FieldNode(
      name: _i1.NameNode(value: 'machineHistory'),
      alias: null,
      arguments: [
        _i1.ArgumentNode(
          name: _i1.NameNode(value: 'machineId'),
          value: _i1.VariableNode(name: _i1.NameNode(value: 'machineId')),
        ),
        _i1.ArgumentNode(
          name: _i1.NameNode(value: 'metric'),
          value: _i1.VariableNode(name: _i1.NameNode(value: 'metric')),
        ),
        _i1.ArgumentNode(
          name: _i1.NameNode(value: 'range'),
          value: _i1.VariableNode(name: _i1.NameNode(value: 'range')),
        ),
        _i1.ArgumentNode(
          name: _i1.NameNode(value: 'date'),
          value: _i1.VariableNode(name: _i1.NameNode(value: 'date')),
        ),
      ],
      directives: [],
      selectionSet: _i1.SelectionSetNode(selections: [
        _i1.FieldNode(
          name: _i1.NameNode(value: 'timestamp'),
          alias: null,
          arguments: [],
          directives: [],
          selectionSet: null,
        ),
        _i1.FieldNode(
          name: _i1.NameNode(value: 'value'),
          alias: null,
          arguments: [],
          directives: [],
          selectionSet: null,
        ),
      ]),
    )
  ]),
);
const document = _i1.DocumentNode(definitions: [MachineHistory]);
