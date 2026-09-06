import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/repositories/api/v6/group_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart' hide Success;
import 'package:result_dart/result_dart.dart';

import '../../../../../testing/fakes/services/fake_pihole_v6_api_client.dart';
import '../../../../../testing/fakes/services/fake_session_credential_service.dart';
import '../../../../../testing/helper/test_helper.dart';
import '../../../../../testing/models/v6/group.dart';

class _FakePiholeV6Service extends PiholeV6Service {
  _FakePiholeV6Service()
    : super(api: PiholeV6Api(basePathOverride: 'http://localhost/api'));

  bool shouldFailFetch = false;
  bool shouldFailAdd = false;
  bool shouldFailReplace = false;
  bool shouldFailDelete = false;
  String? lastSid;
  GroupsPost? lastAddBody;
  String? lastReplaceName;
  GroupsPut? lastReplaceBody;
  String? lastDeleteName;

  @override
  void setSid(String sid) {
    lastSid = sid;
  }

  @override
  Future<Result<GetGroups200Response>> getAllGroups() async {
    if (shouldFailFetch) {
      return Failure(Exception('Forced getAllGroups failure'));
    }
    return Success(GetGroups200Response.fromJson(kSrvGetGroups.toJson()));
  }

  @override
  Future<Result<ReplaceGroup200Response>> addGroup({GroupsPost? body}) async {
    lastAddBody = body;
    if (shouldFailAdd) {
      return Failure(Exception('Forced addGroup failure'));
    }
    return Success(ReplaceGroup200Response.fromJson(kSrvPostGroups.toJson()));
  }

  @override
  Future<Result<ReplaceGroup200Response>> replaceGroup({
    required String name,
    GroupsPut? body,
  }) async {
    lastReplaceName = name;
    lastReplaceBody = body;
    if (shouldFailReplace) {
      return Failure(Exception('Forced replaceGroup failure'));
    }
    return Success(ReplaceGroup200Response.fromJson(kSrvPutGroups.toJson()));
  }

  @override
  Future<Result<Unit>> deleteGroup({required String name}) async {
    lastDeleteName = name;
    if (shouldFailDelete) {
      return Failure(Exception('Forced deleteGroup failure'));
    }
    return Success(unit);
  }
}

void main() {
  late GroupRepositoryV6 repository;
  late FakePiholeV6ApiClient client;
  late FakeSessionCredentialService creds;
  late _FakePiholeV6Service service;

  setUp(() {
    creds = FakeSessionCredentialService();
    client = FakePiholeV6ApiClient();
    service = _FakePiholeV6Service();
    repository = GroupRepositoryV6(
      service: service,
      sessionCache: V6SessionCache(creds: creds, client: client),
    );
  });

  group('fetchGroups', () {
    test('should get groups successfully through generated service', () async {
      final result = await repository.fetchGroups();

      expect(result.getOrNull(), kRepoFetchGroups);
      expect(service.lastSid, 'sid123');
    });

    test('should fail when generated groups request fails', () async {
      service.shouldFailFetch = true;

      final result = await repository.fetchGroups();
      expectError(result, messageContains: 'Forced getAllGroups failure');
    });
  });

  group('addGroup', () {
    test('should add group successfully through generated service', () async {
      final result = await repository.addGroup(
        'NewGroup',
        comment: 'new comment',
        enabled: false,
      );

      expect(result.isSuccess(), true);
      expect(service.lastSid, 'sid123');
      expect(service.lastAddBody?.name?.value, 'NewGroup');
      expect(service.lastAddBody?.comment, 'new comment');
      expect(service.lastAddBody?.enabled, false);
    });

    test('should fail when generated add group request fails', () async {
      service.shouldFailAdd = true;

      final result = await repository.addGroup('NewGroup');
      expectError(result, messageContains: 'Forced addGroup failure');
    });
  });

  group('updateGroup', () {
    test(
      'should update group successfully through generated service',
      () async {
        final result = await repository.updateGroup(
          'test',
          comment: 'updated',
          enabled: false,
        );

        expect(result.isSuccess(), true);
        expect(service.lastSid, 'sid123');
        expect(service.lastReplaceName, 'test');
        expect(service.lastReplaceBody?.name, isNull);
        expect(service.lastReplaceBody?.comment, 'updated');
        expect(service.lastReplaceBody?.enabled, false);
      },
    );

    test('should fail when generated update group request fails', () async {
      service.shouldFailReplace = true;

      final result = await repository.updateGroup('test');
      expectError(result, messageContains: 'Forced replaceGroup failure');
    });
  });

  group('deleteGroup', () {
    test(
      'should delete group successfully through generated service',
      () async {
        final result = await repository.deleteGroup('test');

        expect(result.isSuccess(), true);
        expect(service.lastSid, 'sid123');
        expect(service.lastDeleteName, 'test');
      },
    );

    test('should fail when generated delete group request fails', () async {
      service.shouldFailDelete = true;

      final result = await repository.deleteGroup('test');
      expectError(result, messageContains: 'Forced deleteGroup failure');
    });
  });
}
