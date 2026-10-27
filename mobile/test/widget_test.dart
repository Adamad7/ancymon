import 'package:ancymon_mobile/core/models/connection_config.dart';
import 'package:ancymon_mobile/core/providers/connection_provider.dart';
import 'package:ancymon_mobile/core/storage/secure_storage_service.dart';
import 'package:ancymon_mobile/features/dashboard/providers/fleet_summary_provider.dart';
import 'package:ancymon_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSecureStorageService implements SecureStorageService {
  ConnectionConfig? _storedConfig;

  _FakeSecureStorageService([this._storedConfig]);

  @override
  Future<ConnectionConfig?> loadConnectionConfig() async => _storedConfig;

  @override
  Future<void> saveConnectionConfig(ConnectionConfig config) async {
    _storedConfig = config;
  }

  @override
  Future<void> clearConnectionConfig() async {
    _storedConfig = null;
  }
}

void main() {
  group('AncyMonApp Onboarding Gateway & Navigation Tests', () {
    testWidgets('shows PairingScreen on first launch when unconfigured', (tester) async {
      final fakeStorage = _FakeSecureStorageService(null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureStorageServiceProvider.overrideWithValue(fakeStorage),
          ],
          child: const AncyMonApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Pair Workstation Fleet'), findsOneWidget);
      expect(find.byKey(const Key('enter_manually_button')), findsOneWidget);
    });

    testWidgets('manual QR payload entry validates JSON and saves credentials', (tester) async {
      final fakeStorage = _FakeSecureStorageService(null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureStorageServiceProvider.overrideWithValue(fakeStorage),
            fleetSummaryProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const AncyMonApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Open manual input dialog
      await tester.tap(find.byKey(const Key('enter_manually_button')));
      await tester.pumpAndSettle();

      expect(find.text('Manual Pairing JSON'), findsOneWidget);

      const validCa =
          'MIIBkTCCATegAwIBAgIUOD+0iYHm45WuhwZre1LNL4sn8cYwCgYIKoZIzj0EAwIw'
          'HjEcMBoGA1UEAwwTQW5jeU1vbiBJbnRlcm5hbCBDQTAeFw0yNjEwMjcxMDI1MTJa'
          'Fw0yNzEwMjcxMDI1MTJaMB4xHDAaBgNVBAMME0FuY3lNb24gSW50ZXJuYWwgQ0Ew'
          'WTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAATJvlNovr82UbNMgVpuHfczmEfxvE7d'
          '43j/fdmyoFQXBO/X6SxPvTbgvIoHAENq1kF5pnshwtvFKihzNNYoHEYEo1MwUTAd'
          'BgNVHQ4EFgQUcYp6gKh7BejwwPD4QSo4bWGA824wHwYDVR0jBBgwFoAUcYp6gKh7'
          'BejwwPD4QSo4bWGA824wDwYDVR0TAQH/BAUwAwEB/zAKBggqhkjOPQQDAgNIADBF'
          'AiEAsFjvEZaVbw/+4u6LSM03ktxighxPkXsNJzHfn6UeejcCIA2He28qo6z6kwiw'
          '0riJyLngbNVJUlEmvGXWfBzoHzJf';
      const payload =
          '{"ip":"192.168.1.50","port":443,"token":"auth-token-xyz","ca":"$validCa"}';
      await tester.enterText(find.byKey(const Key('manual_json_input')), payload);
      await tester.pumpAndSettle();

      // Tap Pair button
      await tester.tap(find.byKey(const Key('submit_manual_json_button')));
      await tester.pumpAndSettle();

      // Verify stored in storage service
      final stored = await fakeStorage.loadConnectionConfig();
      expect(stored, isNotNull);
      expect(stored!.ip, '192.168.1.50');
      expect(stored.port, 443);
      expect(stored.token, 'auth-token-xyz');
    });
  });
}
