import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/connection_config.dart';

/// Service managing persistent storage of connection credentials via Keystore/Keychain.
class SecureStorageService {
  static const _keyHost = 'ancymon_host';
  static const _keyPort = 'ancymon_port';
  static const _keyToken = 'ancymon_token';
  static const _keyCa = 'ancymon_ca';

  final FlutterSecureStorage _storage;

  const SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  /// Loads stored connection config if available.
  Future<ConnectionConfig?> loadConnectionConfig() async {
    try {
      final ip = await _storage.read(key: _keyHost);
      final portStr = await _storage.read(key: _keyPort);
      final token = await _storage.read(key: _keyToken);
      final ca = await _storage.read(key: _keyCa);

      if (ip != null && portStr != null && token != null && ca != null) {
        final port = int.tryParse(portStr);
        if (port != null && port > 0 && port <= 65535) {
          return ConnectionConfig(
            ip: ip,
            port: port,
            token: token,
            ca: ca,
          );
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Persists connection configuration securely.
  Future<void> saveConnectionConfig(ConnectionConfig config) async {
    await _storage.write(key: _keyHost, value: config.ip);
    await _storage.write(key: _keyPort, value: config.port.toString());
    await _storage.write(key: _keyToken, value: config.token);
    await _storage.write(key: _keyCa, value: config.ca);
  }

  /// Clears stored connection configuration on unpairing or reset.
  Future<void> clearConnectionConfig() async {
    await _storage.delete(key: _keyHost);
    await _storage.delete(key: _keyPort);
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyCa);
  }
}
