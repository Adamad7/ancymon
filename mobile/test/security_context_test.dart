import 'dart:io';
import 'package:ancymon_mobile/core/models/connection_config.dart';
import 'package:ancymon_mobile/core/security/security_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dynamic SecurityContext and TLS Certificate Injection Tests', () {
    const validDerCertBase64 =
        'MIIBkTCCATegAwIBAgIUOD+0iYHm45WuhwZre1LNL4sn8cYwCgYIKoZIzj0EAwIw'
        'HjEcMBoGA1UEAwwTQW5jeU1vbiBJbnRlcm5hbCBDQTAeFw0yNjEwMjcxMDI1MTJa'
        'Fw0yNzEwMjcxMDI1MTJaMB4xHDAaBgNVBAMME0FuY3lNb24gSW50ZXJuYWwgQ0Ew'
        'WTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAATJvlNovr82UbNMgVpuHfczmEfxvE7d'
        '43j/fdmyoFQXBO/X6SxPvTbgvIoHAENq1kF5pnshwtvFKihzNNYoHEYEo1MwUTAd'
        'BgNVHQ4EFgQUcYp6gKh7BejwwPD4QSo4bWGA824wHwYDVR0jBBgwFoAUcYp6gKh7'
        'BejwwPD4QSo4bWGA824wDwYDVR0TAQH/BAUwAwEB/zAKBggqhkjOPQQDAgNIADBF'
        'AiEAsFjvEZaVbw/+4u6LSM03ktxighxPkXsNJzHfn6UeejcCIA2He28qo6z6kwiw'
        '0riJyLngbNVJUlEmvGXWfBzoHzJf';

    test('createCustomSecurityContext decodes Base64 and returns valid SecurityContext', () {
      expect(() => createCustomSecurityContext(validDerCertBase64), returnsNormally);
      final context = createCustomSecurityContext(validDerCertBase64);
      expect(context, isA<SecurityContext>());
    });

    test('createCustomSecurityContext handles whitespace and newlines cleanly', () {
      final certWithWhitespace = '\n  $validDerCertBase64  \n';

      final context = createCustomSecurityContext(certWithWhitespace);
      expect(context, isA<SecurityContext>());
    });

    test('createCustomSecurityContext throws FormatException on invalid Base64 string', () {
      expect(
        () => createCustomSecurityContext('!@@@NOT_VALID_BASE64###!'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('ConnectionConfig Model & JSON Schema Validation Tests', () {
    const validJsonString =
        '{"ip":"192.168.1.100","port":443,"token":"secret-psk-token-123","ca":"QUJDREVGR0hJSktMTU5PUFFSU1RVVldYWVo="}';

    test('parses valid JSON string matching pairing.schema.json', () {
      final config = ConnectionConfig.fromJsonString(validJsonString);

      expect(config.ip, '192.168.1.100');
      expect(config.port, 443);
      expect(config.token, 'secret-psk-token-123');
      expect(config.ca, 'QUJDREVGR0hJSktMTU5PUFFSU1RVVldYWVo=');
    });

    test('serializes to JSON map and JSON string correctly', () {
      final config = ConnectionConfig.fromJsonString(validJsonString);
      final jsonMap = config.toJson();

      expect(jsonMap['ip'], '192.168.1.100');
      expect(jsonMap['port'], 443);
      expect(jsonMap['token'], 'secret-psk-token-123');
      expect(jsonMap['ca'], 'QUJDREVGR0hJSktMTU5PUFFSU1RVVldYWVo=');

      final roundTrip = ConnectionConfig.fromJsonString(config.toJsonString());
      expect(roundTrip, equals(config));
    });

    test('throws FormatException on missing required properties', () {
      // Missing 'ca'
      const missingCa = '{"ip":"192.168.1.1","port":443,"token":"tok"}';
      expect(
        () => ConnectionConfig.fromJsonString(missingCa),
        throwsA(isA<FormatException>().having((e) => e.message, 'msg', contains('ca'))),
      );

      // Missing 'ip'
      const missingIp = '{"port":443,"token":"tok","ca":"dGVzdA=="}';
      expect(
        () => ConnectionConfig.fromJsonString(missingIp),
        throwsA(isA<FormatException>().having((e) => e.message, 'msg', contains('ip'))),
      );

      // Missing 'port'
      const missingPort = '{"ip":"192.168.1.1","token":"tok","ca":"dGVzdA=="}';
      expect(
        () => ConnectionConfig.fromJsonString(missingPort),
        throwsA(isA<FormatException>().having((e) => e.message, 'msg', contains('port'))),
      );

      // Missing 'token'
      const missingToken = '{"ip":"192.168.1.1","port":443,"ca":"dGVzdA=="}';
      expect(
        () => ConnectionConfig.fromJsonString(missingToken),
        throwsA(isA<FormatException>().having((e) => e.message, 'msg', contains('token'))),
      );
    });

    test('throws FormatException on invalid port bounds', () {
      const portZero = '{"ip":"192.168.1.1","port":0,"token":"tok","ca":"dGVzdA=="}';
      expect(
        () => ConnectionConfig.fromJsonString(portZero),
        throwsA(isA<FormatException>().having((e) => e.message, 'msg', contains('Port must be between'))),
      );

      const portTooHigh = '{"ip":"192.168.1.1","port":70000,"token":"tok","ca":"dGVzdA=="}';
      expect(
        () => ConnectionConfig.fromJsonString(portTooHigh),
        throwsA(isA<FormatException>().having((e) => e.message, 'msg', contains('Port must be between'))),
      );
    });
  });
}
