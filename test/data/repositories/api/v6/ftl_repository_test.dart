import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/repositories/api/v6/ftl_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache.dart';
import 'package:pi_hole_client/data/services/api/utils/api_exception.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart' hide Success;
import 'package:result_dart/result_dart.dart';

import '../../../../../testing/fakes/services/fake_pihole_v6_api_client.dart';
import '../../../../../testing/fakes/services/fake_session_credential_service.dart';
import '../../../../../testing/helper/test_helper.dart';
import '../../../../../testing/models/v6/ftl.dart';

class _FakePiholeV6Service extends PiholeV6Service {
  _FakePiholeV6Service()
    : super(api: PiholeV6Api(basePathOverride: 'http://localhost/api'));

  bool shouldFail = false;
  bool shouldFailHost = false;
  bool shouldFailMessages = false;
  bool shouldFailDeleteMessage = false;
  bool shouldFailMetrics = false;
  bool shouldFailSensors = false;
  bool shouldFailSystem = false;
  bool shouldGetInfoSystemOld = false;
  bool shouldGetInfoVersionWithDocker = false;
  bool shouldReturnUnauthorizedOnce = false;
  int getInfoVersionCallCount = 0;
  String? lastSid;

  @override
  void setSid(String sid) {
    lastSid = sid;
  }

  @override
  Future<Result<GetVersion200Response>> getInfoVersion() async {
    getInfoVersionCallCount++;
    if (shouldReturnUnauthorizedOnce && getInfoVersionCallCount == 1) {
      return Failure(ApiException(message: 'Unauthorized', statusCode: 401));
    }
    if (shouldFail) {
      return Failure(Exception('Forced getInfoVersion failure'));
    }
    final fixture = shouldGetInfoVersionWithDocker
        ? kSrvGetInfoVersionWithDocker
        : kSrvGetInfoVersion;
    return Success(GetVersion200Response.fromJson(fixture.toJson()));
  }

  @override
  Future<Result<GetHostinfo200Response>> getInfoHost() async {
    if (shouldFailHost) {
      return Failure(Exception('Forced getInfoHost failure'));
    }
    return Success(GetHostinfo200Response.fromJson(kSrvGetInfoHost.toJson()));
  }

  @override
  Future<Result<GetMessages200Response>> getInfoMessages() async {
    if (shouldFailMessages) {
      return Failure(Exception('Forced getInfoMessages failure'));
    }
    return Success(
      GetMessages200Response.fromJson(kSrvGetInfoMessages.toJson()),
    );
  }

  @override
  Future<Result<Unit>> deleteInfoMessage({required int messageId}) async {
    if (shouldFailDeleteMessage) {
      return Failure(Exception('Forced deleteInfoMessage failure'));
    }
    return Success(unit);
  }

  @override
  Future<Result<GetMetricsinfo200Response>> getInfoMetrics() async {
    if (shouldFailMetrics) {
      return Failure(Exception('Forced getInfoMetrics failure'));
    }
    return Success(
      GetMetricsinfo200Response.fromJson(kSrvGetInfoMetrics.toJson()),
    );
  }

  @override
  Future<Result<GetSensors200Response>> getInfoSensors() async {
    if (shouldFailSensors) {
      return Failure(Exception('Forced getInfoSensors failure'));
    }
    return Success(GetSensors200Response.fromJson(kSrvGetInfoSensors.toJson()));
  }

  @override
  Future<Result<GetSysteminfo200Response>> getInfoSystem() async {
    if (shouldFailSystem) {
      return Failure(Exception('Forced getInfoSystem failure'));
    }
    final fixture = shouldGetInfoSystemOld
        ? kSrvGetInfoSystemOld
        : kSrvGetInfoSystem;
    return Success(GetSysteminfo200Response.fromJson(fixture.toJson()));
  }
}

void main() {
  late FtlRepositoryV6 repository;
  late FakePiholeV6ApiClient client;
  late FakeSessionCredentialService creds;
  late _FakePiholeV6Service service;

  group('fetchInfoClient', () {
    setUp(() {
      client = FakePiholeV6ApiClient();
      creds = FakeSessionCredentialService();
      service = _FakePiholeV6Service();
      repository = FtlRepositoryV6(
        client: client,
        service: service,
        sessionCache: V6SessionCache(creds: creds, client: client),
      );
    });

    test('should fetch info client successfully', () async {
      final result = await repository.fetchInfoClient();
      expect(result.getOrNull(), kRepoFetchFtlClient);
    });

    test('should fail when fetching info client fails', () async {
      client.shouldFail = true;

      final result = await repository.fetchInfoClient();
      expectError(result, messageContains: 'Forced getInfoClient failure');
    });
  });

  group('fetchInfoFtl', () {
    setUp(() {
      client = FakePiholeV6ApiClient();
      creds = FakeSessionCredentialService();
      service = _FakePiholeV6Service();
      repository = FtlRepositoryV6(
        client: client,
        service: service,
        sessionCache: V6SessionCache(creds: creds, client: client),
      );
    });

    test('should fetch info ftl successfully', () async {
      final result = await repository.fetchInfoFtl();
      expect(result.getOrNull(), kRepoFetchFtlInfo);
    });

    test('should fetch info ftl successfully (FTL >= 6.3)', () async {
      client.shouldGetInfoFtlV63 = true;
      final result = await repository.fetchInfoFtl();
      expect(result.getOrNull(), kRepoFetchFtlInfo);
    });

    test('should fail when fetching info ftl fails', () async {
      client.shouldFail = true;

      final result = await repository.fetchInfoFtl();
      expectError(result, messageContains: 'Forced getInfoFtl failure');
    });
  });

  group('fetchInfoHost', () {
    setUp(() {
      client = FakePiholeV6ApiClient();
      creds = FakeSessionCredentialService();
      service = _FakePiholeV6Service();
      repository = FtlRepositoryV6(
        client: client,
        service: service,
        sessionCache: V6SessionCache(creds: creds, client: client),
      );
    });

    test(
      'should fetch info host successfully through generated service',
      () async {
        final result = await repository.fetchInfoHost();
        expect(result.getOrNull(), kRepoFetchFtlHost);
        expect(service.lastSid, 'sid123');
      },
    );

    test('should fail when generated host request fails', () async {
      service.shouldFailHost = true;

      final result = await repository.fetchInfoHost();
      expectError(result, messageContains: 'Forced getInfoHost failure');
    });
  });

  group('fetchInfoMessages', () {
    setUp(() {
      client = FakePiholeV6ApiClient();
      creds = FakeSessionCredentialService();
      service = _FakePiholeV6Service();
      repository = FtlRepositoryV6(
        client: client,
        service: service,
        sessionCache: V6SessionCache(creds: creds, client: client),
      );
    });

    test(
      'should fetch gravity messages successfully through generated service',
      () async {
        final result = await repository.fetchInfoMessages();
        expect(result.getOrNull(), kRepoFetchFtlMessages);
        expect(service.lastSid, 'sid123');
      },
    );

    test('should fail when generated messages request fails', () async {
      service.shouldFailMessages = true;

      final result = await repository.fetchInfoMessages();
      expectError(result, messageContains: 'Forced getInfoMessages failure');
    });
  });

  group('deleteInfoMessage', () {
    setUp(() {
      client = FakePiholeV6ApiClient();
      creds = FakeSessionCredentialService();
      service = _FakePiholeV6Service();
      repository = FtlRepositoryV6(
        client: client,
        service: service,
        sessionCache: V6SessionCache(creds: creds, client: client),
      );
    });

    test(
      'should delete info message successfully through generated service',
      () async {
        final result = await repository.deleteInfoMessage(1);
        expectSuccess(result);
        expect(service.lastSid, 'sid123');
      },
    );

    test('should fail when generated message deletion fails', () async {
      service.shouldFailDeleteMessage = true;

      final result = await repository.deleteInfoMessage(1);
      expectError(result, messageContains: 'Forced deleteInfoMessage failure');
    });
  });

  group('fetchInfoMetrics', () {
    setUp(() {
      client = FakePiholeV6ApiClient();
      creds = FakeSessionCredentialService();
      service = _FakePiholeV6Service();
      repository = FtlRepositoryV6(
        client: client,
        service: service,
        sessionCache: V6SessionCache(creds: creds, client: client),
      );
    });

    test(
      'should fetch info metrics successfully through generated service',
      () async {
        final result = await repository.fetchInfoMetrics();
        expect(result.getOrNull(), kRepoFetchFtlMetrics);
        expect(service.lastSid, 'sid123');
      },
    );

    test('should fail when generated metrics request fails', () async {
      service.shouldFailMetrics = true;

      final result = await repository.fetchInfoMetrics();
      expectError(result, messageContains: 'Forced getInfoMetrics failure');
    });
  });

  group('fetchInfoSensors', () {
    setUp(() {
      client = FakePiholeV6ApiClient();
      creds = FakeSessionCredentialService();
      service = _FakePiholeV6Service();
      repository = FtlRepositoryV6(
        client: client,
        service: service,
        sessionCache: V6SessionCache(creds: creds, client: client),
      );
    });

    test(
      'should fetch all sensors successfully through generated service',
      () async {
        final result = await repository.fetchInfoSensors();
        expect(result.getOrNull(), kRepoFetchFtlSensors);
        expect(service.lastSid, 'sid123');
      },
    );

    test('should fail when generated sensor request fails', () async {
      service.shouldFailSensors = true;

      final result = await repository.fetchInfoSensors();
      expectError(result, messageContains: 'Forced getInfoSensors failure');
    });
  });

  group('fetchInfoSystem', () {
    setUp(() {
      client = FakePiholeV6ApiClient();
      creds = FakeSessionCredentialService();
      service = _FakePiholeV6Service();
      repository = FtlRepositoryV6(
        client: client,
        service: service,
        sessionCache: V6SessionCache(creds: creds, client: client),
      );
    });

    test(
      'should fetch info system successfully through generated service',
      () async {
        final result = await repository.fetchInfoSystem();
        expect(result.getOrNull(), kRepoFetchFtlSystem);
        expect(service.lastSid, 'sid123');
      },
    );

    test('should fetch info system successfully (FTL < 6.1)', () async {
      service.shouldGetInfoSystemOld = true;
      final result = await repository.fetchInfoSystem();
      expect(result.getOrNull(), kRepoFetchFtlSystemOld);
    });

    test('should fail when generated system request fails', () async {
      service.shouldFailSystem = true;

      final result = await repository.fetchInfoSystem();
      expectError(result, messageContains: 'Forced getInfoSystem failure');
    });
  });

  group('fetchInfoVersion', () {
    setUp(() {
      client = FakePiholeV6ApiClient();
      creds = FakeSessionCredentialService();
      service = _FakePiholeV6Service();
      repository = FtlRepositoryV6(
        client: client,
        service: service,
        sessionCache: V6SessionCache(creds: creds, client: client),
      );
    });

    test(
      'should fetch info version successfully through generated service',
      () async {
        final result = await repository.fetchInfoVersion();
        expect(result.getOrNull(), kRepoFetchFtlVersion);
        expect(service.lastSid, 'sid123');
      },
    );

    test('should fetch info version successfully (with Docker)', () async {
      service.shouldGetInfoVersionWithDocker = true;
      final result = await repository.fetchInfoVersion();
      expect(result.getOrNull(), kRepoFetchFtlVersionWithDocker);
    });

    test('renews SID and retries generated service after 401', () async {
      service.shouldReturnUnauthorizedOnce = true;

      final result = await repository.fetchInfoVersion();

      expect(result.getOrNull(), kRepoFetchFtlVersion);
      expect(client.postAuthCallCount, 1);
      expect(service.getInfoVersionCallCount, 2);
      expect(service.lastSid, 'n9n9f6c3umrumfq2ese1lvu2pg');
    });

    test('should fail when fetching info version fails', () async {
      service.shouldFail = true;

      final result = await repository.fetchInfoVersion();
      expectError(result, messageContains: 'Forced getInfoVersion failure');
    });
  });

  group('fetchAllServerInfo', () {
    setUp(() {
      client = FakePiholeV6ApiClient();
      creds = FakeSessionCredentialService();
      service = _FakePiholeV6Service();
      repository = FtlRepositoryV6(
        client: client,
        service: service,
        sessionCache: V6SessionCache(creds: creds, client: client),
      );
    });

    test('should fetch all server info successfully', () async {
      final result = await repository.fetchAllServerInfo();
      expect(result.getOrNull(), kRepoFetchAllServerInfo);
    });

    test('should fail when fetching all server info fails', () async {
      service.shouldFailHost = true;
      final result = await repository.fetchAllServerInfo();
      expectError(result, messageContains: 'Forced getInfoHost failure');
    });
  });
}
