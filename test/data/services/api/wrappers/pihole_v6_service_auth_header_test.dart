import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart';

void main() {
  test('clearSid removes only the generated x_header_sid API key', () {
    final api = PiholeV6Api(basePathOverride: 'http://localhost/api');
    final service = PiholeV6Service(api: api);
    final authInterceptor = api.dio.interceptors
        .whereType<ApiKeyAuthInterceptor>()
        .single;

    authInterceptor.apiKeys['other'] = 'keep';
    service.setSid('sid-123');

    expect(authInterceptor.apiKeys['x_header_sid'], 'sid-123');

    service.clearSid();

    expect(authInterceptor.apiKeys.containsKey('x_header_sid'), isFalse);
    expect(authInterceptor.apiKeys['other'], 'keep');
  });
}
