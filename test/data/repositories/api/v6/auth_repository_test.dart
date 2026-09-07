import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/repositories/api/v6/auth_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pi_hole_client/utils/exceptions.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart' hide Success;
import 'package:result_dart/result_dart.dart';

import '../../../../../testing/fakes/services/fake_pihole_v6_api_client.dart';
import '../../../../../testing/fakes/services/fake_session_credential_service.dart';
import '../../../../../testing/helper/test_helper.dart';
import '../../../../../testing/models/v6/auth.dart';

class _FakePiholeV6Service extends PiholeV6Service {
  _FakePiholeV6Service()
    : super(api: PiholeV6Api(basePathOverride: 'http://localhost/api'));

  bool shouldFailGetAuth = false;
  bool shouldFailDeleteAuth = false;
  bool shouldFailGetSessions = false;
  bool shouldFailDeleteSession = false;
  String? lastSid;
  int? lastDeletedSessionId;

  @override
  void setSid(String sid) {
    lastSid = sid;
  }

  @override
  Future<Result<GetAuth200Response>> getAuth() async {
    if (shouldFailGetAuth) {
      return Failure(Exception('Forced generated getAuth failure'));
    }
    return Success(
      GetAuth200Response(
        session: SessionSession(
          valid: true,
          totp: false,
          sid: 'sid123',
          csrf: 'csrf-token',
          validity: 300,
          message: 'correct password',
        ),
      ),
    );
  }

  @override
  Future<Result<Unit>> deleteAuth() async {
    if (shouldFailDeleteAuth) {
      return Failure(Exception('Forced generated deleteAuth failure'));
    }
    return Success(unit);
  }

  @override
  Future<Result<GetAuthSessions200Response>> getAuthSessions() async {
    if (shouldFailGetSessions) {
      return Failure(Exception('Forced generated getAuthSessions failure'));
    }
    return Success(
      GetAuthSessions200Response.fromJson(kSrvGetAuthSessions.toJson()),
    );
  }

  @override
  Future<Result<Unit>> deleteAuthSession({required int id}) async {
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
  late _FakePiholeV6Service service;

  setUp(() {
    client = FakePiholeV6ApiClient();
    creds = FakeSessionCredentialService();
    service = _FakePiholeV6Service();
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
    test('reports the server 2FA status (disabled)', () async {
      final result = await repository.getAuth(useSid: false);

      expect(result.getOrNull()?.totp, isFalse);
      expect(client.getAuthCallCount, 1);
    });

    test('reports when the server has 2FA enabled', () async {
      client.serverTotpEnabled = true;

      final result = await repository.getAuth(useSid: false);

      expect(result.getOrNull()?.totp, isTrue);
    });

    test('returns error when the API fails', () async {
      client.shouldFail = true;

      final result = await repository.getAuth(useSid: false);

      expectError(result, messageContains: 'Forced getAuth failure');
    });

    test('uses generated service for authenticated auth status', () async {
      final result = await repository.getAuth();

      expect(result.isSuccess(), isTrue);
      expect(result.getOrNull()?.sid, 'sid123');
      expect(service.lastSid, 'sid123');
      expect(client.getAuthCallCount, 0);
    });

    test('returns generated error for authenticated auth status', () async {
      service.shouldFailGetAuth = true;

      final result = await repository.getAuth();

      expectError(result, messageContains: 'Forced generated getAuth failure');
    });
  });

  group('deleteCurrentSession', () {
    test('deletes the current session through generated service', () async {
      final result = await repository.deleteCurrentSession();

      expectSuccess(result);
      expect(service.lastSid, 'sid123');
    });

    test('returns error when generated API fails', () async {
      service.shouldFailDeleteAuth = true;

      final result = await repository.deleteCurrentSession();
      expectError(
        result,
        messageContains: 'Forced generated deleteAuth failure',
      );
    });
  });

  group('getAllSessions', () {
    test('should return all sessions through generated service', () async {
      final result = await repository.getAllSessions();

      expect(result.getOrNull(), kRepoGetAllSessions);
      expect(service.lastSid, 'sid123');
    });

    test('returns error when generated API fails', () async {
      service.shouldFailGetSessions = true;

      final result = await repository.getAllSessions();
      expectError(
        result,
        messageContains: 'Forced generated getAuthSessions failure',
      );
    });
  });

  group('deleteSessionById', () {
    test('should delete a session by ID through generated service', () async {
      final result = await repository.deleteSessionById(1);

      expectSuccess(result);
      expect(service.lastSid, 'sid123');
      expect(service.lastDeletedSessionId, 1);
    });

    test('returns error when generated API fails', () async {
      service.shouldFailDeleteSession = true;

      final result = await repository.deleteSessionById(1);
      expectError(
        result,
        messageContains: 'Forced generated deleteAuthSession failure',
      );
    });
  });
}
