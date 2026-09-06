import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/model/v6/metrics/query_filter.dart';

void main() {
  group('V6QueryFilter', () {
    test('maps supported Pi-hole v6 query filters to API parameter names', () {
      const filter = V6QueryFilter(
        domain: 'gravity.ftl',
        clientIp: '127.0.0.1',
        status: 'GRAVITY',
        type: 'AAAA',
        reply: 'IP',
      );

      expect(filter.toQueryParameters(), {
        'domain': 'gravity.ftl',
        'client_ip': '127.0.0.1',
        'status': 'GRAVITY',
        'type': 'AAAA',
        'reply': 'IP',
      });
      expect(filter.isEmpty, isFalse);
    });

    test('omits null, empty, and whitespace-only filters', () {
      const filter = V6QueryFilter(domain: '  ', status: '', clientIp: null);

      expect(filter.toQueryParameters(), isEmpty);
      expect(filter.isEmpty, isTrue);
    });

    test('trims values before transport', () {
      const filter = V6QueryFilter(
        domain: ' example.com ',
        clientIp: ' 192.0.2.1 ',
      );

      expect(filter.toQueryParameters(), {
        'domain': 'example.com',
        'client_ip': '192.0.2.1',
      });
    });
  });
}
