import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pi_hole_client/data/services/api/pihole_v6_api_client.dart';

import '../../../../testing/helper/test_helper.dart';
import '../utils/mocks.mocks.dart';

void main() {
  test('preserves the configured subroute for v6 API requests', () async {
    const baseUrl = 'http://localhost:8080';
    final mockClient = MockClient();
    final apiClient = PiholeV6ApiClient(
      url: '$baseUrl/pihole',
      client: mockClient,
    );
    final url = Uri.parse('$baseUrl/pihole/api/auth');
    final response = http.Response(
      jsonEncode({
        'session': {
          'valid': true,
          'totp': false,
          'sid': 'test-sid',
          'csrf': 'test-csrf',
          'validity': 300,
          'message': 'correct password',
        },
        'took': 0.01,
      }),
      200,
    );
    mockPost(mockClient, url, response);

    final result = await apiClient.postAuth(password: 'test');

    expect(result.isSuccess(), isTrue);
  });
}
