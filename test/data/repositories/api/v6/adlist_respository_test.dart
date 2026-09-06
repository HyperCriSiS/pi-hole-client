import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/model/v6/lists/search.dart' as legacy_search;
import 'package:pi_hole_client/data/repositories/api/v6/adlist_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pi_hole_client/domain/model/enums.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart' hide Success;
import 'package:result_dart/result_dart.dart';

import '../../../../../testing/fakes/services/fake_pihole_v6_api_client.dart';
import '../../../../../testing/fakes/services/fake_session_credential_service.dart';
import '../../../../../testing/helper/test_helper.dart';
import '../../../../../testing/models/v6/adlist.dart';

legacy_search.Search _searchFixture({
  required String domain,
  bool partial = false,
  int limit = 20,
}) {
  return legacy_search.Search(
    search: legacy_search.SearchData(
      domains: const [],
      gravity: [
        legacy_search.GravityEntry(
          domain: domain,
          address: 'https://blocklist.example.com/hosts',
          enabled: true,
          id: 1,
          type: legacy_search.GravityType.block,
          dateAdded: 1704067200,
          dateModified: 1704067200,
          dateUpdated: 1704067200,
          number: 1000,
          invalidDomains: 0,
          abpEntries: 0,
          status: 2,
          groups: const [0],
        ),
      ],
      parameters: legacy_search.SearchParameters(
        partial: partial,
        N: limit,
        domain: domain,
        debug: false,
      ),
      results: const legacy_search.SearchResults(
        domains: legacy_search.DomainMatchCount(exact: 0, regex: 0),
        gravity: legacy_search.GravityMatchCount(allow: 0, block: 1),
        total: 1,
      ),
    ),
    took: 0.01,
  );
}

Map<String, dynamic> _deepJson(legacy_search.Search fixture) =>
    jsonDecode(jsonEncode(fixture)) as Map<String, dynamic>;

class _FakePiholeV6Service extends PiholeV6Service {
  _FakePiholeV6Service()
    : super(api: PiholeV6Api(basePathOverride: 'http://localhost/api'));

  bool shouldFailFetch = false;
  bool shouldFailAdd = false;
  bool shouldFailReplace = false;
  bool shouldFailDelete = false;
  bool shouldFailSearch = false;
  String? lastSid;
  String? lastFetchList;
  String? lastFetchType;
  String? lastAddType;
  ListsPost? lastAddBody;
  String? lastReplaceList;
  String? lastReplaceType;
  ListsPut? lastReplaceBody;
  String? lastDeleteList;
  String? lastDeleteType;
  String? lastSearchDomain;
  int? lastSearchN;
  bool? lastSearchPartial;

  @override
  void setSid(String sid) {
    lastSid = sid;
  }

  @override
  Future<Result<GetLists200Response>> getAllLists({String? type}) async {
    lastFetchList = null;
    lastFetchType = type;
    if (shouldFailFetch) {
      return Failure(Exception('Forced getAllLists failure'));
    }
    return Success(GetLists200Response.fromJson(kSrvGetLists.toJson()));
  }

  @override
  Future<Result<GetLists200Response>> getLists({
    required String list,
    String? type,
  }) async {
    lastFetchList = list;
    lastFetchType = type;
    if (shouldFailFetch) {
      return Failure(Exception('Forced getLists failure'));
    }
    return Success(GetLists200Response.fromJson(kSrvGetLists.toJson()));
  }

  @override
  Future<Result<ReplaceLists200Response>> addList({
    required String type,
    ListsPost? body,
  }) async {
    lastAddType = type;
    lastAddBody = body;
    if (shouldFailAdd) {
      return Failure(Exception('Forced addList failure'));
    }
    return Success(ReplaceLists200Response.fromJson(kSrvPostLists.toJson()));
  }

  @override
  Future<Result<ReplaceLists200Response>> replaceList({
    required String list,
    required String type,
    ListsPut? body,
  }) async {
    lastReplaceList = list;
    lastReplaceType = type;
    lastReplaceBody = body;
    if (shouldFailReplace) {
      return Failure(Exception('Forced replaceList failure'));
    }
    return Success(ReplaceLists200Response.fromJson(kSrvPutLists.toJson()));
  }

  @override
  Future<Result<Unit>> deleteList({
    required String list,
    required String type,
  }) async {
    lastDeleteList = list;
    lastDeleteType = type;
    if (shouldFailDelete) {
      return Failure(Exception('Forced deleteList failure'));
    }
    return Success(unit);
  }

  @override
  Future<Result<GetSearch200Response>> searchDomainInLists({
    required String domain,
    int? n,
    bool? partial,
  }) async {
    lastSearchDomain = domain;
    lastSearchN = n;
    lastSearchPartial = partial;
    if (shouldFailSearch) {
      return Failure(Exception('Forced searchDomainInLists failure'));
    }
    return Success(
      GetSearch200Response.fromJson(
        _deepJson(
          _searchFixture(
            domain: domain,
            partial: partial ?? false,
            limit: n ?? 20,
          ),
        ),
      ),
    );
  }
}

void main() {
  late AdlistRepositoryV6 repository;
  late FakePiholeV6ApiClient client;
  late FakeSessionCredentialService creds;
  late _FakePiholeV6Service service;

  setUp(() {
    creds = FakeSessionCredentialService();
    client = FakePiholeV6ApiClient();
    service = _FakePiholeV6Service();
    repository = AdlistRepositoryV6(
      service: service,
      sessionCache: V6SessionCache(creds: creds, client: client),
    );
  });

  group('fetchAdlists', () {
    test('fetches all adlists through generated service', () async {
      final result = await repository.fetchAdlists(type: ListType.block);

      expect(result.getOrNull(), kRepoFetchAdlists);
      expect(service.lastSid, 'sid123');
      expect(service.lastFetchList, isNull);
      expect(service.lastFetchType, 'block');
    });

    test('forwards requested adlist address through generated service', () async {
      const address = 'https://example.com/adlist.txt';
      final result = await repository.fetchAdlists(
        adlist: address,
        type: ListType.allow,
      );

      expect(result.isSuccess(), true);
      expect(service.lastFetchList, address);
      expect(service.lastFetchType, 'allow');
    });

    test('fails when generated adlist read fails', () async {
      service.shouldFailFetch = true;

      final result = await repository.fetchAdlists();
      expectError(result, messageContains: 'Forced getAllLists failure');
    });
  });

  group('addAdlist', () {
    test('adds adlist through generated service', () async {
      const address = 'https://example.com/adlist.txt';
      final result = await repository.addAdlist(
        address,
        ListType.block,
        groups: const [2],
        comment: 'new list',
        enabled: false,
      );

      expect(result.getOrNull(), kRepoAddAdlist);
      expect(service.lastSid, 'sid123');
      expect(service.lastAddType, 'block');
      expect(service.lastAddBody?.address?.value, address);
      expect(service.lastAddBody?.groups, [2]);
      expect(service.lastAddBody?.comment, 'new list');
      expect(service.lastAddBody?.enabled, false);
    });

    test('fails when generated add request fails', () async {
      service.shouldFailAdd = true;

      final result = await repository.addAdlist(
        'https://example.com/adlist.txt',
        ListType.block,
      );
      expectError(result, messageContains: 'Forced addList failure');
    });
  });

  group('updateAdlist', () {
    test('updates adlist through generated service', () async {
      const address = 'https://example.com/adlist.txt';
      final result = await repository.updateAdlist(
        address,
        ListType.allow,
        groups: const [1],
        comment: 'test',
        enabled: false,
      );

      expect(result.getOrNull(), kRepoUpdateAdlist);
      expect(service.lastSid, 'sid123');
      expect(service.lastReplaceList, address);
      expect(service.lastReplaceType, 'allow');
      expect(service.lastReplaceBody?.type?.value, 'allow');
      expect(service.lastReplaceBody?.groups, [1]);
      expect(service.lastReplaceBody?.comment, 'test');
      expect(service.lastReplaceBody?.enabled, false);
    });

    test('keeps unknown type in endpoint and omits unsupported body enum', () async {
      const address = 'https://example.com/adlist.txt';
      final result = await repository.updateAdlist(
        address,
        ListType.unknown,
        groups: const [3],
        comment: 'unknown type',
        enabled: true,
      );

      expect(result.isSuccess(), true);
      expect(service.lastReplaceList, address);
      expect(service.lastReplaceType, 'unknown');
      expect(service.lastReplaceBody?.type, isNull);
      expect(service.lastReplaceBody?.groups, [3]);
      expect(service.lastReplaceBody?.comment, 'unknown type');
      expect(service.lastReplaceBody?.enabled, true);
    });

    test('fails when generated replace request fails', () async {
      service.shouldFailReplace = true;

      final result = await repository.updateAdlist(
        'https://example.com/adlist.txt',
        ListType.block,
      );
      expectError(result, messageContains: 'Forced replaceList failure');
    });
  });

  group('deleteAdlist', () {
    test('deletes adlist through generated service', () async {
      const address = 'https://example.com/adlist.txt';
      final result = await repository.deleteAdlist(address, ListType.block);

      expectSuccess(result);
      expect(service.lastSid, 'sid123');
      expect(service.lastDeleteList, address);
      expect(service.lastDeleteType, 'block');
    });

    test('fails when generated delete request fails', () async {
      service.shouldFailDelete = true;

      final result = await repository.deleteAdlist(
        'https://example.com/adlist.txt',
        ListType.block,
      );
      expectError(result, messageContains: 'Forced deleteList failure');
    });
  });

  group('searchLists', () {
    test('forwards search parameters and maps generated response', () async {
      final result = await repository.searchLists(
        domain: 'example.com',
        partial: true,
        limit: 7,
      );

      final search = result.getOrNull();
      expect(search, isNotNull);
      expect(search!.gravityMatches, hasLength(1));
      expect(search.gravityMatches.first.matchedDomain, 'example.com');
      expect(search.meta.total, 1);
      expect(search.meta.gravityBlock, 1);
      expect(service.lastSid, 'sid123');
      expect(service.lastSearchDomain, 'example.com');
      expect(service.lastSearchPartial, true);
      expect(service.lastSearchN, 7);
    });

    test('preserves null optional search parameters', () async {
      final result = await repository.searchLists(domain: 'example.com');

      expect(result.isSuccess(), true);
      expect(service.lastSearchPartial, isNull);
      expect(service.lastSearchN, isNull);
    });

    test('fails when generated search request fails', () async {
      service.shouldFailSearch = true;

      final result = await repository.searchLists(domain: 'example.com');
      expectError(
        result,
        messageContains: 'Forced searchDomainInLists failure',
      );
    });
  });
}
