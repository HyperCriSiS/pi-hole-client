import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/repositories/api/v6/dns_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart' hide Success;
import 'package:result_dart/result_dart.dart';

import '../../../../../testing/fakes/services/fake_pihole_v6_api_client.dart';
import '../../../../../testing/fakes/services/fake_session_credential_service.dart';
import '../../../../../testing/helper/test_helper.dart';
import '../../../../../testing/models/v6/dns.dart';

class _FakePiholeV6Service extends PiholeV6Service {
  _FakePiholeV6Service()
    : super(api: PiholeV6Api(basePathOverride: 'http://localhost/api'));

  bool shouldFailGetDnsBlocking = false;
  bool shouldFailSetDnsBlocking = false;
  String? lastSid;
  SetBlockingRequest? lastRequest;

  @override
  void setSid(String sid) {
    lastSid = sid;
  }

  @override
  Future<Result<GetBlocking200Response>> getDnsBlocking() async {
    if (shouldFailGetDnsBlocking) {
      return Failure(Exception('Forced getDnsBlocking failure'));
    }
    return Success(
      GetBlocking200Response.fromJson(kSrvGetDnsBlocking.toJson()),
    );
  }

  @override
  Future<Result<GetBlocking200Response>> setDnsBlocking({
    SetBlockingRequest? request,
  }) async {
    lastRequest = request;
    if (shouldFailSetDnsBlocking) {
      return Failure(Exception('Forced setDnsBlocking failure'));
    }
    final fixture = request?.blocking == false
        ? kSrvPostDnsBlockingDisabled
        : kSrvPostDnsBlockingEnabled;
    return Success(GetBlocking200Response.fromJson(fixture.toJson()));
  }
}

void main() {
  late DnsRepositoryV6 repository;
  late FakePiholeV6ApiClient client;
  late FakeSessionCredentialService creds;
  late _FakePiholeV6Service service;

  setUp(() {
    client = FakePiholeV6ApiClient();
    creds = FakeSessionCredentialService();
    service = _FakePiholeV6Service();
    repository = DnsRepositoryV6(
      service: service,
      sessionCache: V6SessionCache(creds: creds, client: client),
    );
  });

  group('fetchBlockingStatus', () {
    test('should fetch DNS blocking status through generated service', () async {
      final result = await repository.fetchBlockingStatus();

      expect(result.getOrNull(), kRepoFetchDnsBlocking);
      expect(service.lastSid, 'sid123');
    });

    test('should fail when generated DNS blocking fetch fails', () async {
      service.shouldFailGetDnsBlocking = true;

      final result = await repository.fetchBlockingStatus();
      expectError(result, messageContains: 'Forced getDnsBlocking failure');
    });
  });

  group('enableBlocking', () {
    test('should enable DNS blocking through generated service', () async {
      final result = await repository.enableBlocking();

      expect(result.getOrNull(), kRepoEnableDnsBlocking);
      expect(service.lastSid, 'sid123');
      expect(service.lastRequest?.blocking, isTrue);
      expect(service.lastRequest?.timer, isNull);
    });

    test('should fail when generated DNS blocking update fails', () async {
      service.shouldFailSetDnsBlocking = true;

      final result = await repository.enableBlocking();
      expectError(result, messageContains: 'Forced setDnsBlocking failure');
    });
  });

  group('disableBlocking', () {
    test(
      'should disable DNS blocking with timer through generated service',
      () async {
        final result = await repository.disableBlocking(30);

        expect(result.getOrNull(), kRepoDisableDnsBlocking);
        expect(service.lastSid, 'sid123');
        expect(service.lastRequest?.blocking, isFalse);
        expect(service.lastRequest?.timer, 30);
      },
    );

    test('should fail when generated DNS blocking disable fails', () async {
      service.shouldFailSetDnsBlocking = true;

      final result = await repository.disableBlocking(30);
      expectError(result, messageContains: 'Forced setDnsBlocking failure');
    });
  });
}
