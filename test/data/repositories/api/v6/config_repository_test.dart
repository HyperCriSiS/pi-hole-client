import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/repositories/api/v6/config_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart' hide Success;
import 'package:result_dart/result_dart.dart';

import '../../../../../testing/fakes/services/fake_pihole_v6_api_client.dart';
import '../../../../../testing/fakes/services/fake_session_credential_service.dart';
import '../../../../../testing/helper/test_helper.dart';
import '../../../../../testing/models/v6/config.dart';

class _FakePiholeV6Service extends PiholeV6Service {
  _FakePiholeV6Service()
    : super(api: PiholeV6Api(basePathOverride: 'http://localhost/api'));

  bool shouldFailGet = false;
  bool shouldFailPatch = false;
  String? lastSid;
  GetConfig200Response? lastPatchBody;
  bool? lastRestart;

  @override
  void setSid(String sid) {
    lastSid = sid;
  }

  @override
  Future<Result<GetConfig200Response>> getConfig() async {
    if (shouldFailGet) {
      return Failure(Exception('Forced generated getConfig failure'));
    }
    return Success(
      GetConfig200Response(
        config: ConfigConfig(dns: ConfigConfigDns(queryLogging: true)),
        took: 0.003,
      ),
    );
  }

  @override
  Future<Result<GetConfig200Response>> patchConfig({
    GetConfig200Response? body,
    bool? restart,
  }) async {
    lastPatchBody = body;
    lastRestart = restart;
    if (shouldFailPatch) {
      return Failure(Exception('Forced generated patchConfig failure'));
    }
    return Success(
      GetConfig200Response(
        config: ConfigConfig(dns: ConfigConfigDns(queryLogging: false)),
        took: 0.003,
      ),
    );
  }
}

void main() {
  late ConfigRepositoryV6 repository;
  late FakePiholeV6ApiClient client;
  late FakeSessionCredentialService creds;
  late _FakePiholeV6Service service;

  setUp(() {
    client = FakePiholeV6ApiClient();
    creds = FakeSessionCredentialService();
    service = _FakePiholeV6Service();
    repository = ConfigRepositoryV6(
      service: service,
      sessionCache: V6SessionCache(creds: creds, client: client),
    );
  });

  group('fetchDnsQueryLogging', () {
    test(
      'reads query logging through generated full config endpoint',
      () async {
        final result = await repository.fetchDnsQueryLogging();

        expect(result.getOrNull(), kRepoFetchDnsQueryLogging);
        expect(service.lastSid, 'sid123');
        expect(service.lastPatchBody, isNull);
      },
    );

    test('fails when generated full config read fails', () async {
      service.shouldFailGet = true;

      final result = await repository.fetchDnsQueryLogging();
      expectError(
        result,
        messageContains: 'Forced generated getConfig failure',
      );
    });
  });

  group('setDnsQueryLogging', () {
    test('updates query logging through generated service only', () async {
      final result = await repository.setDnsQueryLogging(false);

      expect(result.getOrNull(), kRepoSetDnsQueryLogging);
      expect(service.lastSid, 'sid123');
      expect(service.lastRestart, true);
      expect(service.lastPatchBody?.toJson(), {
        'config': {
          'dns': {'queryLogging': false},
        },
      });
    });

    test('fails when generated query logging update fails', () async {
      service.shouldFailPatch = true;

      final result = await repository.setDnsQueryLogging(false);
      expectError(
        result,
        messageContains: 'Forced generated patchConfig failure',
      );
    });
  });
}
