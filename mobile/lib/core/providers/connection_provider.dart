import 'package:ferry/ferry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../graphql/client.dart';
import '../models/connection_config.dart';
import '../storage/secure_storage_service.dart';

/// Provider for the secure credential storage service.
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return const SecureStorageService();
});

/// State notifier managing stored connection state and pairing lifecycle.
class ConnectionConfigNotifier extends StateNotifier<AsyncValue<ConnectionConfig?>> {
  final SecureStorageService _storageService;

  ConnectionConfigNotifier(this._storageService)
      : super(const AsyncValue.loading()) {
    loadStoredConfig();
  }

  /// Loads configuration from Keystore / Keychain.
  Future<void> loadStoredConfig() async {
    try {
      final config = await _storageService.loadConnectionConfig();
      state = AsyncValue.data(config);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Pairs the device with scanned credentials and persists them securely.
  Future<void> pair(ConnectionConfig config) async {
    state = const AsyncValue.loading();
    try {
      await _storageService.saveConnectionConfig(config);
      state = AsyncValue.data(config);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Clears credentials and disconnects the client.
  Future<void> unpair() async {
    try {
      await _storageService.clearConnectionConfig();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider managing active connection configuration.
final connectionConfigProvider =
    StateNotifierProvider<ConnectionConfigNotifier, AsyncValue<ConnectionConfig?>>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  return ConnectionConfigNotifier(storage);
});

/// Provider supplying the active Ferry GraphQL Client instance when paired.
final ferryClientProvider = Provider<Client?>((ref) {
  final configState = ref.watch(connectionConfigProvider);
  return configState.maybeWhen(
    data: (config) {
      if (config == null) return null;
      return buildFerryClient(config: config);
    },
    orElse: () => null,
  );
});
