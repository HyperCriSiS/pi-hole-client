import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/utils/misc.dart';

class _FakeCertificate implements X509Certificate {
  _FakeCertificate(List<int> der) : _der = Uint8List.fromList(der);

  final Uint8List _der;

  @override
  Uint8List get der => _der;

  @override
  DateTime get endValidity => DateTime.utc(2100);

  @override
  String get issuer => 'CN=test-issuer';

  @override
  String get pem => '';

  @override
  Uint8List get sha1 => Uint8List(0);

  @override
  DateTime get startValidity => DateTime.utc(2000);

  @override
  String get subject => 'CN=test-subject';
}

String _colonSeparatedUppercase(String digest) {
  return [
    for (var index = 0; index < digest.length; index += 2)
      digest.substring(index, index + 2),
  ].join(':').toUpperCase();
}

void main() {
  group('createHttpClient TLS policy', () {
    test('does not install a callback when untrusted certificates are disabled', () {
      final client = createHttpClient(allowUntrustedCert: false);
      addTearDown(() => client.close(force: true));

      expect(client.badCertificateCallback, isNull);
    });

    test('accepts an unpinned certificate when legacy untrusted mode is enabled', () {
      final client = createHttpClient(allowUntrustedCert: true);
      addTearDown(() => client.close(force: true));
      final certificate = _FakeCertificate([1, 2, 3, 4]);

      final callback = client.badCertificateCallback;

      expect(callback, isNotNull);
      expect(callback!(certificate, 'pi.hole', 443), isTrue);
    });

    test('accepts a matching SHA-256 pin independent of case and separators', () {
      final certificate = _FakeCertificate([5, 6, 7, 8]);
      final digest = sha256.convert(certificate.der).toString();
      final client = createHttpClient(
        allowUntrustedCert: true,
        pinnedCertificateSha256: _colonSeparatedUppercase(digest),
      );
      addTearDown(() => client.close(force: true));

      final callback = client.badCertificateCallback;

      expect(callback, isNotNull);
      expect(callback!(certificate, 'pi.hole', 443), isTrue);
    });

    test('rejects a certificate that does not match the configured pin', () {
      final client = createHttpClient(
        allowUntrustedCert: true,
        pinnedCertificateSha256: '00' * 32,
      );
      addTearDown(() => client.close(force: true));
      final certificate = _FakeCertificate([9, 10, 11, 12]);

      final callback = client.badCertificateCallback;

      expect(callback, isNotNull);
      expect(callback!(certificate, 'pi.hole', 443), isFalse);
    });

    test('ignoreCertificateErrors overrides pin validation', () {
      final client = createHttpClient(
        allowUntrustedCert: true,
        ignoreCertificateErrors: true,
        pinnedCertificateSha256: '00' * 32,
      );
      addTearDown(() => client.close(force: true));
      final certificate = _FakeCertificate([13, 14, 15, 16]);

      final callback = client.badCertificateCallback;

      expect(callback, isNotNull);
      expect(callback!(certificate, 'pi.hole', 443), isTrue);
    });
  });
}
