import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/repositories/api/v6/adlist_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/client_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pi_hole_client/domain/model/enums.dart';
import 'package:pi_hole_client/utils/exceptions.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart' hide Success;
import 'package:result_dart/result_dart.dart';

import '../../../../../testing/fakes/services/fake_pihole_v6_api_client.dart';
import '../../../../../testing/fakes/services/fake_session_credential_service.dart';

class _ClientDuplicateService extends PiholeV6Service {
  _ClientDuplicateService()
    : super(api: PiholeV6Api(basePathOverride: 'http://localhost/api'));

  Result<ReplaceClient200Response>? addResult;
  Result<ReplaceClient200Response>? replaceResult;
  int addCallCount = 0;
  int replaceCallCount = 0;

  @override
  void setSid(String sid) {}

  @override
  Future<Result<ReplaceClient200Response>> addClient({
    AddClientRequest? body,
  }) async {
    addCallCount++;
    return addResult ?? Failure(Exception('Missing add result'));
  }

  @override
  Future<Result<ReplaceClient200Response>> replaceClient({
    required String client,
    ReplaceClientRequest? body,
  }) async {
    replaceCallCount++;
    return replaceResult ?? Failure(Exception('Missing replace result'));
  }
}

class _AdlistDuplicateService extends PiholeV6Service {
  _AdlistDuplicateService()
    : super(api: PiholeV6Api(basePathOverride: 'http://localhost/api'));

  Result<ReplaceLists200Response>? addResult;
  Result<ReplaceLists200Response>? replaceResult;
  int addCallCount = 0;
  int replaceCallCount = 0;

  @override
  void setSid(String sid) {}

  @override
  Future<Result<ReplaceLists200Response>> addList({
    required String type,
    Post4? body,
  }) async {
    addCallCount++;
    return addResult ?? Failure(Exception('Missing add result'));
  }

  @override
  Future<Result<ReplaceLists200Response>> replaceList({
    required String list,
    required String type,
    Put4? body,
  }) async {
    replaceCallCount++;
    return replaceResult ?? Failure(Exception('Missing replace result'));
  }
}

V6SessionCache _sessionCache() {
  return V6SessionCache(
    creds: FakeSessionCredentialService(),
    client: FakePiholeV6ApiClient(),
  );
}

void main() {
  group('ClientRepositoryV6 duplicate handling', () {
    late _ClientDuplicateService service;
    late ClientRepositoryV6 repository;

    setUp(() {
      service = _ClientDuplicateService();
      repository = ClientRepositoryV6(
        service: service,
        sessionCache: _sessionCache(),
      );
    });

    test('maps a v6.7 add duplicate and does not retry it', () async {
      service.addResult = Failure(
        HttpStatusCodeException(400, 'The item is already present'),
      );

      final result = await repository.addClient('192.168.1.10');

      expect(result.exceptionOrNull(), isA<AlreadyExistsException>());
      expect(service.addCallCount, 1);
    });

    test('maps an older processed-error duplicate on update', () async {
      service.replaceResult = Success(
        ReplaceClient200Response.fromJson({
          'processed': {
            'errors': [
              {
                'item': '192.168.1.10',
                'error': 'UNIQUE constraint failed: client.ip',
              },
            ],
          },
        }),
      );

      final result = await repository.updateClient('192.168.1.10');

      expect(result.exceptionOrNull(), isA<AlreadyExistsException>());
      expect(service.replaceCallCount, 1);
    });
  });

  group('AdlistRepositoryV6 duplicate handling', () {
    late _AdlistDuplicateService service;
    late AdlistRepositoryV6 repository;

    setUp(() {
      service = _AdlistDuplicateService();
      repository = AdlistRepositoryV6(
        service: service,
        sessionCache: _sessionCache(),
      );
    });

    test('maps a v6.7 add duplicate and does not retry it', () async {
      service.addResult = Failure(
        HttpStatusCodeException(400, 'The item is already present'),
      );

      final result = await repository.addAdlist(
        'https://example.com/hosts',
        ListType.block,
      );

      expect(result.exceptionOrNull(), isA<AlreadyExistsException>());
      expect(service.addCallCount, 1);
    });

    test('maps an older processed-error duplicate on update', () async {
      service.replaceResult = Success(
        ReplaceLists200Response.fromJson({
          'processed': {
            'errors': [
              {
                'item': 'https://example.com/hosts',
                'error': 'UNIQUE constraint failed: adlist.address, adlist.type',
              },
            ],
          },
        }),
      );

      final result = await repository.updateAdlist(
        'https://example.com/hosts',
        ListType.block,
      );

      expect(result.exceptionOrNull(), isA<AlreadyExistsException>());
      expect(service.replaceCallCount, 1);
    });
  });
}
