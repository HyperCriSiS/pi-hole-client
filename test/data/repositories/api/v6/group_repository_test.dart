import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/repositories/api/v6/group_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart';
import 'package:result_dart/result_dart.dart';

import '../../../../../testing/fakes/services/fake_pihole_v6_api_client.dart';
import '../../../../../testing/fakes/services/fake_session_credential_service.dart';
import '../../../../../testing/helper/test_helper.dart';
import '../../../../../testing/models/v6/group.dart';

class _FakePiholeV6Service extends PiholeV6Service {
  _FakePiholeV6Service()
    : super(api: PiholeV6Api(basePathOverride: 'http://localhost/api'));

  bool shouldFailGetGroups = false;
  String? lastSid;

  @override
  void setSid(String sid) {
    lastSid = sid;
  }

  @override
  Future<Result<GetGroups200Response>> getAllGroups() async {
    if (shouldFailGetGroups) {
      return Failure(Exception('Forced generated getAllGroups failure'));
    }
    return Success(GetGroups200Response.fromJson(kSrvGetGroups.toJson()));
  }
}

void main() {
  late GroupRepositoryV6 repository;
  late FakePiholeV6ApiClient client;
  late _FakePiholeV6Service service;
  late FakeSessionCredentialService creds;

  setUp(() {
    creds = FakeSessionCredentialService();
    client = FakePiholeV6ApiClient();
    service = _FakePiholeV6Service();
    repository = GroupRepositoryV6(
      client: client,
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

    test('should fail when generated group fetch fails', () async {
      service.shouldFailGetGroups = true;

      final result = await repository.fetchGroups();
      expectError(
        result,
        messageContains: 'Forced generated getAllGroups failure',
      );
    });
  });

  group('addGroup', () {
    test('should add group successfully', () async {
      final result = await repository.addGroup('NewGroup');
      expect(result.isSuccess(), true);
    });

    test('should fail when adding group', () async {
      client.shouldFail = true;

      final result = await repository.addGroup('NewGroup');
      expectError(result, messageContains: 'Forced postGroups failure');
    });
  });

  group('updateGroup', () {
    test('should update group successfully', () async {
      final result = await repository.updateGroup(
        'test',
        comment: 'updated',
        enabled: false,
      );
      expect(result.isSuccess(), true);
    });

    test('should fail when updating group', () async {
      client.shouldFail = true;

      final result = await repository.updateGroup('test');
      expectError(result, messageContains: 'Forced putGroups failure');
    });
  });

  group('deleteGroup', () {
    test('should delete group successfully', () async {
      final result = await repository.deleteGroup('test');
      expect(result.isSuccess(), true);
    });

    test('should fail when deleting group', () async {
      client.shouldFail = true;

      final result = await repository.deleteGroup('test');
      expectError(result, messageContains: 'Forced deleteGroups failure');
    });
  });
}
