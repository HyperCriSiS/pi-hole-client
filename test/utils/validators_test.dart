import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/utils/validators.dart';

void main() {
  group('isValidServerAddress', () {
    test('accepts an IPv4 address', () {
      expect(isValidServerAddress('192.168.1.10'), isTrue);
      expect(isValidServerAddress('10.0.0.1'), isTrue);
    });

    test('accepts a hostname and a domain', () {
      expect(isValidServerAddress('pi.hole'), isTrue);
      expect(isValidServerAddress('localhost'), isTrue);
      expect(isValidServerAddress('my-server.example.com'), isTrue);
    });

    test('rejects an empty value', () {
      expect(isValidServerAddress(''), isFalse);
    });

    test('rejects a value with no host-like characters', () {
      expect(isValidServerAddress('!!!'), isFalse);
    });
  });

  group('isValidPort', () {
    test('accepts ports within range', () {
      expect(isValidPort('0'), isTrue);
      expect(isValidPort('8080'), isTrue);
      expect(isValidPort('65535'), isTrue);
    });

    test('rejects ports above the maximum', () {
      expect(isValidPort('65536'), isFalse);
      expect(isValidPort('99999'), isFalse);
    });

    test('rejects ports below the minimum', () {
      expect(isValidPort('-1'), isFalse);
    });

    test('rejects non-numeric values', () {
      expect(isValidPort('abc'), isFalse);
      expect(isValidPort('80a'), isFalse);
      expect(isValidPort(''), isFalse);
    });
  });

  group('normalizeLocalDnsNames', () {
    test('trims and collapses whitespace', () {
      expect(normalizeLocalDnsNames(' test '), 'test');
      expect(normalizeLocalDnsNames('test   ok'), 'test ok');
      expect(normalizeLocalDnsNames('test\tok'), 'test ok');
    });

    test('returns empty for whitespace only', () {
      expect(normalizeLocalDnsNames('   '), '');
    });
  });

  group('isValidLocalDnsNames', () {
    test('accepts one or more valid hostnames', () {
      expect(isValidLocalDnsNames('nas'), isTrue);
      expect(isValidLocalDnsNames('nas nas.local my_host-1'), isTrue);
      expect(isValidLocalDnsNames(' nas  ok '), isTrue);
    });

    test('rejects invalid or empty hostnames', () {
      expect(isValidLocalDnsNames('test o!k'), isFalse);
      expect(isValidLocalDnsNames(''), isFalse);
      expect(isValidLocalDnsNames('   '), isFalse);
    });
  });

  group('isValidSubroute', () {
    test('accepts a leading-slash path', () {
      expect(isValidSubroute('/admin'), isTrue);
      expect(isValidSubroute('/api/v1'), isTrue);
    });

    test('rejects a path without a leading slash', () {
      expect(isValidSubroute('admin'), isFalse);
    });

    test('rejects a trailing slash, dot or colon', () {
      expect(isValidSubroute('/admin/'), isFalse);
      expect(isValidSubroute('/admin.'), isFalse);
      expect(isValidSubroute('/admin:'), isFalse);
    });
  });
}
