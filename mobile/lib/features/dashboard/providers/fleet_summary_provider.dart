import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/connection_provider.dart';
import '../../../graphql/operations/__generated__/delete_machine.req.gql.dart';
import '../../../graphql/operations/__generated__/fleet_summary.data.gql.dart';
import '../../../graphql/operations/__generated__/fleet_summary.req.gql.dart';

/// StreamProvider binding the live GraphQL fleetSummary subscription to Riverpod.
final fleetSummaryProvider =
    StreamProvider.autoDispose<List<GFleetSummaryData_fleetSummary>>((ref) {
  final client = ref.watch(ferryClientProvider);
  if (client == null) {
    return const Stream.empty();
  }

  final req = GFleetSummaryReq();
  return client.request(req).map((response) {
    if (response.hasErrors) {
      final msg = response.graphqlErrors?.isNotEmpty == true
          ? response.graphqlErrors!.first.message
          : 'GraphQL Fleet Subscription Error';
      throw Exception(msg);
    }
    final list = response.data?.fleetSummary;
    return list != null ? list.toList() : <GFleetSummaryData_fleetSummary>[];
  });
});

/// Typed callback provider for executing the deleteMachine GraphQL mutation.
final deleteMachineMutationProvider =
    Provider<Future<bool> Function(String machineId)>((ref) {
  final client = ref.watch(ferryClientProvider);

  return (String machineId) async {
    if (client == null) {
      throw Exception('Ferry client is not initialized');
    }

    final req = GDeleteMachineReq(
      (b) => b..vars.machineId = machineId,
    );

    final response = await client.request(req).first;
    if (response.hasErrors) {
      final msg = response.graphqlErrors?.isNotEmpty == true
          ? response.graphqlErrors!.first.message
          : 'Failed to delete workstation';
      throw Exception(msg);
    }

    return response.data?.deleteMachine ?? false;
  };
});
