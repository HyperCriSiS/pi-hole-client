import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/model/v5/domains.dart';
import 'package:pi_hole_client/data/repositories/api/v5/domain_repository.dart';
import 'package:pi_hole_client/data/repositories/utils/constants.dart';
import 'package:pi_hole_client/domain/model/enums.dart';
import 'package:pi_hole_client/utils/exceptions.dart';
import 'package:result_dart/result_dart.dart';

import '../../../../../testing/fakes/services/fake_pihole_v5_api_client.dart';
import '../../../../../testing/fakes/services/fake_session_credential_service.dart';
import '../../../../../testing/helper/test_helper.dart';
import '../../../../../testing/models/v5/domain.dart';

class _DomainResponseClient extends FakePiholeV5ApiClient {
  DomainResponse response = const DomainResponse(
    success: true,
    message: 'Added example.com',
  );
  int postDomainCallCount = 0;

  @override
  Future<Result<DomainResponse>> postDomain(
    String token, {
    required String domain,
    required V5DomainType domainType,
  }) async {
    postDomainCallCount++;
    return Success(response);
  }
}

void main() async {
  group('NotSupportedException', () {
    late DomainRepositoryV5 repository;
    late FakePiholeV5ApiClient client;
    late FakeSessionCredentialService creds;

    setUp(() {
      client = FakePiholeV5ApiClient();
      creds = FakeSessionCredentialService();
      repository = DomainRepositoryV5(client: client, creds: creds);
    });

    test('updateDomain should return NotSupportedException', () async {
      final result = await repository.updateDomain(
        DomainType.allow,
        DomainKind.exact,
        'example.com',
      );
      expectError(result, messageContains: kNotSupportedInV5Message);
    });
  });

  group('fetchAllDomains', () {
    late DomainRepositoryV5 repository;
    late FakePiholeV5ApiClient client;
    late FakeSessionCredentialService creds;

    setUp(() {
      client = FakePiholeV5ApiClient();
      creds = FakeSessionCredentialService();
      repository = DomainRepositoryV5(client: client, creds: creds);
    });

    test('should fetch all domains', () async {
      final result = await repository.fetchAllDomains();
      expect(result.isSuccess(), true);
      expect(result.getOrNull(), kRepoGetDomains);
    });

    test('should return an error if fetching domains fails', () async {
      client.shouldFail = true;
      final result = await repository.fetchAllDomains();
      expect(result.isError(), true);
    });
  });

  group('addDomain', () {
    late DomainRepositoryV5 repository;
    late FakePiholeV5ApiClient client;
    late FakeSessionCredentialService creds;

    setUp(() {
      client = FakePiholeV5ApiClient();
      creds = FakeSessionCredentialService();
      repository = DomainRepositoryV5(client: client, creds: creds);
    });

    test('should add domain successfully', () async {
      final result = await repository.addDomain(
        DomainType.allow,
        DomainKind.exact,
        'example.com',
        comment: 'test comment',
        groups: [1, 2],
        enabled: false,
      );
      expect(result.isSuccess(), true);
      expect(result.getOrNull(), kRepoAddDomain);
    });

    test('should return an error if add fails', () async {
      client.shouldFail = true;
      final result = await repository.addDomain(
        DomainType.allow,
        DomainKind.exact,
        'example.com',
      );
      expect(result.isError(), true);
    });

    test('maps duplicate success message and does not retry it', () async {
      final duplicateClient = _DomainResponseClient()
        ..response = const DomainResponse(
          success: true,
          message: 'Not adding example.com as it is already on the list',
        );
      final duplicateRepository = DomainRepositoryV5(
        client: duplicateClient,
        creds: FakeSessionCredentialService(),
      );

      final result = await duplicateRepository.addDomain(
        DomainType.allow,
        DomainKind.exact,
        'example.com',
      );

      expect(result.exceptionOrNull(), isA<AlreadyExistsException>());
      expect(duplicateClient.postDomainCallCount, 1);
    });

    test('keeps normal success message as success', () async {
      final responseClient = _DomainResponseClient();
      final responseRepository = DomainRepositoryV5(
        client: responseClient,
        creds: FakeSessionCredentialService(),
      );

      final result = await responseRepository.addDomain(
        DomainType.allow,
        DomainKind.exact,
        'example.com',
      );

      expect(result.isSuccess(), true);
      expect(responseClient.postDomainCallCount, 1);
    });

    test('maps success false response to failure', () async {
      final responseClient = _DomainResponseClient()
        ..response = const DomainResponse(
          success: false,
          message: 'Invalid domain',
        );
      final responseRepository = DomainRepositoryV5(
        client: responseClient,
        creds: FakeSessionCredentialService(),
      );

      final result = await responseRepository.addDomain(
        DomainType.allow,
        DomainKind.exact,
        'example.com',
      );

      expect(result.isError(), true);
      expect(result.exceptionOrNull().toString(), contains('Invalid domain'));
    });
  });

  group('deleteDomain', () {
    late DomainRepositoryV5 repository;
    late FakePiholeV5ApiClient client;
    late FakeSessionCredentialService creds;

    setUp(() {
      client = FakePiholeV5ApiClient();
      creds = FakeSessionCredentialService();
      repository = DomainRepositoryV5(client: client, creds: creds);
    });

    test('should delete domain successfully', () async {
      final result = await repository.deleteDomain(
        DomainType.allow,
        DomainKind.exact,
        'example.com',
      );
      expect(result.isSuccess(), true);
    });

    test('should return an error if delete fails', () async {
      client.shouldFail = true;
      final result = await repository.deleteDomain(
        DomainType.allow,
        DomainKind.exact,
        'example.com',
      );
      expect(result.isError(), true);
      expectError(result, messageContains: 'Failed to delete domain');
    });
  });
}
