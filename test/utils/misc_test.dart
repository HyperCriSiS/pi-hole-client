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

class _RecordingHttpClient implements HttpClient {
  bool Function(X509Certificate certificate, String host, int port)?
  recordedBadCertificateCallback;

  @override
  set badCertificateCallback(
    bool Function(X509Certificate certificate, String host, int port)? callback,
  ) {
    recordedBadCertificateCallback = callback;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

HttpClient _createWithRecordingClient(
  _RecordingHttpClient recordingClient, {
  bool allowUntrustedCert = true,
  bool ignoreCertificateErrors = false,
  String? pinnedCertificateSha256,
}) {
  return HttpOverrides.runZoned(
    () => createHttpClient(
      allowUntrustedCert: allowUntrustedCert,
      ignoreCertificateErrors: ignoreCertificateErrors,
      pinnedCertificateSha256: pinnedCertificateSha256,
    ),
    createHttpClient: (_) => recordingClient,
  );
}

String _colonSeparatedUppercase(String digest) {
  return [
    for (var index = 0; index < digest.length; index += 2)
      digest.substring(index, index + 2),
  ].join(':').toUpperCase();
}

String get _nonMatchingSha256 => List.filled(64, '0').join();

void main() {
  group('createHttpClient TLS policy', () {
    test('does not install a callback when untrusted certificates are disabled', () {
      final recordingClient = _RecordingHttpClient();

      final client = _createWithRecordingClient(
        recordingClient,
        allowUntrustedCert: false,
      );

      expect(client, same(recordingClient));
      expect(recordingClient.recordedBadCertificateCallback, isNull);
    });

    test('accepts an unpinned certificate when legacy untrusted mode is enabled', () {
      final recordingClient = _RecordingHttpClient();
      _createWithRecordingClient(recordingClient);
      final certificate = _FakeCertificate([1, 2, 3, 4]);

      final callback = recordingClient.recordedBadCertificateCallback;

      expect(callback, isNotNull);
      expect(callback!(certificate, 'pi.hole', 443), isTrue);
    });

    test('accepts a matching SHA-256 pin independent of case and separators', () {
      final certificate = _FakeCertificate([5, 6, 7, 8]);
      final digest = sha256.convert(certificate.der).toString();
      final recordingClient = _RecordingHttpClient();
      _createWithRecordingClient(
        recordingClient,
        pinnedCertificateSha256: _colonSeparatedUppercase(digest),
      );

      final callback = recordingClient.recordedBadCertificateCallback;

      expect(callback, isNotNull);
      expect(callback!(certificate, 'pi.hole', 443), isTrue);
    });

    test('rejects a certificate that does not match the configured pin', () {
      final recordingClient = _RecordingHttpClient();
      _createWithRecordingClient(
        recordingClient,
        pinnedCertificateSha256: _nonMatchingSha256,
      );
      final certificate = _FakeCertificate([9, 10, 11, 12]);

      final callback = recordingClient.recordedBadCertificateCallback;

      expect(callback, isNotNull);
      expect(callback!(certificate, 'pi.hole', 443), isFalse);
    });

    test('ignoreCertificateErrors overrides pin validation', () {
      final recordingClient = _RecordingHttpClient();
      _createWithRecordingClient(
        recordingClient,
        ignoreCertificateErrors: true,
        pinnedCertificateSha256: _nonMatchingSha256,
      );
      final certificate = _FakeCertificate([13, 14, 15, 16]);

      final callback = recordingClient.recordedBadCertificateCallback;

      expect(callback, isNotNull);
      expect(callback!(certificate, 'pi.hole', 443), isTrue);
    });
  });
}
