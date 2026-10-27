// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:gql/ast.dart' as _i1;

const MetricType = _i1.EnumTypeDefinitionNode(
  name: _i1.NameNode(value: 'MetricType'),
  directives: [],
  values: [
    _i1.EnumValueDefinitionNode(
      name: _i1.NameNode(value: 'CPU_USAGE'),
      directives: [],
    ),
    _i1.EnumValueDefinitionNode(
      name: _i1.NameNode(value: 'CPU_TEMP'),
      directives: [],
    ),
    _i1.EnumValueDefinitionNode(
      name: _i1.NameNode(value: 'MEMORY_USAGE'),
      directives: [],
    ),
    _i1.EnumValueDefinitionNode(
      name: _i1.NameNode(value: 'NETWORK_RX'),
      directives: [],
    ),
    _i1.EnumValueDefinitionNode(
      name: _i1.NameNode(value: 'NETWORK_TX'),
      directives: [],
    ),
    _i1.EnumValueDefinitionNode(
      name: _i1.NameNode(value: 'DISK_USAGE'),
      directives: [],
    ),
  ],
);
const TimeRange = _i1.EnumTypeDefinitionNode(
  name: _i1.NameNode(value: 'TimeRange'),
  directives: [],
  values: [
    _i1.EnumValueDefinitionNode(
      name: _i1.NameNode(value: 'RANGE_1H'),
      directives: [],
    ),
    _i1.EnumValueDefinitionNode(
      name: _i1.NameNode(value: 'RANGE_6H'),
      directives: [],
    ),
    _i1.EnumValueDefinitionNode(
      name: _i1.NameNode(value: 'RANGE_12H'),
      directives: [],
    ),
    _i1.EnumValueDefinitionNode(
      name: _i1.NameNode(value: 'RANGE_24H'),
      directives: [],
    ),
    _i1.EnumValueDefinitionNode(
      name: _i1.NameNode(value: 'RANGE_3D'),
      directives: [],
    ),
    _i1.EnumValueDefinitionNode(
      name: _i1.NameNode(value: 'RANGE_7D'),
      directives: [],
    ),
    _i1.EnumValueDefinitionNode(
      name: _i1.NameNode(value: 'CUSTOM_DATE'),
      directives: [],
    ),
  ],
);
const MachineStatus = _i1.EnumTypeDefinitionNode(
  name: _i1.NameNode(value: 'MachineStatus'),
  directives: [],
  values: [
    _i1.EnumValueDefinitionNode(
      name: _i1.NameNode(value: 'ONLINE'),
      directives: [],
    ),
    _i1.EnumValueDefinitionNode(
      name: _i1.NameNode(value: 'OFFLINE'),
      directives: [],
    ),
  ],
);
const MachineSummary = _i1.ObjectTypeDefinitionNode(
  name: _i1.NameNode(value: 'MachineSummary'),
  directives: [],
  interfaces: [],
  fields: [
    _i1.FieldDefinitionNode(
      name: _i1.NameNode(value: 'machineId'),
      directives: [],
      args: [],
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'ID'),
        isNonNull: true,
      ),
    ),
    _i1.FieldDefinitionNode(
      name: _i1.NameNode(value: 'hostname'),
      directives: [],
      args: [],
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'String'),
        isNonNull: true,
      ),
    ),
    _i1.FieldDefinitionNode(
      name: _i1.NameNode(value: 'status'),
      directives: [],
      args: [],
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'MachineStatus'),
        isNonNull: true,
      ),
    ),
    _i1.FieldDefinitionNode(
      name: _i1.NameNode(value: 'lastSeenTimestamp'),
      directives: [],
      args: [],
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'Int'),
        isNonNull: true,
      ),
    ),
    _i1.FieldDefinitionNode(
      name: _i1.NameNode(value: 'cpuUsagePercent'),
      directives: [],
      args: [],
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'Float'),
        isNonNull: false,
      ),
    ),
    _i1.FieldDefinitionNode(
      name: _i1.NameNode(value: 'cpuTemperatureC'),
      directives: [],
      args: [],
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'Float'),
        isNonNull: false,
      ),
    ),
    _i1.FieldDefinitionNode(
      name: _i1.NameNode(value: 'networkRxBytesPerSec'),
      directives: [],
      args: [],
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'Float'),
        isNonNull: false,
      ),
    ),
    _i1.FieldDefinitionNode(
      name: _i1.NameNode(value: 'networkTxBytesPerSec'),
      directives: [],
      args: [],
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'Float'),
        isNonNull: false,
      ),
    ),
  ],
);
const MachineDetail = _i1.ObjectTypeDefinitionNode(
  name: _i1.NameNode(value: 'MachineDetail'),
  directives: [],
  interfaces: [],
  fields: [
    _i1.FieldDefinitionNode(
      name: _i1.NameNode(value: 'machineId'),
      directives: [],
      args: [],
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'ID'),
        isNonNull: true,
      ),
    ),
    _i1.FieldDefinitionNode(
      name: _i1.NameNode(value: 'hostname'),
      directives: [],
      args: [],
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'String'),
        isNonNull: true,
      ),
    ),
    _i1.FieldDefinitionNode(
      name: _i1.NameNode(value: 'status'),
      directives: [],
      args: [],
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'MachineStatus'),
        isNonNull: true,
      ),
    ),
    _i1.FieldDefinitionNode(
      name: _i1.NameNode(value: 'timestamp'),
      directives: [],
      args: [],
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'Int'),
        isNonNull: true,
      ),
    ),
    _i1.FieldDefinitionNode(
      name: _i1.NameNode(value: 'cpu'),
      directives: [],
      args: [],
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'DetailedCpuMetrics'),
        isNonNull: true,
      ),
    ),
    _i1.FieldDefinitionNode(
      name: _i1.NameNode(value: 'memory'),
      directives: [],
      args: [],
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'DetailedMemoryMetrics'),
        isNonNull: true,
      ),
    ),
    _i1.FieldDefinitionNode(
      name: _i1.NameNode(value: 'network'),
      directives: [],
      args: [],
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'DetailedNetworkMetrics'),
        isNonNull: true,
      ),
    ),
    _i1.FieldDefinitionNode(
      name: _i1.NameNode(value: 'disks'),
      directives: [],
      args: [],
      type: _i1.ListTypeNode(
        type: _i1.NamedTypeNode(
          name: _i1.NameNode(value: 'DiskPartitionInfo'),
          isNonNull: true,
        ),
        isNonNull: true,
      ),
    ),
  ],
);
const DetailedCpuMetrics = _i1.ObjectTypeDefinitionNode(
  name: _i1.NameNode(value: 'DetailedCpuMetrics'),
  directives: [],
  interfaces: [],
  fields: [
    _i1.FieldDefinitionNode(
      name: _i1.NameNode(value: 'totalUsagePercent'),
      directives: [],
      args: [],
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'Float'),
        isNonNull: true,
      ),
    ),
    _i1.FieldDefinitionNode(
      name: _i1.NameNode(value: 'temperatureC'),
      directives: [],
      args: [],
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'Float'),
        isNonNull: false,
      ),
    ),
  ],
);
const DetailedMemoryMetrics = _i1.ObjectTypeDefinitionNode(
  name: _i1.NameNode(value: 'DetailedMemoryMetrics'),
  directives: [],
  interfaces: [],
  fields: [
    _i1.FieldDefinitionNode(
      name: _i1.NameNode(value: 'totalBytes'),
      directives: [],
      args: [],
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'Float'),
        isNonNull: true,
      ),
    ),
    _i1.FieldDefinitionNode(
      name: _i1.NameNode(value: 'usedBytes'),
      directives: [],
      args: [],
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'Float'),
        isNonNull: true,
      ),
    ),
    _i1.FieldDefinitionNode(
      name: _i1.NameNode(value: 'usagePercent'),
      directives: [],
      args: [],
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'Float'),
        isNonNull: true,
      ),
    ),
  ],
);
const DetailedNetworkMetrics = _i1.ObjectTypeDefinitionNode(
  name: _i1.NameNode(value: 'DetailedNetworkMetrics'),
  directives: [],
  interfaces: [],
  fields: [
    _i1.FieldDefinitionNode(
      name: _i1.NameNode(value: 'rxBytesPerSec'),
      directives: [],
      args: [],
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'Float'),
        isNonNull: true,
      ),
    ),
    _i1.FieldDefinitionNode(
      name: _i1.NameNode(value: 'txBytesPerSec'),
      directives: [],
      args: [],
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'Float'),
        isNonNull: true,
      ),
    ),
  ],
);
const DiskPartitionInfo = _i1.ObjectTypeDefinitionNode(
  name: _i1.NameNode(value: 'DiskPartitionInfo'),
  directives: [],
  interfaces: [],
  fields: [
    _i1.FieldDefinitionNode(
      name: _i1.NameNode(value: 'mountPoint'),
      directives: [],
      args: [],
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'String'),
        isNonNull: true,
      ),
    ),
    _i1.FieldDefinitionNode(
      name: _i1.NameNode(value: 'fsType'),
      directives: [],
      args: [],
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'String'),
        isNonNull: true,
      ),
    ),
    _i1.FieldDefinitionNode(
      name: _i1.NameNode(value: 'totalBytes'),
      directives: [],
      args: [],
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'Float'),
        isNonNull: true,
      ),
    ),
    _i1.FieldDefinitionNode(
      name: _i1.NameNode(value: 'freeBytes'),
      directives: [],
      args: [],
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'Float'),
        isNonNull: true,
      ),
    ),
    _i1.FieldDefinitionNode(
      name: _i1.NameNode(value: 'usagePercent'),
      directives: [],
      args: [],
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'Float'),
        isNonNull: true,
      ),
    ),
  ],
);
const HistoricalPoint = _i1.ObjectTypeDefinitionNode(
  name: _i1.NameNode(value: 'HistoricalPoint'),
  directives: [],
  interfaces: [],
  fields: [
    _i1.FieldDefinitionNode(
      name: _i1.NameNode(value: 'timestamp'),
      directives: [],
      args: [],
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'Int'),
        isNonNull: true,
      ),
    ),
    _i1.FieldDefinitionNode(
      name: _i1.NameNode(value: 'value'),
      directives: [],
      args: [],
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'Float'),
        isNonNull: true,
      ),
    ),
  ],
);
const Query = _i1.ObjectTypeDefinitionNode(
  name: _i1.NameNode(value: 'Query'),
  directives: [],
  interfaces: [],
  fields: [
    _i1.FieldDefinitionNode(
      name: _i1.NameNode(value: 'machineHistory'),
      directives: [],
      args: [
        _i1.InputValueDefinitionNode(
          name: _i1.NameNode(value: 'machineId'),
          directives: [],
          type: _i1.NamedTypeNode(
            name: _i1.NameNode(value: 'ID'),
            isNonNull: true,
          ),
          defaultValue: null,
        ),
        _i1.InputValueDefinitionNode(
          name: _i1.NameNode(value: 'metric'),
          directives: [],
          type: _i1.NamedTypeNode(
            name: _i1.NameNode(value: 'MetricType'),
            isNonNull: true,
          ),
          defaultValue: null,
        ),
        _i1.InputValueDefinitionNode(
          name: _i1.NameNode(value: 'range'),
          directives: [],
          type: _i1.NamedTypeNode(
            name: _i1.NameNode(value: 'TimeRange'),
            isNonNull: true,
          ),
          defaultValue: null,
        ),
        _i1.InputValueDefinitionNode(
          name: _i1.NameNode(value: 'date'),
          directives: [],
          type: _i1.NamedTypeNode(
            name: _i1.NameNode(value: 'String'),
            isNonNull: false,
          ),
          defaultValue: null,
        ),
      ],
      type: _i1.ListTypeNode(
        type: _i1.NamedTypeNode(
          name: _i1.NameNode(value: 'HistoricalPoint'),
          isNonNull: true,
        ),
        isNonNull: true,
      ),
    )
  ],
);
const Mutation = _i1.ObjectTypeDefinitionNode(
  name: _i1.NameNode(value: 'Mutation'),
  directives: [],
  interfaces: [],
  fields: [
    _i1.FieldDefinitionNode(
      name: _i1.NameNode(value: 'deleteMachine'),
      directives: [],
      args: [
        _i1.InputValueDefinitionNode(
          name: _i1.NameNode(value: 'machineId'),
          directives: [],
          type: _i1.NamedTypeNode(
            name: _i1.NameNode(value: 'ID'),
            isNonNull: true,
          ),
          defaultValue: null,
        )
      ],
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'Boolean'),
        isNonNull: true,
      ),
    )
  ],
);
const Subscription = _i1.ObjectTypeDefinitionNode(
  name: _i1.NameNode(value: 'Subscription'),
  directives: [],
  interfaces: [],
  fields: [
    _i1.FieldDefinitionNode(
      name: _i1.NameNode(value: 'fleetSummary'),
      directives: [],
      args: [],
      type: _i1.ListTypeNode(
        type: _i1.NamedTypeNode(
          name: _i1.NameNode(value: 'MachineSummary'),
          isNonNull: true,
        ),
        isNonNull: true,
      ),
    ),
    _i1.FieldDefinitionNode(
      name: _i1.NameNode(value: 'machineMetrics'),
      directives: [],
      args: [
        _i1.InputValueDefinitionNode(
          name: _i1.NameNode(value: 'machineId'),
          directives: [],
          type: _i1.NamedTypeNode(
            name: _i1.NameNode(value: 'ID'),
            isNonNull: true,
          ),
          defaultValue: null,
        )
      ],
      type: _i1.NamedTypeNode(
        name: _i1.NameNode(value: 'MachineDetail'),
        isNonNull: true,
      ),
    ),
  ],
);
const document = _i1.DocumentNode(definitions: [
  MetricType,
  TimeRange,
  MachineStatus,
  MachineSummary,
  MachineDetail,
  DetailedCpuMetrics,
  DetailedMemoryMetrics,
  DetailedNetworkMetrics,
  DiskPartitionInfo,
  HistoricalPoint,
  Query,
  Mutation,
  Subscription,
]);
