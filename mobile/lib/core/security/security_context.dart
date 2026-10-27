import 'dart:convert';
import 'dart:io';

/// Creates a custom Dart [SecurityContext] configured to exclusively trust the
/// server's internal root CA certificate decoded from Base64 DER bytes.
///
/// This avoids requiring OS-level root certificate installation.
SecurityContext createCustomSecurityContext(String caBase64) {
  final securityContext = SecurityContext(withTrustedRoots: false);

  // Normalize base64 string by removing any whitespace or line breaks
  final cleanBase64 = caBase64.replaceAll(RegExp(r'\s+'), '');

  // Validate that caBase64 is valid Base64
  final derBytes = base64Decode(cleanBase64);

  // Wrap in PEM headers: BoringSSL (Android/Linux) requires PEM encoding for X509 certificates,
  // while Apple platforms support DER. We try PEM first, falling back to DER bytes.
  final pem = '-----BEGIN CERTIFICATE-----\n$cleanBase64\n-----END CERTIFICATE-----\n';
  final pemBytes = utf8.encode(pem);

  try {
    securityContext.setTrustedCertificatesBytes(pemBytes);
  } catch (_) {
    securityContext.setTrustedCertificatesBytes(derBytes);
  }

  return securityContext;
}
