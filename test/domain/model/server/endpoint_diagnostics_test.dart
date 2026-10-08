import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/services/api/utils/api_exception.dart';
import 'package:pi_hole_client/domain/model/server/endpoint_diagnostics.dart';
import 'package:pi_hole_client/utils/exceptions.dart';

void main() {
  test('endpoint paths have fixed, non-secret v6 routes', () {
    expect(FtlEndpoint.values.map((e) => e.path), [
      '/api/info/host',
      '/api/info/sensors',
      '/api/info/system',
      '/api/info/version',
    ]);
  });

  test('classifies structured failures without exposing messages', () {
    expect(classifyEndpointError(SidNotFoundException()), EndpointOutcome.authentication);
    expect(classifyEndpointError(TotpRequiredException()), EndpointOutcome.authentication);
    expect(classifyEndpointError(HttpStatusCodeException(401, 'SID=secret')), EndpointOutcome.authentication);
    expect(classifyEndpointError(ApiException(message: 'password=secret', statusCode: 403)), EndpointOutcome.authentication);
    expect(classifyEndpointError(HttpStatusCodeException(495)), EndpointOutcome.tls);
    expect(classifyEndpointError(HandshakeException('cert')), EndpointOutcome.tls);
    expect(classifyEndpointError(TimeoutException('slow')), EndpointOutcome.timeout);
    expect(classifyEndpointError(HttpStatusCodeException(504)), EndpointOutcome.timeout);
    expect(classifyEndpointError(SocketException('unreachable')), EndpointOutcome.connection);
    expect(classifyEndpointError(ApiException(message: 'not found', statusCode: 404)), EndpointOutcome.notFound);
    expect(classifyEndpointError(HttpStatusCodeException(503)), EndpointOutcome.server);
    expect(classifyEndpointError(Exception('token=secret')), EndpointOutcome.unknown);
  });
}
