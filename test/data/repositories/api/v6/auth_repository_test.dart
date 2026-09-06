import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/repositories/api/v6/auth_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache.dart';
import 'package:pi_hole_client/data/services/api/utils/api_exception.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pi_hole_client/utils/exceptions.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart' hide Success;
import 'package:result_dart/result_dart.dart';

import '../../../../../testing/fakes/services/fake_pihole_v6_api_client.dart';
import '../../../../../testing/fakes/services/fake_session_credential_service.dart';
import '../../../../../testing/helper/test_helper.dart';
import '../../../../../testing/models/v6/auth.dart';

class _FakeAuthService extends PiholeV6Service {
  _FakeAuthService()
    : super(api: PiholeV6Api(basePathOverride: 'http://localhost/api'));

  bool shouldFailGetAuth = false;
  bool shouldFailDeleteAuth = false;
  bool unauthorizedFirstDeleteAuth = false;
  bool shouldFailGetSessions = false;
  bool shouldFailDeleteSession = false;
  bool unauthorizedFirstGetAuth = false;

  int getAuthCallCount = 0;
  int deleteAuthCallCount = 0;
  int getSessionsCallCount = 0;
  int deleteSessionCallCount = 0;
  int? lastDeletedSessionId;
  String? lastSid;

  @override
  void setSid(String sid) {
    lastSid = sid;
  }

  @override
  Future<Result<GetAuth200Response>> getAuth() async {
    getAuthCallCount++;
    if (unauthorizedFirstGetAuth && getAuthCallCount == 1) {
      return Failure(ApiException(message: 'Unauthorized', statusCode: 401));
    }
    if (shouldFailGetAuth) {
      return Failure(Exception('Forced generated getAuth failure'));
    }
    final json = jsonDecode(jsonEncode(kSrvPostAuth.toJson()));
    return Success(
      GetAuth200Response.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<Unit>> deleteAuth() async {
    deleteAuthCallCount++;
    if (unauthorizedFirstDeleteAuth && deleteAuthCallCount == 1) {
      return Failure(ApiException(message: 'Unauthorized', statusCode: 401));
    }
    if (shouldFailDeleteAuth) {
      return Failure(Exception('Forced generated deleteAuth failure'));
    }
    return Success(unit);
  }

  @override
  Future<Result<GetAuthSessions200Response>> getAuthSessions() async {
    getSessionsCallCount++;
    if (shouldFailGetSessions) {
      return Failure(Exception('Forced generated getAuthSessions failure'));
    }
    final json = jsonDecode(jsonEncode(kSrvGetAuthSessions.toJson()));
    return Success(
      GetAuthSessions200Response.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<Unit>> deleteAuthSession({required int id}) async {
    deleteSessionCallCount++;
    lastDeletedSessionId = id;
    if (shouldFailDeleteSession) {
      return Failure(Exception('Forced generated deleteAuthSession failure'));
    }
    return Success(unit);
  }
}

void main() {
  late AuthRepositoryV6 repository;
  late FakePiholeV6ApiClient client;
  late FakeSessionCredentialService creds;
  late _FakeAuthService service;

  setUp(() {
    client = FakePiholeV6ApiClient();
    creds = FakeSessionCredentialService();
    service = _FakeAuthService();
    repository = AuthRepositoryV6(
      client: client,
      service: service,
      sessionCache: V6SessionCache(creds: creds, client: client),
    );
  });

  group('createSession', () {
    test('should create a session successfully', () async {
      final result = await repository.createSession('password123');
      expect(result.getOrNull(), kRepoCreateSession);
    });

    test('returns error when API fails', () async {
      client.shouldFail = true;

      final result = await repository.createSession('password123');
      expectError(result, messageContains: 'Forced postAuth failure');
    });

    test(
      'succeeds without persisting a sid when no app password is set',
      () async {
        client.shouldReturnNoPasswordSession = true;

        final result = await repository.createSession('');

        expect(result.isSuccess(), isTrue);
        expect(result.getOrNull()!.valid, isTrue);
        expect(result.getOrNull()!.sid, '');
        expect(creds.saveSidCallCount, 0);
      },
    );

    test('forwards the totp code to the API client as an int', () async {
      await repository.createSession('password123', totp: '123456');

      expect(client.lastTotp, 123456);
    });

    test('propagates TotpRequiredException from a 2FA server', () async {
      client.shouldRequireTotp = true;

      final result = await repository.createSession('password123');

      expect(result.isError(), isTrue);
      expect(result.exceptionOrNull(), isA<TotpRequiredException>());
    });

    test('propagates TotpInvalidException from a 2FA server', () async {
      client.shouldRequireTotp = true;
      client.validTotp = 123456;

      final result = await repository.createSession(
        'password123',
        totp: '654321',
      );

      expect(result.isError(), isTrue);
      expect(result.exceptionOrNull(), isA<TotpInvalidException>());
    });
  });

  group('getAuth', () {
    test('reports the server 2FA status unauthenticated', () async {
      final result = await repository.getAuth(useSid: false);

      expect(result.getOrNull()?.totp, isFalse);
      expect(client.getAuthCallCount, 1);
      expect(service.getAuthCallCount, 0);
      expect(service.lastSid, isNull);
    });

    test('reports when the server has 2FA enabled', () async {
      client.serverTotpEnabled = true;

      final result = await repository.getAuth(useSid: false);

      expect(result.getOrNull()?.totp, isTrue);
      expect(service.getAuthCallCount, 0);
    });

    test('returns handwritten error for unauthenticated status read', () async {
      client.shouldFail = true;

      final result = await repository.getAuth(useSid: false);

      expectError(result, messageContains: 'Forced getAuth failure');
      expect(service.getAuthCallCount, 0);
    });

    test('uses generated service for authenticated auth read', () async {
      final result = await repository.getAuth();

      expect(result.getOrNull(), kRepoCreateSession);
      expect(service.getAuthCallCount, 1);
      expect(service.lastSid, 'sid123');
      expect(client.getAuthCallCount, 0);
    });

    test('surfaces generated authenticated auth errors', () async {
      service.shouldFailGetAuth = true;

      final result = await repository.getAuth();

      expectError(result, messageContains: 'Forced generated getAuth failure');
    });

    test('renews SID and retries generated authenticated auth after 401', () async {
      service.unauthorizedFirstGetAuth = true;

      final result = await repository.getAuth();

      expect(result.getOrNull(), kRepoCreateSession);
      expect(service.getAuthCallCount, 2);
      expect(client.postAuthCallCount, 1);
      expect(service.lastSid, isNot('sid123'));
    });
  });

  group('deleteCurrentSession', () {
    test('deletes the current session through generated service', () async {
      final result = await repository.deleteCurrentSession();

      expectSuccess(result);
      expect(service.deleteAuthCallCount, 1);
      expect(service.lastSid, 'sid123');
    });

    test('returns generated error when API fails', () async {
      service.shouldFailDeleteAuth = true;

      final result = await repository.deleteCurrentSession();

      expectError(result, messageContains: 'Forced generated deleteAuth failure');
    });

    test('renews SID and retries generated logout after 401', () async {
      service.unauthorizedFirstDeleteAuth = true;

      final result = await repository.deleteCurrentSession();

      expectSuccess(result);
      expect(service.deleteAuthCallCount, 2);
      expect(client.postAuthCallCount, 1);
      expect(service.lastSid, isNot('sid123'));
    });
  });

  group('getAllSessions', () {
    test('returns all generated sessions through legacy mapper', () async {
      final result = await repository.getAllSessions();

      expect(result.getOrNull(), kRepoGetAllSessions);
      expect(service.getSessionsCallCount, 1);
      expect(service.lastSid, 'sid123');
    });

    test('returns generated error when API fails', () async {
      service.shouldFailGetSessions = true;

      final result = await repository.getAllSessions();

      expectError(
        result,
        messageContains: 'Forced generated getAuthSessions failure',
      );
    });
  });

  group('deleteSessionById', () {
    test('deletes a session by ID through generated service', () async {
      final result = await repository.deleteSessionById(1);

      expectSuccess(result);
      expect(service.deleteSessionCallCount, 1);
      expect(service.lastDeletedSessionId, 1);
      expect(service.lastSid, 'sid123');
    });

    test('returns generated error when API fails', () async {
      service.shouldFailDeleteSession = true;

      final result = await repository.deleteSessionById(1);

      expectError(
        result,
        messageContains: 'Forced generated deleteAuthSession failure',
      );
    });
  });
}
