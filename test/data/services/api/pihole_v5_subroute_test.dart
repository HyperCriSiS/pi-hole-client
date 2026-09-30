import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pi_hole_client/data/model/v5/domains.dart';
import 'package:pi_hole_client/data/services/api/pihole_v5_api_client.dart';

import '../../../../testing/helper/test_helper.dart';
import '../utils/mocks.mocks.dart';

void main() {
  test('preserves the configured subroute for v5 API requests', () async {
    const baseUrl = 'http://localhost:8080';
    const token = 'token12345';
    final mockClient = MockClient();
    final apiClient = PiholeV5ApiClient(
      url: '$baseUrl/pihole',
      client: mockClient,
    );
    final url = Uri.parse(
      '$baseUrl/pihole/admin/api.php?auth=$token&list=white&add=example.com',
    );
    final response = http.Response(
      jsonEncode({'success': true, 'message': 'Added example.com'}),
      200,
    );
    mockGet(mockClient, url, response);

    final result = await apiClient.postDomain(
      token,
      domain: 'example.com',
      domainType: V5DomainType.white,
    );

    expect(result.isSuccess(), isTrue);
  });
}
