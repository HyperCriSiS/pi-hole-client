import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/repositories/api/v6/group_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache.dart';
import 'package:pi_hole_client/data/services/api/utils/api_exception.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart' hide Success;
import 'package:result_dart/result_dart.dart';

import '../../../../../testing/fakes/services/fake_pihole_v6_api_client.dart';
import '../../../../../testing/fakes/services/fake_session_credential_service.dart';
import '../../../../../testing/models/v6/group.dart';

class _RetryGroupService extends PiholeV6Service {
  _RetryGroupService()
    : super(api: PiholeV6Api(basePathOverride: 'http://localhost/api'));

  int fetchCallCount = 0;
  int addCallCount = 0;
  int replaceCallCount = 0;
  int deleteCallCount = 0;
  String? lastSid;
  Post2? lastAddBody;
  String? lastReplaceName;
  Put2? lastReplaceBody;
  String? lastDeleteName;

  @override
  void setSid(String sid) {
    lastSid = sid;
  }

  @override
  Future<Result<GetGroups200Response>> getAllGroups() async {
    fetchCallCount++;
    if (fetchCallCount == 1) {
      return Failure(ApiException(message: 'Unauthorized', statusCode: 401));
    }
    return Success(GetGroups200Response.fromJson(kSrvGetGroups.toJson()));
  }

  @override
  Future<Result<ReplaceGroup200Response>> addGroup({Post2? body}) async {
    addCallCount++;
    lastAddBody = body;
    if (addCallCount == 1) {
      return Failure(ApiException(message: 'Unauthorized', statusCode: 401));
    }
    return Success(ReplaceGroup200Response.fromJson(kSrvPostGroups.toJson()));
  }

  @override
  Future<Result<ReplaceGroup200Response>> replaceGroup({
    required String name,
    Put2? body,
  }) async {
    replaceCallCount++;
    lastReplaceName = name;
    lastReplaceBody = body;
    if (replaceCallCount == 1) {
      return Failure(ApiException(message: 'Unauthorized', statusCode: 401));
    }
    return Success(ReplaceGroup200Response.fromJson(kSrvPutGroups.toJson()));
  }

  @override
  Future<Result<Unit>> deleteGroup({required String name}) async {
    deleteCallCount++;
    lastDeleteName = name;
    if (deleteCallCount == 1) {
      return Failure(ApiException(message: 'Unauthorized', statusCode: 401));
    }
    return Success(unit);
  }
}

GroupRepositoryV6 _repository({
  required FakePiholeV6ApiClient client,
  required FakeSessionCredentialService creds,
  required _RetryGroupService service,
}) {
  return GroupRepositoryV6(
    service: service,
    sessionCache: V6SessionCache(creds: creds, client: client),
  );
}

void main() {
  test('renews SID and retries generated group read after 401', () async {
    final client = FakePiholeV6ApiClient();
    final creds = FakeSessionCredentialService();
    final service = _RetryGroupService();
    final repository = _repository(
      client: client,
      creds: creds,
      service: service,
    );

    final result = await repository.fetchGroups();

    expect(result.getOrNull(), kRepoFetchGroups);
    expect(client.postAuthCallCount, 1);
    expect(service.fetchCallCount, 2);
    expect(service.lastSid, isNot('sid123'));
  });

  test('renews SID and retries generated group add after 401', () async {
    final client = FakePiholeV6ApiClient();
    final creds = FakeSessionCredentialService();
    final service = _RetryGroupService();
    final repository = _repository(
      client: client,
      creds: creds,
      service: service,
    );

    final result = await repository.addGroup(
      'NewGroup',
      comment: 'new comment',
      enabled: false,
    );

    expect(result.isSuccess(), true);
    expect(client.postAuthCallCount, 1);
    expect(service.addCallCount, 2);
    expect(service.lastAddBody?.name?.value, 'NewGroup');
    expect(service.lastAddBody?.comment, 'new comment');
    expect(service.lastAddBody?.enabled, false);
    expect(service.lastSid, isNot('sid123'));
  });

  test('renews SID and retries generated group update after 401', () async {
    final client = FakePiholeV6ApiClient();
    final creds = FakeSessionCredentialService();
    final service = _RetryGroupService();
    final repository = _repository(
      client: client,
      creds: creds,
      service: service,
    );

    final result = await repository.updateGroup(
      'test',
      comment: 'updated',
      enabled: false,
    );

    expect(result.isSuccess(), true);
    expect(client.postAuthCallCount, 1);
    expect(service.replaceCallCount, 2);
    expect(service.lastReplaceName, 'test');
    expect(service.lastReplaceBody?.comment, 'updated');
    expect(service.lastReplaceBody?.enabled, false);
    expect(service.lastSid, isNot('sid123'));
  });

  test('renews SID and retries generated group delete after 401', () async {
    final client = FakePiholeV6ApiClient();
    final creds = FakeSessionCredentialService();
    final service = _RetryGroupService();
    final repository = _repository(
      client: client,
      creds: creds,
      service: service,
    );

    final result = await repository.deleteGroup('test');

    expect(result.isSuccess(), true);
    expect(client.postAuthCallCount, 1);
    expect(service.deleteCallCount, 2);
    expect(service.lastDeleteName, 'test');
    expect(service.lastSid, isNot('sid123'));
  });
}
