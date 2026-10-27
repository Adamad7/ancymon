import 'dart:io';
import 'package:ferry/ferry.dart';
import 'package:gql/ast.dart';
import 'package:gql_exec/gql_exec.dart';
import 'package:gql_http_link/gql_http_link.dart';
import 'package:gql_websocket_link/gql_websocket_link.dart';
import 'package:http/io_client.dart';
import 'package:web_socket_channel/io.dart';
import '../models/connection_config.dart';
import '../security/security_context.dart';

/// Builds a Ferry GraphQL [Client] configured with custom TLS security context
/// trusting the server's ECDSA CA certificate for both HTTPS queries/mutations
/// and WSS live subscriptions.
Client buildFerryClient({
  required ConnectionConfig config,
  HttpClient? customHttpClient,
}) {
  final httpClient = customHttpClient ??
      HttpClient(
        context: createCustomSecurityContext(config.ca),
      );

  final ioClient = IOClient(httpClient);

  // HTTPS Link for queries and mutations
  final httpLink = HttpLink(
    'https://${config.ip}:${config.port}/graphql',
    httpClient: ioClient,
    defaultHeaders: {
      'Authorization': 'Bearer ${config.token}',
    },
  );

  // WSS Link for live subscriptions
  final wsUrl = Uri.parse('wss://${config.ip}:${config.port}/graphql');
  final wsLink = WebSocketLink(
    null,
    channelGenerator: () => IOWebSocketChannel.connect(
      wsUrl,
      protocols: const ['graphql-ws'],
      headers: {
        'Authorization': 'Bearer ${config.token}',
      },
      customClient: httpClient,
    ),
    autoReconnect: true,
    initialPayload: () => {
      'Authorization': 'Bearer ${config.token}',
    },
  );

  // Split traffic: subscriptions over WebSocket, queries/mutations over HTTP
  final link = SplitLink(
    test: (request) {
      final defs = request.operation.document.definitions
          .whereType<OperationDefinitionNode>();
      if (defs.isEmpty) return false;
      return defs.first.type == OperationType.subscription;
    },
    left: wsLink,
    right: httpLink,
  );

  return AncyMonClient(link: link);
}

/// A composite [Link] that routes subscription requests to [left] (e.g. WebSocket)
/// and other operations to [right] (e.g. HTTP), propagating [dispose] to both child links.
class SplitLink extends Link {
  final bool Function(Request request) test;
  final Link left;
  final Link right;

  SplitLink({
    required this.test,
    required this.left,
    required this.right,
  });

  @override
  Stream<Response> request(
    Request request, [
    NextLink? forward,
  ]) =>
      test(request)
          ? left.request(request, forward)
          : right.request(request, forward);

  @override
  Future<void> dispose() async {
    await Future.wait([
      left.dispose(),
      right.dispose(),
    ]);
  }
}

/// Custom Ferry [Client] that ensures both the internal cache/controllers
/// and the underlying [Link] chain are cleanly disposed.
class AncyMonClient extends Client {
  AncyMonClient({required super.link});

  @override
  Future<void> dispose() async {
    await super.dispose();
    await link.dispose();
  }
}
