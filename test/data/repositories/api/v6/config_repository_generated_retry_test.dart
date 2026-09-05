import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/repositories/api/v6/config_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache.dart';
import 'package:pi_hole_client/data/services/api/utils/api_exception.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart' hide Success;
import 'package:result_dart/result_dart.dart';

import '../../../../../testing/fakes/services/fake_pihole_v6_api_client.dart';
import '../../../../../testing/fakes/services/fake_session_credential_service.dart';
import '../../../../../testing/models/v6/config.dart';

class _RetryConfigService extends PiholeV6Service {
  _RetryConfigService()
    : super(api: PiholeV6Api(basePathOverride: 'http://localhost/api'));

  int patchCallCount = 0;
  String? lastSid;
  GetConfig200Response? lastPatchBody;
  bool? lastRestart;

  @override
  void setSid(String sid) {
    lastSid = sid;
  }

  @override
  Future<Result<GetConfig200Response>> patchConfig({
    GetConfig200Response? body,
    bool? restart,
  }) async {
    patchCallCount++;
    lastPatchBody = body;
    lastRestart = restart;
    if (patchCallCount == 1) {
      return Failure(ApiException(message: 'Unauthorized', statusCode: 401));
    }
    return Success(
      GetConfig200Response(
        config: ConfigConfig(
          dns: ConfigConfigDns(queryLogging: false),
        ),
        took: 0.003,
      ),
    );
  }
}

void main() {
  test('renews SID and retries generated query logging update after 401', () async {
    final client = FakePiholeV6ApiClient();
    final creds = FakeSessionCredentialService();
    final service = _RetryConfigService();
    final repository = ConfigRepositoryV6(
      client: client,
      service: service,
      sessionCache: V6SessionCache(creds: creds, client: client),
    );

    final result = await repository.setDnsQueryLogging(false);

    expect(result.getOrNull(), kRepoSetDnsQueryLogging);
    expect(client.postAuthCallCount, 1);
    expect(service.patchCallCount, 2);
    expect(service.lastSid, isNot('sid123'));
    expect(service.lastRestart, true);
    expect(service.lastPatchBody?.toJson(), {
      'config': {
        'dns': {'queryLogging': false},
      },
    });
  });
}
