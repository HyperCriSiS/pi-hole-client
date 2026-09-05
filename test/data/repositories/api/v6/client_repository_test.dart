import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/repositories/api/v6/client_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart' hide Success;
import 'package:result_dart/result_dart.dart';

import '../../../../../testing/fakes/services/fake_pihole_v6_api_client.dart';
import '../../../../../testing/fakes/services/fake_session_credential_service.dart';
import '../../../../../testing/helper/test_helper.dart';
import '../../../../../testing/models/v6/client.dart';

class _FakePiholeV6Service extends PiholeV6Service {
  _FakePiholeV6Service()
    : super(api: PiholeV6Api(basePathOverride: 'http://localhost/api'));

  bool shouldFailFetch = false;
  bool shouldFailAdd = false;
  bool shouldFailReplace = false;
  bool shouldFailDelete = false;
  String? lastSid;
  AddClientRequest? lastAddBody;
  String? lastReplaceClient;
  ReplaceClientRequest? lastReplaceBody;
  String? lastDeleteClient;

  @override
  void setSid(String sid) {
    lastSid = sid;
  }

  @override
  Future<Result<GetClients200Response>> getAllClients() async {
    if (shouldFailFetch) {
      return Failure(Exception('Forced getAllClients failure'));
    }
    return Success(GetClients200Response.fromJson(kSrvGetClients.toJson()));
  }

  @override
  Future<Result<ReplaceClient200Response>> addClient({
    AddClientRequest? body,
  }) async {
    lastAddBody = body;
    if (shouldFailAdd) {
      return Failure(Exception('Forced addClient failure'));
    }
    return Success(ReplaceClient200Response.fromJson(kSrvPostClients.toJson()));
  }

  @override
  Future<Result<ReplaceClient200Response>> replaceClient({
    required String client,
    ReplaceClientRequest? body,
  }) async {
    lastReplaceClient = client;
    lastReplaceBody = body;
    if (shouldFailReplace) {
      return Failure(Exception('Forced replaceClient failure'));
    }
    return Success(ReplaceClient200Response.fromJson(kSrvPutClients.toJson()));
  }

  @override
  Future<Result<Unit>> deleteClient({required String client}) async {
    lastDeleteClient = client;
    if (shouldFailDelete) {
      return Failure(Exception('Forced deleteClient failure'));
    }
    return Success(unit);
  }
}

void main() {
  late ClientRepositoryV6 repository;
  late FakePiholeV6ApiClient client;
  late FakeSessionCredentialService creds;
  late _FakePiholeV6Service service;

  setUp(() {
    creds = FakeSessionCredentialService();
    client = FakePiholeV6ApiClient();
    service = _FakePiholeV6Service();
    repository = ClientRepositoryV6(
      service: service,
      sessionCache: V6SessionCache(creds: creds, client: client),
    );
  });

  group('fetchClients', () {
    test('should get clients through generated service', () async {
      final result = await repository.fetchClients();

      expect(result.getOrNull(), kRepoFetchClients);
      expect(service.lastSid, 'sid123');
    });

    test('should fail when generated client read fails', () async {
      service.shouldFailFetch = true;

      final result = await repository.fetchClients();
      expectError(result, messageContains: 'Forced getAllClients failure');
    });
  });

  group('addClient', () {
    test('should add client through generated service', () async {
      final result = await repository.addClient(
        '10.0.0.1',
        comment: 'new client',
        groups: [0, 5],
      );

      expect(result.isSuccess(), true);
      expect(service.lastSid, 'sid123');
      expect(service.lastAddBody?.client?.value, '10.0.0.1');
      expect(service.lastAddBody?.comment, 'new client');
      expect(service.lastAddBody?.groups, [0, 5]);
    });

    test('should fail when generated add client request fails', () async {
      service.shouldFailAdd = true;

      final result = await repository.addClient('10.0.0.1');
      expectError(result, messageContains: 'Forced addClient failure');
    });
  });

  group('updateClient', () {
    test('should update client through generated service', () async {
      final result = await repository.updateClient(
        '192.168.1.100',
        comment: 'updated',
        groups: [0, 5],
      );

      expect(result.isSuccess(), true);
      expect(service.lastSid, 'sid123');
      expect(service.lastReplaceClient, '192.168.1.100');
      expect(service.lastReplaceBody?.comment, 'updated');
      expect(service.lastReplaceBody?.groups, [0, 5]);
    });

    test('should fail when generated replace client request fails', () async {
      service.shouldFailReplace = true;

      final result = await repository.updateClient('192.168.1.100');
      expectError(result, messageContains: 'Forced replaceClient failure');
    });
  });

  group('deleteClient', () {
    test('should delete client through generated service', () async {
      final result = await repository.deleteClient('192.168.1.100');

      expect(result.isSuccess(), true);
      expect(service.lastSid, 'sid123');
      expect(service.lastDeleteClient, '192.168.1.100');
    });

    test('should fail when generated delete client request fails', () async {
      service.shouldFailDelete = true;

      final result = await repository.deleteClient('192.168.1.100');
      expectError(result, messageContains: 'Forced deleteClient failure');
    });
  });
}
