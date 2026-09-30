import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';

void main() {
  test('preserves the configured subroute for generated v6 requests', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));

    String? requestPath;
    final responseFuture = server.first.then((request) async {
      requestPath = request.uri.path;
      await utf8.decoder.bind(request).join();
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'session': {
            'valid': true,
            'totp': false,
            'sid': 'generated-sid',
            'validity': 300,
            'message': 'correct password',
          },
          'took': 0.01,
        }),
      );
      await request.response.close();
    });

    final service = PiholeV6Service.fromConnection(
      url: 'http://127.0.0.1:${server.port}/pihole',
    );

    final result = await service.postAuth(password: 'test');
    await responseFuture;

    expect(requestPath, '/pihole/api/auth');
    expect(result.isSuccess(), isTrue);
  });
}
