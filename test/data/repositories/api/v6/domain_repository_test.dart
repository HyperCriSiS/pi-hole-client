import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/repositories/api/v6/domain_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pi_hole_client/domain/model/enums.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart' hide Success;
import 'package:result_dart/result_dart.dart';

import '../../../../../testing/fakes/services/fake_pihole_v6_api_client.dart';
import '../../../../../testing/fakes/services/fake_session_credential_service.dart';
import '../../../../../testing/helper/test_helper.dart';
import '../../../../../testing/models/v6/domain.dart';

class _FakePiholeV6Service extends PiholeV6Service {
  _FakePiholeV6Service()
    : super(api: PiholeV6Api(basePathOverride: 'http://localhost/api'));

  bool shouldFailFetch = false;
  bool shouldFailAdd = false;
  bool shouldFailReplace = false;
  bool shouldFailDelete = false;
  String? lastSid;
  String? lastAddType;
  String? lastAddKind;
  Post? lastAddBody;
  String? lastReplaceType;
  String? lastReplaceKind;
  String? lastReplaceDomain;
  ReplaceDomainRequest? lastReplaceBody;
  String? lastDeleteType;
  String? lastDeleteKind;
  String? lastDeleteDomain;

  @override
  void setSid(String sid) {
    lastSid = sid;
  }

  @override
  Future<Result<GetDomain200Response>> getAllDomains() async {
    if (shouldFailFetch) {
      return Failure(Exception('Forced getAllDomains failure'));
    }
    return Success(GetDomain200Response.fromJson(kSrvGetDomains.toJson()));
  }

  @override
  Future<Result<ReplaceDomain200Response>> addDomain({
    required String type,
    required String kind,
    Post? body,
  }) async {
    lastAddType = type;
    lastAddKind = kind;
    lastAddBody = body;
    if (shouldFailAdd) {
      return Failure(Exception('Forced addDomain failure'));
    }
    return Success(ReplaceDomain200Response.fromJson(kSrvPostDomains.toJson()));
  }

  @override
  Future<Result<ReplaceDomain200Response>> replaceDomain({
    required String type,
    required String kind,
    required String domain,
    ReplaceDomainRequest? body,
  }) async {
    lastReplaceType = type;
    lastReplaceKind = kind;
    lastReplaceDomain = domain;
    lastReplaceBody = body;
    if (shouldFailReplace) {
      return Failure(Exception('Forced replaceDomain failure'));
    }
    return Success(ReplaceDomain200Response.fromJson(kSrvPutDomains.toJson()));
  }

  @override
  Future<Result<Unit>> deleteDomain({
    required String type,
    required String kind,
    required String domain,
  }) async {
    lastDeleteType = type;
    lastDeleteKind = kind;
    lastDeleteDomain = domain;
    if (shouldFailDelete) {
      return Failure(Exception('Forced deleteDomain failure'));
    }
    return Success(unit);
  }
}

void main() {
  late DomainRepositoryV6 repository;
  late FakePiholeV6ApiClient client;
  late FakeSessionCredentialService creds;
  late _FakePiholeV6Service service;

  setUp(() {
    client = FakePiholeV6ApiClient();
    creds = FakeSessionCredentialService();
    service = _FakePiholeV6Service();
    repository = DomainRepositoryV6(
      service: service,
      sessionCache: V6SessionCache(creds: creds, client: client),
    );
  });

  group('fetchAllDomains', () {
    test('should fetch all domains through generated service', () async {
      final result = await repository.fetchAllDomains();

      expect(result.getOrNull(), kRepoFetchAllDomains);
      expect(service.lastSid, 'sid123');
    });

    test('should fail when generated domain read fails', () async {
      service.shouldFailFetch = true;

      final result = await repository.fetchAllDomains();
      expectError(result, messageContains: 'Forced getAllDomains failure');
    });
  });

  group('addDomain', () {
    test('should add domain through generated service', () async {
      final result = await repository.addDomain(
        DomainType.deny,
        DomainKind.exact,
        'example.com',
        comment: 'new comment',
        groups: [2],
        enabled: false,
      );

      expect(result.getOrNull(), kRepoAddDomain);
      expect(service.lastSid, 'sid123');
      expect(service.lastAddType, 'deny');
      expect(service.lastAddKind, 'exact');
      expect(service.lastAddBody?.domain?.value, 'example.com');
      expect(service.lastAddBody?.comment, 'new comment');
      expect(service.lastAddBody?.groups, [2]);
      expect(service.lastAddBody?.enabled, false);
    });

    test('should fail when generated add domain request fails', () async {
      service.shouldFailAdd = true;

      final result = await repository.addDomain(
        DomainType.deny,
        DomainKind.exact,
        'example.com',
      );
      expectError(result, messageContains: 'Forced addDomain failure');
    });
  });

  group('updateDomain', () {
    test('should update domain through generated service', () async {
      final result = await repository.updateDomain(
        DomainType.deny,
        DomainKind.regex,
        'example.com',
        comment: 'test',
        groups: [1],
        enabled: false,
      );

      expect(result.getOrNull(), kRepoUpdateDomain);
      expect(service.lastSid, 'sid123');
      expect(service.lastReplaceType, 'deny');
      expect(service.lastReplaceKind, 'regex');
      expect(service.lastReplaceDomain, 'example.com');
      expect(service.lastReplaceBody?.type?.value, 'deny');
      expect(service.lastReplaceBody?.kind?.value, 'regex');
      expect(service.lastReplaceBody?.comment, 'test');
      expect(service.lastReplaceBody?.groups, [1]);
      expect(service.lastReplaceBody?.enabled, false);
    });

    test('should fail when generated replace domain request fails', () async {
      service.shouldFailReplace = true;

      final result = await repository.updateDomain(
        DomainType.deny,
        DomainKind.exact,
        'example.com',
        comment: 'test',
        groups: [1],
        enabled: false,
      );
      expectError(result, messageContains: 'Forced replaceDomain failure');
    });
  });

  group('deleteDomain', () {
    test('should delete domain through generated service', () async {
      final result = await repository.deleteDomain(
        DomainType.deny,
        DomainKind.regex,
        'example.com',
      );

      expectSuccess(result);
      expect(service.lastSid, 'sid123');
      expect(service.lastDeleteType, 'deny');
      expect(service.lastDeleteKind, 'regex');
      expect(service.lastDeleteDomain, 'example.com');
    });

    test('should fail when generated delete domain request fails', () async {
      service.shouldFailDelete = true;

      final result = await repository.deleteDomain(
        DomainType.deny,
        DomainKind.exact,
        'example.com',
      );
      expectError(result, messageContains: 'Forced deleteDomain failure');
    });
  });
}
