import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/repositories/api/v6/domain_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache.dart';
import 'package:pi_hole_client/data/services/api/utils/api_exception.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pi_hole_client/domain/model/enums.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart' hide Success;
import 'package:result_dart/result_dart.dart';

import '../../../../../testing/fakes/services/fake_pihole_v6_api_client.dart';
import '../../../../../testing/fakes/services/fake_session_credential_service.dart';
import '../../../../../testing/models/v6/domain.dart';

class _RetryDomainService extends PiholeV6Service {
  _RetryDomainService()
    : super(api: PiholeV6Api(basePathOverride: 'http://localhost/api'));

  int fetchCallCount = 0;
  int addCallCount = 0;
  int replaceCallCount = 0;
  int deleteCallCount = 0;
  String? lastSid;
  String? lastAddType;
  String? lastAddKind;
  Post? lastAddBody;
  String? lastReplaceType;
  String? lastReplaceKind;
  String? lastReplaceDomain;
  ReplaceDomainRequest? lastReplaceBody;
  String? lastDeleteType;
  String? lastDeleteKind;
  String? lastDeleteDomain;

  @override
  void setSid(String sid) {
    lastSid = sid;
  }

  @override
  Future<Result<GetDomain200Response>> getAllDomains() async {
    fetchCallCount++;
    if (fetchCallCount == 1) {
      return Failure(ApiException(message: 'Unauthorized', statusCode: 401));
    }
    return Success(GetDomain200Response.fromJson(kSrvGetDomains.toJson()));
  }

  @override
  Future<Result<ReplaceDomain200Response>> addDomain({
    required String type,
    required String kind,
    Post? body,
  }) async {
    addCallCount++;
    lastAddType = type;
    lastAddKind = kind;
    lastAddBody = body;
    if (addCallCount == 1) {
      return Failure(ApiException(message: 'Unauthorized', statusCode: 401));
    }
    return Success(ReplaceDomain200Response.fromJson(kSrvPostDomains.toJson()));
  }

  @override
  Future<Result<ReplaceDomain200Response>> replaceDomain({
    required String type,
    required String kind,
    required String domain,
    ReplaceDomainRequest? body,
  }) async {
    replaceCallCount++;
    lastReplaceType = type;
    lastReplaceKind = kind;
    lastReplaceDomain = domain;
    lastReplaceBody = body;
    if (replaceCallCount == 1) {
      return Failure(ApiException(message: 'Unauthorized', statusCode: 401));
    }
    return Success(ReplaceDomain200Response.fromJson(kSrvPutDomains.toJson()));
  }

  @override
  Future<Result<Unit>> deleteDomain({
    required String type,
    required String kind,
    required String domain,
  }) async {
    deleteCallCount++;
    lastDeleteType = type;
    lastDeleteKind = kind;
    lastDeleteDomain = domain;
    if (deleteCallCount == 1) {
      return Failure(ApiException(message: 'Unauthorized', statusCode: 401));
    }
    return Success(unit);
  }
}

DomainRepositoryV6 _repository({
  required FakePiholeV6ApiClient client,
  required FakeSessionCredentialService creds,
  required _RetryDomainService service,
}) {
  return DomainRepositoryV6(
    service: service,
    sessionCache: V6SessionCache(creds: creds, client: client),
  );
}

void main() {
  test('renews SID and retries generated domain read after 401', () async {
    final client = FakePiholeV6ApiClient();
    final creds = FakeSessionCredentialService();
    final service = _RetryDomainService();
    final repository = _repository(
      client: client,
      creds: creds,
      service: service,
    );

    final result = await repository.fetchAllDomains();

    expect(result.getOrNull(), kRepoFetchAllDomains);
    expect(client.postAuthCallCount, 1);
    expect(service.fetchCallCount, 2);
    expect(service.lastSid, isNot('sid123'));
  });

  test('renews SID and retries generated domain add after 401', () async {
    final client = FakePiholeV6ApiClient();
    final creds = FakeSessionCredentialService();
    final service = _RetryDomainService();
    final repository = _repository(
      client: client,
      creds: creds,
      service: service,
    );

    final result = await repository.addDomain(
      DomainType.deny,
      DomainKind.regex,
      'example.com',
      comment: 'new comment',
      groups: [2],
      enabled: false,
    );

    expect(result.isSuccess(), true);
    expect(client.postAuthCallCount, 1);
    expect(service.addCallCount, 2);
    expect(service.lastAddType, 'deny');
    expect(service.lastAddKind, 'regex');
    expect(service.lastAddBody?.domain?.value, 'example.com');
    expect(service.lastAddBody?.comment, 'new comment');
    expect(service.lastAddBody?.groups, [2]);
    expect(service.lastAddBody?.enabled, false);
    expect(service.lastSid, isNot('sid123'));
  });

  test('renews SID and retries generated domain update after 401', () async {
    final client = FakePiholeV6ApiClient();
    final creds = FakeSessionCredentialService();
    final service = _RetryDomainService();
    final repository = _repository(
      client: client,
      creds: creds,
      service: service,
    );

    final result = await repository.updateDomain(
      DomainType.allow,
      DomainKind.exact,
      'example.com',
      comment: 'updated',
      groups: [1],
      enabled: false,
    );

    expect(result.isSuccess(), true);
    expect(client.postAuthCallCount, 1);
    expect(service.replaceCallCount, 2);
    expect(service.lastReplaceType, 'allow');
    expect(service.lastReplaceKind, 'exact');
    expect(service.lastReplaceDomain, 'example.com');
    expect(service.lastReplaceBody?.type?.value, 'allow');
    expect(service.lastReplaceBody?.kind?.value, 'exact');
    expect(service.lastReplaceBody?.comment, 'updated');
    expect(service.lastReplaceBody?.groups, [1]);
    expect(service.lastReplaceBody?.enabled, false);
    expect(service.lastSid, isNot('sid123'));
  });

  test('renews SID and retries generated domain delete after 401', () async {
    final client = FakePiholeV6ApiClient();
    final creds = FakeSessionCredentialService();
    final service = _RetryDomainService();
    final repository = _repository(
      client: client,
      creds: creds,
      service: service,
    );

    final result = await repository.deleteDomain(
      DomainType.deny,
      DomainKind.exact,
      'example.com',
    );

    expect(result.isSuccess(), true);
    expect(client.postAuthCallCount, 1);
    expect(service.deleteCallCount, 2);
    expect(service.lastDeleteType, 'deny');
    expect(service.lastDeleteKind, 'exact');
    expect(service.lastDeleteDomain, 'example.com');
    expect(service.lastSid, isNot('sid123'));
  });
}
