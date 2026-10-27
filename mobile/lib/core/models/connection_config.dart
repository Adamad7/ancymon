import 'dart:convert';

/// Server connection configuration retrieved via QR code onboarding or secure storage.
class ConnectionConfig {
  final String ip;
  final int port;
  final String token;
  final String ca;

  const ConnectionConfig({
    required this.ip,
    required this.port,
    required this.token,
    required this.ca,
  });

  /// Parse and validate pairing JSON according to pairing.schema.json
  factory ConnectionConfig.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('ip') || json['ip'] is! String || (json['ip'] as String).trim().isEmpty) {
      throw const FormatException('Missing or invalid "ip" field in pairing payload');
    }
    if (!json.containsKey('port') || json['port'] is! int) {
      throw const FormatException('Missing or invalid "port" field in pairing payload');
    }
    if (!json.containsKey('token') || json['token'] is! String || (json['token'] as String).trim().isEmpty) {
      throw const FormatException('Missing or invalid "token" field in pairing payload');
    }
    if (!json.containsKey('ca') || json['ca'] is! String || (json['ca'] as String).trim().isEmpty) {
      throw const FormatException('Missing or invalid "ca" field in pairing payload');
    }

    final port = json['port'] as int;
    if (port < 1 || port > 65535) {
      throw const FormatException('Port must be between 1 and 65535');
    }

    return ConnectionConfig(
      ip: (json['ip'] as String).trim(),
      port: port,
      token: (json['token'] as String).trim(),
      ca: (json['ca'] as String).trim(),
    );
  }

  /// Parse from raw minified JSON string
  factory ConnectionConfig.fromJsonString(String rawJson) {
    try {
      final dynamic decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Pairing payload must be a JSON object');
      }
      return ConnectionConfig.fromJson(decoded);
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('Failed to parse pairing JSON: $e');
    }
  }

  Map<String, dynamic> toJson() => {
        'ip': ip,
        'port': port,
        'token': token,
        'ca': ca,
      };

  String toJsonString() => jsonEncode(toJson());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionConfig &&
          runtimeType == other.runtimeType &&
          ip == other.ip &&
          port == other.port &&
          token == other.token &&
          ca == other.ca;

  @override
  int get hashCode => Object.hash(ip, port, token, ca);
}
