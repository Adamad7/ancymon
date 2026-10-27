import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ancymon_mobile/graphql/operations/__generated__/fleet_summary.req.gql.dart';
import 'package:ancymon_mobile/graphql/operations/__generated__/machine_metrics.req.gql.dart';
import 'package:ferry/ferry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gql_websocket_link/gql_websocket_link.dart';
import 'package:web_socket_channel/io.dart';

void main() {
  group('Ferry & WebSocketLink Resilience Tests', () {
    late HttpServer mockServer;
    late int serverPort;

    setUp(() async {
      mockServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      serverPort = mockServer.port;
    });

    tearDown(() async {
      await mockServer.close(force: true);
    });

    test(
        'WebSocketLink automatically reconnects (autoReconnect: true) and recovers FleetSummary subscription after unexpected connection drop',
        () async {
      final connectionsCount = Completer<void>();
      var connectAttempts = 0;
      WebSocket? firstSocket;

      // Handle server-side WebSocket lifecycle
      mockServer.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          connectAttempts++;
          final socket = await WebSocketTransformer.upgrade(request);

          if (connectAttempts == 1) {
            firstSocket = socket;
          }

          socket.listen((dynamic message) {
            final jsonMsg = jsonDecode(message as String) as Map<String, dynamic>;
            final type = jsonMsg['type'];

            if (type == 'connection_init') {
              socket.add(jsonEncode({'type': 'connection_ack'}));
            } else if (type == 'start') {
              final id = jsonMsg['id'];

              if (connectAttempts == 1) {
                // First session: emit initial fleet summary then drop connection
                socket.add(jsonEncode({
                  'type': 'data',
                  'id': id,
                  'payload': {
                    'data': {
                      'fleetSummary': [
                        {
                          'machineId': 'host-resilience-01',
                          'hostname': 'alpha-node',
                          'status': 'ONLINE',
                          'lastSeenTimestamp': 1700000000,
                          'cpuUsagePercent': 25.0,
                          'cpuTemperatureC': 45.0,
                          'networkRxBytesPerSec': 1024.0,
                          'networkTxBytesPerSec': 2048.0,
                        }
                      ]
                    }
                  }
                }));

                // Abruptly sever the connection to simulate LAN drop / server crash
                Timer(const Duration(milliseconds: 50), () {
                  firstSocket?.close(WebSocketStatus.goingAway, 'Simulated network drop');
                });
              } else if (connectAttempts == 2) {
                // Second session: verify subscription auto-reinitialized and emit updated data
                socket.add(jsonEncode({
                  'type': 'data',
                  'id': id,
                  'payload': {
                    'data': {
                      'fleetSummary': [
                        {
                          'machineId': 'host-resilience-01',
                          'hostname': 'alpha-node',
                          'status': 'ONLINE',
                          'lastSeenTimestamp': 1700000010,
                          'cpuUsagePercent': 32.5,
                          'cpuTemperatureC': 48.0,
                          'networkRxBytesPerSec': 4096.0,
                          'networkTxBytesPerSec': 8192.0,
                        }
                      ]
                    }
                  }
                }));

                if (!connectionsCount.isCompleted) {
                  connectionsCount.complete();
                }
              }
            }
          });
        }
      });

      // Client with autoReconnect enabled and short interval for fast testing
      final wsUri = Uri.parse('ws://127.0.0.1:$serverPort/graphql');
      final wsLink = WebSocketLink(
        null,
        channelGenerator: () => IOWebSocketChannel.connect(
          wsUri,
          headers: {'Authorization': 'Bearer test-token'},
        ),
        autoReconnect: true,
        reconnectInterval: const Duration(milliseconds: 100),
        initialPayload: () => {'Authorization': 'Bearer test-token'},
      );

      final client = Client(link: wsLink);

      final receivedPayloads = <String>[];
      final subscription = client.request(GFleetSummaryReq()).listen((response) {
        if (response.data != null && response.data!.fleetSummary.isNotEmpty) {
          final host = response.data!.fleetSummary.first;
          receivedPayloads.add('${host.hostname}:${host.cpuUsagePercent}');
        }
      });

      // Wait until the second connection has replayed and completed
      await connectionsCount.future.timeout(const Duration(seconds: 5));

      // Allow event stream to process
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Assertions:
      expect(connectAttempts, equals(2),
          reason: 'Client should have automatically reconnected once following disconnect');
      expect(receivedPayloads.length, equals(2),
          reason: 'Stream should have received initial data AND post-reconnect data');
      expect(receivedPayloads[0], equals('alpha-node:25.0'));
      expect(receivedPayloads[1], equals('alpha-node:32.5'));

      await subscription.cancel();
      wsLink.dispose();
    });

    test(
        'WebSocketLink auto-reconnects and restores machineMetrics subscription with matching variables',
        () async {
      final sessionReconnected = Completer<void>();
      var attempts = 0;
      final requestedMachineIds = <String>[];

      mockServer.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          attempts++;
          final socket = await WebSocketTransformer.upgrade(request);

          socket.listen((dynamic message) {
            final jsonMsg = jsonDecode(message as String) as Map<String, dynamic>;
            final type = jsonMsg['type'];

            if (type == 'connection_init') {
              socket.add(jsonEncode({'type': 'connection_ack'}));
            } else if (type == 'start') {
              final id = jsonMsg['id'];
              final payload = jsonMsg['payload'] as Map<String, dynamic>?;
              final vars = payload?['variables'] as Map<String, dynamic>?;
              final machineId = vars?['machineId'] as String? ?? 'unknown';

              requestedMachineIds.add(machineId);

              if (attempts == 1) {
                socket.add(jsonEncode({
                  'type': 'data',
                  'id': id,
                  'payload': {
                    'data': {
                      'machineMetrics': {
                        'machineId': machineId,
                        'hostname': 'box-beta',
                        'status': 'ONLINE',
                        'timestamp': 1700000000,
                        'cpu': {'totalUsagePercent': 55.0, 'temperatureC': 50.0},
                        'memory': {
                          'totalBytes': 16000000000,
                          'usedBytes': 8000000000,
                          'usagePercent': 50.0,
                        },
                        'network': {'rxBytesPerSec': 1000.0, 'txBytesPerSec': 2000.0},
                        'disks': <Map<String, dynamic>>[],
                      }
                    }
                  }
                }));

                Timer(const Duration(milliseconds: 50), () {
                  socket.close(WebSocketStatus.goingAway, 'Simulated drop');
                });
              } else if (attempts == 2) {
                socket.add(jsonEncode({
                  'type': 'data',
                  'id': id,
                  'payload': {
                    'data': {
                      'machineMetrics': {
                        'machineId': machineId,
                        'hostname': 'box-beta',
                        'status': 'ONLINE',
                        'timestamp': 1700000005,
                        'cpu': {'totalUsagePercent': 60.0, 'temperatureC': 52.0},
                        'memory': {
                          'totalBytes': 16000000000,
                          'usedBytes': 9000000000,
                          'usagePercent': 56.25,
                        },
                        'network': {'rxBytesPerSec': 2000.0, 'txBytesPerSec': 3000.0},
                        'disks': <Map<String, dynamic>>[],
                      }
                    }
                  }
                }));

                if (!sessionReconnected.isCompleted) {
                  sessionReconnected.complete();
                }
              }
            }
          });
        }
      });

      final wsUri = Uri.parse('ws://127.0.0.1:$serverPort/graphql');
      final wsLink = WebSocketLink(
        null,
        channelGenerator: () => IOWebSocketChannel.connect(wsUri),
        autoReconnect: true,
        reconnectInterval: const Duration(milliseconds: 100),
      );

      final client = Client(link: wsLink);

      final req = GMachineMetricsReq((b) => b..vars.machineId = 'target-machine-42');
      final receivedTemps = <double>[];

      final sub = client.request(req).listen((res) {
        if (res.data != null) {
          final temp = res.data!.machineMetrics.cpu.temperatureC;
          if (temp != null) {
            receivedTemps.add(temp);
          }
        }
      });

      await sessionReconnected.future.timeout(const Duration(seconds: 5));
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(attempts, equals(2));
      expect(requestedMachineIds, equals(['target-machine-42', 'target-machine-42']),
          reason: 'Subscription variables must be preserved and retransmitted upon reconnection');
      expect(receivedTemps, equals([50.0, 52.0]));

      await sub.cancel();
      wsLink.dispose();
    });

    test('WebSocketLink with autoReconnect: false terminates when connection drops', () async {
      var connectAttempts = 0;

      mockServer.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          connectAttempts++;
          final socket = await WebSocketTransformer.upgrade(request);
          socket.listen((dynamic message) {
            final jsonMsg = jsonDecode(message as String) as Map<String, dynamic>;
            if (jsonMsg['type'] == 'connection_init') {
              socket.add(jsonEncode({'type': 'connection_ack'}));
            } else if (jsonMsg['type'] == 'start') {
              // Immediately disconnect
              socket.close(WebSocketStatus.goingAway, 'Forced disconnect');
            }
          });
        }
      });

      final wsUri = Uri.parse('ws://127.0.0.1:$serverPort/graphql');
      final wsLink = WebSocketLink(
        null,
        channelGenerator: () => IOWebSocketChannel.connect(wsUri),
        autoReconnect: false, // Disabled
      );

      final client = Client(link: wsLink);
      final sub = client.request(GFleetSummaryReq()).listen(
            (_) {},
            onError: (_) {},
          );

      // Wait 300ms to allow connection attempt and drop
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(connectAttempts, equals(1),
          reason: 'With autoReconnect: false, no reconnection attempts should be made');

      await sub.cancel();
      wsLink.dispose();
    });
  });
}
