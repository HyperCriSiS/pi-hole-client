import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart' hide Success;
import 'package:result_dart/result_dart.dart';

import '../../../../../testing/fakes/services/fake_session_credential_service.dart';

class _GeneratedAuthService extends PiholeV6Service {
  _GeneratedAuthService()
    : super(api: PiholeV6Api(basePathOverride: 'http://localhost/api'));

  int postAuthCallCount = 0;

  @override
  Future<Result<GetAuth200Response>> postAuth({
    required String password,
    int? totp,
  }) async {
    postAuthCallCount++;
    return Success(
      GetAuth200Response(
        session: SessionSession(
          valid: true,
          totp: false,
          sid: 'generated-sid',
          csrf: 'csrf-token',
          validity: 300,
          message: 'correct password',
        ),
      ),
    );
  }
}

void main() {
  test('production service seam renews and caches SID through generated auth', () async {
    final creds = FakeSessionCredentialService();
    final service = _GeneratedAuthService();
    final cache = V6SessionCache(creds: creds, service: service);

    await cache.clearAndRenewSid();

    expect(service.postAuthCallCount, 1);
    expect(creds.deleteSidCallCount, 1);
    expect(creds.lastSavedSid, 'generated-sid');

    creds.shouldFailRead = true;
    expect(await cache.getSid(), 'generated-sid');
  });
}
