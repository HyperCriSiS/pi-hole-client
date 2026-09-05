import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/model/v6/lists/search.dart' as legacy_search;
import 'package:pi_hole_client/data/repositories/api/v6/adlist_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache.dart';
import 'package:pi_hole_client/data/services/api/utils/api_exception.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pi_hole_client/domain/model/enums.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart' hide Success;
import 'package:result_dart/result_dart.dart';

import '../../../../../testing/fakes/services/fake_pihole_v6_api_client.dart';
import '../../../../../testing/fakes/services/fake_session_credential_service.dart';
import '../../../../../testing/models/v6/adlist.dart';

legacy_search.Search _searchFixture(String domain) {
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
        partial: true,
        N: 7,
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

class _RetryAdlistService extends PiholeV6Service {
  _RetryAdlistService()
    : super(api: PiholeV6Api(basePathOverride: 'http://localhost/api'));

  int fetchCallCount = 0;
  int addCallCount = 0;
  int replaceCallCount = 0;
  int deleteCallCount = 0;
  int searchCallCount = 0;
  String? lastSid;
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
    fetchCallCount++;
    lastFetchType = type;
    if (fetchCallCount == 1) {
      return Failure(ApiException(message: 'Unauthorized', statusCode: 401));
    }
    return Success(GetLists200Response.fromJson(kSrvGetLists.toJson()));
  }

  @override
  Future<Result<ReplaceLists200Response>> addList({
    required String type,
    ListsPost? body,
  }) async {
    addCallCount++;
    lastAddType = type;
    lastAddBody = body;
    if (addCallCount == 1) {
      return Failure(ApiException(message: 'Unauthorized', statusCode: 401));
    }
    return Success(ReplaceLists200Response.fromJson(kSrvPostLists.toJson()));
  }

  @override
  Future<Result<ReplaceLists200Response>> replaceList({
    required String list,
    required String type,
    ListsPut? body,
  }) async {
    replaceCallCount++;
    lastReplaceList = list;
    lastReplaceType = type;
    lastReplaceBody = body;
    if (replaceCallCount == 1) {
      return Failure(ApiException(message: 'Unauthorized', statusCode: 401));
    }
    return Success(ReplaceLists200Response.fromJson(kSrvPutLists.toJson()));
  }

  @override
  Future<Result<Unit>> deleteList({
    required String list,
    required String type,
  }) async {
    deleteCallCount++;
    lastDeleteList = list;
    lastDeleteType = type;
    if (deleteCallCount == 1) {
      return Failure(ApiException(message: 'Unauthorized', statusCode: 401));
    }
    return Success(unit);
  }

  @override
  Future<Result<GetSearch200Response>> searchDomainInLists({
    required String domain,
    int? n,
    bool? partial,
  }) async {
    searchCallCount++;
    lastSearchDomain = domain;
    lastSearchN = n;
    lastSearchPartial = partial;
    if (searchCallCount == 1) {
      return Failure(ApiException(message: 'Unauthorized', statusCode: 401));
    }
    return Success(GetSearch200Response.fromJson(_searchFixture(domain).toJson()));
  }
}

AdlistRepositoryV6 _repository({
  required FakePiholeV6ApiClient client,
  required FakeSessionCredentialService creds,
  required _RetryAdlistService service,
}) {
  return AdlistRepositoryV6(
    service: service,
    sessionCache: V6SessionCache(creds: creds, client: client),
  );
}

void main() {
  test('renews SID and retries generated adlist read after 401', () async {
    final client = FakePiholeV6ApiClient();
    final creds = FakeSessionCredentialService();
    final service = _RetryAdlistService();
    final repository = _repository(client: client, creds: creds, service: service);

    final result = await repository.fetchAdlists(type: ListType.block);

    expect(result.getOrNull(), kRepoFetchAdlists);
    expect(client.postAuthCallCount, 1);
    expect(service.fetchCallCount, 2);
    expect(service.lastFetchType, 'block');
    expect(service.lastSid, isNot('sid123'));
  });

  test('renews SID and retries generated adlist add after 401', () async {
    final client = FakePiholeV6ApiClient();
    final creds = FakeSessionCredentialService();
    final service = _RetryAdlistService();
    final repository = _repository(client: client, creds: creds, service: service);

    final result = await repository.addAdlist(
      'https://example.com/adlist.txt',
      ListType.block,
      groups: const [2],
      comment: 'new list',
      enabled: false,
    );

    expect(result.isSuccess(), true);
    expect(client.postAuthCallCount, 1);
    expect(service.addCallCount, 2);
    expect(service.lastAddType, 'block');
    expect(service.lastAddBody?.address?.value, 'https://example.com/adlist.txt');
    expect(service.lastAddBody?.groups, [2]);
    expect(service.lastAddBody?.comment, 'new list');
    expect(service.lastAddBody?.enabled, false);
    expect(service.lastSid, isNot('sid123'));
  });

  test('renews SID and retries generated adlist update after 401', () async {
    final client = FakePiholeV6ApiClient();
    final creds = FakeSessionCredentialService();
    final service = _RetryAdlistService();
    final repository = _repository(client: client, creds: creds, service: service);

    final result = await repository.updateAdlist(
      'https://example.com/adlist.txt',
      ListType.allow,
      groups: const [1],
      comment: 'updated',
      enabled: false,
    );

    expect(result.isSuccess(), true);
    expect(client.postAuthCallCount, 1);
    expect(service.replaceCallCount, 2);
    expect(service.lastReplaceList, 'https://example.com/adlist.txt');
    expect(service.lastReplaceType, 'allow');
    expect(service.lastReplaceBody?.type?.value, 'allow');
    expect(service.lastReplaceBody?.groups, [1]);
    expect(service.lastReplaceBody?.comment, 'updated');
    expect(service.lastReplaceBody?.enabled, false);
    expect(service.lastSid, isNot('sid123'));
  });

  test('renews SID and retries generated adlist delete after 401', () async {
    final client = FakePiholeV6ApiClient();
    final creds = FakeSessionCredentialService();
    final service = _RetryAdlistService();
    final repository = _repository(client: client, creds: creds, service: service);

    final result = await repository.deleteAdlist(
      'https://example.com/adlist.txt',
      ListType.block,
    );

    expect(result.isSuccess(), true);
    expect(client.postAuthCallCount, 1);
    expect(service.deleteCallCount, 2);
    expect(service.lastDeleteList, 'https://example.com/adlist.txt');
    expect(service.lastDeleteType, 'block');
    expect(service.lastSid, isNot('sid123'));
  });

  test('renews SID and retries generated list search after 401', () async {
    final client = FakePiholeV6ApiClient();
    final creds = FakeSessionCredentialService();
    final service = _RetryAdlistService();
    final repository = _repository(client: client, creds: creds, service: service);

    final result = await repository.searchLists(
      domain: 'example.com',
      partial: true,
      limit: 7,
    );

    final search = result.getOrNull();
    expect(search, isNotNull);
    expect(search!.meta.total, 1);
    expect(client.postAuthCallCount, 1);
    expect(service.searchCallCount, 2);
    expect(service.lastSearchDomain, 'example.com');
    expect(service.lastSearchPartial, true);
    expect(service.lastSearchN, 7);
    expect(service.lastSid, isNot('sid123'));
  });
}
