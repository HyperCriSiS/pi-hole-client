import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/repositories/api/v6/group_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache.dart';
import 'package:pi_hole_client/data/services/api/utils/api_exception.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pi_hole_client/utils/exceptions.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart' hide Success;
import 'package:result_dart/result_dart.dart';

import '../../../../../testing/fakes/services/fake_pihole_v6_api_client.dart';
import '../../../../../testing/fakes/services/fake_session_credential_service.dart';

class _GroupErrorService extends PiholeV6Service {
  _GroupErrorService()
    : super(api: PiholeV6Api(basePathOverride: 'http://localhost/api'));

  Result<ReplaceGroup200Response>? addResult;
  Result<ReplaceGroup200Response>? replaceResult;
  Result<Unit>? deleteResult;
  int addCallCount = 0;
  int replaceCallCount = 0;
  int deleteCallCount = 0;

  @override
  void setSid(String sid) {}

  @override
  Future<Result<ReplaceGroup200Response>> addGroup({Post2? body}) async {
    addCallCount++;
    return addResult ?? Failure(Exception('Missing add result'));
  }

  @override
  Future<Result<ReplaceGroup200Response>> replaceGroup({
    required String name,
    Put2? body,
  }) async {
    replaceCallCount++;
    return replaceResult ?? Failure(Exception('Missing replace result'));
  }

  @override
  Future<Result<Unit>> deleteGroup({required String name}) async {
    deleteCallCount++;
    return deleteResult ?? Failure(Exception('Missing delete result'));
  }
}

V6SessionCache _sessionCache() {
  return V6SessionCache(
    creds: FakeSessionCredentialService(),
    client: FakePiholeV6ApiClient(),
  );
}

ApiException _generatedError({
  required int statusCode,
  required String message,
  String? hint,
}) {
  return ApiException.fromDioException(
    DioException(
      requestOptions: RequestOptions(),
      response: Response(
        statusCode: statusCode,
        data: {
          'error': {
            'key': 'database_error',
            'message': message,
            if (hint != null) 'hint': hint,
          },
        },
        requestOptions: RequestOptions(),
      ),
      type: DioExceptionType.badResponse,
    ),
  );
}

void main() {
  late _GroupErrorService service;
  late GroupRepositoryV6 repository;

  setUp(() {
    service = _GroupErrorService();
    repository = GroupRepositoryV6(
      service: service,
      sessionCache: _sessionCache(),
    );
  });

  test('maps a generated v6.7 duplicate and does not retry it', () async {
    service.addResult = Failure(
      _generatedError(
        statusCode: 400,
        message: 'Could not add to gravity database',
        hint: 'The item is already present',
      ),
    );

    final result = await repository.addGroup('test');

    expect(result.exceptionOrNull(), isA<AlreadyExistsException>());
    expect(service.addCallCount, 1);
  });

  test('maps an older processed-error duplicate on update', () async {
    service.replaceResult = Success(
      ReplaceGroup200Response.fromJson({
        'processed': {
          'errors': [
            {
              'item': 'test',
              'error': 'UNIQUE constraint failed: group.name',
            },
          ],
        },
      }),
    );

    final result = await repository.updateGroup('test');

    expect(result.exceptionOrNull(), isA<AlreadyExistsException>());
    expect(service.replaceCallCount, 1);
  });

  test('maps generated old-database foreign-key delete failure once', () async {
    service.deleteResult = Failure(
      _generatedError(
        statusCode: 400,
        message: 'Could not delete group from database',
        hint: 'FOREIGN KEY constraint failed',
      ),
    );

    final result = await repository.deleteGroup('test');

    expect(result.exceptionOrNull(), isA<GroupInUseException>());
    expect(service.deleteCallCount, 1);
  });
}
