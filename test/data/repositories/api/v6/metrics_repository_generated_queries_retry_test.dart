import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/model/v6/metrics/query_filter.dart';
import 'package:pi_hole_client/data/repositories/api/v6/metrics_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache.dart';
import 'package:pi_hole_client/data/services/api/utils/api_exception.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart' hide Success;
import 'package:result_dart/result_dart.dart';

import '../../../../../testing/fakes/services/fake_pihole_v6_api_client.dart';
import '../../../../../testing/fakes/services/fake_session_credential_service.dart';
import '../../../../../testing/models/v6/metrics.dart';

class _RetryQueriesService extends PiholeV6Service {
  _RetryQueriesService()
    : super(api: PiholeV6Api(basePathOverride: 'http://localhost/api'));

  int callCount = 0;
  String? lastSid;
  int? lastStart;
  int? lastCursor;
  String? lastDomain;
  String? lastClientIp;
  String? lastStatus;
  String? lastType;
  String? lastReply;

  @override
  void setSid(String sid) {
    lastSid = sid;
  }

  @override
  Future<Result<GetQueries200Response>> getQueries({
    num? from,
    num? until,
    int? length,
    int? start,
    int? cursor,
    String? domain,
    String? clientIp,
    String? clientName,
    String? upstream,
    String? type,
    String? status,
    String? reply,
    String? dnssec,
  }) async {
    callCount++;
    lastStart = start;
    lastCursor = cursor;
    lastDomain = domain;
    lastClientIp = clientIp;
    lastStatus = status;
    lastType = type;
    lastReply = reply;
    if (callCount == 1) {
      return Failure(ApiException(message: 'Unauthorized', statusCode: 401));
    }
    final json = jsonDecode(jsonEncode(kSrvGetQueries.toJson()));
    return Success(
      GetQueries200Response.fromJson(json as Map<String, dynamic>),
    );
  }
}

void main() {
  test('renews SID and retries generated queries after 401', () async {
    final client = FakePiholeV6ApiClient();
    final creds = FakeSessionCredentialService();
    final service = _RetryQueriesService();
    final repository = MetricsRepositoryV6(
      client: client,
      service: service,
      sessionCache: V6SessionCache(creds: creds, client: client),
    );

    final result = await repository.fetchQueriesFiltered(
      from: DateTime.fromMillisecondsSinceEpoch(1511819900000),
      until: DateTime.fromMillisecondsSinceEpoch(1511820500000),
      start: 10,
      cursor: 42,
      filter: const V6QueryFilter(
        domain: 'example.com',
        clientIp: '192.0.2.10',
        status: 'FORWARDED',
        type: 'AAAA',
        reply: 'IP',
      ),
    );

    expect(result.getOrNull(), kRepoFetchQueries);
    expect(client.postAuthCallCount, 1);
    expect(service.callCount, 2);
    expect(service.lastStart, 10);
    expect(service.lastCursor, 42);
    expect(service.lastDomain, 'example.com');
    expect(service.lastClientIp, '192.0.2.10');
    expect(service.lastStatus, 'FORWARDED');
    expect(service.lastType, 'AAAA');
    expect(service.lastReply, 'IP');
    expect(service.lastSid, isNot('sid123'));
  });
}
