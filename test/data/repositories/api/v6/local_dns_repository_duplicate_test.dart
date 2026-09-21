import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/repositories/api/v6/local_dns_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pi_hole_client/domain/model/local_dns/cname_record.dart';
import 'package:pi_hole_client/utils/exceptions.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart' hide Success;
import 'package:result_dart/result_dart.dart';

import '../../../../../testing/fakes/services/fake_pihole_v6_api_client.dart';
import '../../../../../testing/fakes/services/fake_session_credential_service.dart';

class _DuplicateService extends PiholeV6Service {
  _DuplicateService()
    : super(api: PiholeV6Api(basePathOverride: 'http://localhost/api'));

  Exception? error;
  int addCallCount = 0;
  String? lastElement;

  @override
  void setSid(String sid) {}

  @override
  Future<Result<Unit>> addConfigArrayItem({
    required String element,
    required String value,
    bool? restart = true,
  }) async {
    addCallCount++;
    lastElement = element;
    final failure = error;
    if (failure != null) return Failure(failure);
    return const Success(unit);
  }
}

void main() {
  late _DuplicateService service;
  late LocalDnsRepositoryV6 repository;

  setUp(() {
    final client = FakePiholeV6ApiClient();
    final creds = FakeSessionCredentialService();
    service = _DuplicateService();
    repository = LocalDnsRepositoryV6(
      service: service,
      sessionCache: V6SessionCache(creds: creds, client: client),
    );
  });

  test(
    'host duplicate maps generated 400 to AlreadyExists without retry',
    () async {
      service.error = HttpStatusCodeException(
        400,
        '{"error":{"key":"bad_request","message":"Item already present",'
        '"hint":"Uniqueness of items is enforced"}}',
      );

      final result = await repository.addRecord(
        ip: '192.168.1.10',
        name: 'nas',
      );

      expect(result.exceptionOrNull(), isA<AlreadyExistsException>());
      expect(service.addCallCount, 1);
      expect(service.lastElement, 'dns/hosts');
    },
  );

  test(
    'CNAME duplicate maps generated 400 to AlreadyExists without retry',
    () async {
      service.error = HttpStatusCodeException(
        400,
        '{"error":{"key":"bad_request","message":"Item already present"}}',
      );

      final result = await repository.addCnameRecord(
        record: const CnameRecord(alias: 'nas.example', target: 'nas.lan'),
      );

      expect(result.exceptionOrNull(), isA<AlreadyExistsException>());
      expect(service.addCallCount, 1);
      expect(service.lastElement, 'dns/cnameRecords');
    },
  );

  test('non-duplicate failure keeps its type and normal retry behavior', () async {
    service.error = HttpStatusCodeException(500, 'Server error');

    final result = await repository.addRecord(
      ip: '192.168.1.10',
      name: 'nas',
    );

    final error = result.exceptionOrNull();
    expect(error, isA<HttpStatusCodeException>());
    expect(error, isNot(isA<AlreadyExistsException>()));
    expect(service.addCallCount, 2);
  });
}
