import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/repositories/api/v6/client_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache.dart';
import 'package:pi_hole_client/data/services/api/utils/api_exception.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart' hide Success;
import 'package:result_dart/result_dart.dart';

import '../../../../../testing/fakes/services/fake_pihole_v6_api_client.dart';
import '../../../../../testing/fakes/services/fake_session_credential_service.dart';
import '../../../../../testing/models/v6/client.dart';

class _RetryClientService extends PiholeV6Service {
  _RetryClientService()
    : super(api: PiholeV6Api(basePathOverride: 'http://localhost/api'));

  int fetchCallCount = 0;
  int addCallCount = 0;
  int replaceCallCount = 0;
  int deleteCallCount = 0;
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
    fetchCallCount++;
    if (fetchCallCount == 1) {
      return Failure(ApiException(message: 'Unauthorized', statusCode: 401));
    }
    return Success(GetClients200Response.fromJson(kSrvGetClients.toJson()));
  }

  @override
  Future<Result<ReplaceClient200Response>> addClient({
    AddClientRequest? body,
  }) async {
    addCallCount++;
    lastAddBody = body;
    if (addCallCount == 1) {
      return Failure(ApiException(message: 'Unauthorized', statusCode: 401));
    }
    return Success(ReplaceClient200Response.fromJson(kSrvPostClients.toJson()));
  }

  @override
  Future<Result<ReplaceClient200Response>> replaceClient({
    required String client,
    ReplaceClientRequest? body,
  }) async {
    replaceCallCount++;
    lastReplaceClient = client;
    lastReplaceBody = body;
    if (replaceCallCount == 1) {
      return Failure(ApiException(message: 'Unauthorized', statusCode: 401));
    }
    return Success(ReplaceClient200Response.fromJson(kSrvPutClients.toJson()));
  }

  @override
  Future<Result<Unit>> deleteClient({required String client}) async {
    deleteCallCount++;
    lastDeleteClient = client;
    if (deleteCallCount == 1) {
      return Failure(ApiException(message: 'Unauthorized', statusCode: 401));
    }
    return Success(unit);
  }
}

ClientRepositoryV6 _repository({
  required FakePiholeV6ApiClient client,
  required FakeSessionCredentialService creds,
  required _RetryClientService service,
}) {
  return ClientRepositoryV6(
    service: service,
    sessionCache: V6SessionCache(creds: creds, client: client),
  );
}

void main() {
  test('renews SID and retries generated client read after 401', () async {
    final client = FakePiholeV6ApiClient();
    final creds = FakeSessionCredentialService();
    final service = _RetryClientService();
    final repository = _repository(client: client, creds: creds, service: service);

    final result = await repository.fetchClients();

    expect(result.getOrNull(), kRepoFetchClients);
    expect(client.postAuthCallCount, 1);
    expect(service.fetchCallCount, 2);
    expect(service.lastSid, isNot('sid123'));
  });

  test('renews SID and retries generated client add after 401', () async {
    final client = FakePiholeV6ApiClient();
    final creds = FakeSessionCredentialService();
    final service = _RetryClientService();
    final repository = _repository(client: client, creds: creds, service: service);

    final result = await repository.addClient(
      '10.0.0.1',
      comment: 'new client',
      groups: [0, 5],
    );

    expect(result.isSuccess(), true);
    expect(client.postAuthCallCount, 1);
    expect(service.addCallCount, 2);
    expect(service.lastAddBody?.client?.value, '10.0.0.1');
    expect(service.lastAddBody?.comment, 'new client');
    expect(service.lastAddBody?.groups, [0, 5]);
    expect(service.lastSid, isNot('sid123'));
  });

  test('renews SID and retries generated client update after 401', () async {
    final client = FakePiholeV6ApiClient();
    final creds = FakeSessionCredentialService();
    final service = _RetryClientService();
    final repository = _repository(client: client, creds: creds, service: service);

    final result = await repository.updateClient(
      '192.168.1.100',
      comment: 'updated',
      groups: [0, 5],
    );

    expect(result.isSuccess(), true);
    expect(client.postAuthCallCount, 1);
    expect(service.replaceCallCount, 2);
    expect(service.lastReplaceClient, '192.168.1.100');
    expect(service.lastReplaceBody?.comment, 'updated');
    expect(service.lastReplaceBody?.groups, [0, 5]);
    expect(service.lastSid, isNot('sid123'));
  });

  test('renews SID and retries generated client delete after 401', () async {
    final client = FakePiholeV6ApiClient();
    final creds = FakeSessionCredentialService();
    final service = _RetryClientService();
    final repository = _repository(client: client, creds: creds, service: service);

    final result = await repository.deleteClient('192.168.1.100');

    expect(result.isSuccess(), true);
    expect(client.postAuthCallCount, 1);
    expect(service.deleteCallCount, 2);
    expect(service.lastDeleteClient, '192.168.1.100');
    expect(service.lastSid, isNot('sid123'));
  });
}
