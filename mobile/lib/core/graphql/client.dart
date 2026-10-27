import 'dart:io';
import 'package:ferry/ferry.dart';
import 'package:gql/ast.dart';
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
      headers: {
        'Authorization': 'Bearer ${config.token}',
      },
      customClient: httpClient,
    ),
    initialPayload: () => {
      'Authorization': 'Bearer ${config.token}',
    },
  );

  // Split traffic: subscriptions over WebSocket, queries/mutations over HTTP
  final link = Link.split(
    (request) {
      final defs = request.operation.document.definitions
          .whereType<OperationDefinitionNode>();
      if (defs.isEmpty) return false;
      return defs.first.type == OperationType.subscription;
    },
    wsLink,
    httpLink,
  );

  return Client(link: link);
}
