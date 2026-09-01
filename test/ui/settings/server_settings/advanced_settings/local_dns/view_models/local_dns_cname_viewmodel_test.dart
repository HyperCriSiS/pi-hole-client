import 'package:command_it/command_it.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/cname_repository.dart';
import 'package:pi_hole_client/domain/model/local_dns/cname_record.dart';
import 'package:pi_hole_client/ui/settings/server_settings/advanced_settings/local_dns/view_models/local_dns_viewmodel.dart';
import 'package:result_dart/result_dart.dart';

import '../../../../../../../testing/fakes/repositories/api/fake_local_dns_repository.dart';
import '../../../../../../../testing/fakes/repositories/api/fake_network_repository.dart';

void main() {
  group('LocalDnsViewModel CNAME', () {
    late FakeLocalDnsRepository localDnsRepository;
    late FakeNetworkRepository networkRepository;
    late FakeCnameRepository cnameRepository;
    late LocalDnsViewModel viewModel;

    setUp(() {
      Command.globalExceptionHandler = (_, _) {};
      localDnsRepository = FakeLocalDnsRepository();
      networkRepository = FakeNetworkRepository();
      cnameRepository = FakeCnameRepository();
      viewModel = LocalDnsViewModel(
        localDnsRepository: localDnsRepository,
        networkRepository: networkRepository,
        cnameRepository: cnameRepository,
      );
    });

    tearDown(() {
      viewModel.dispose();
      Command.globalExceptionHandler = null;
    });

    test('loads CNAME records when repository is available', () async {
      await viewModel.loadRecords.runAsync();

      expect(viewModel.supportsCname, isTrue);
      expect(viewModel.data.cnameRecords, equals(kCnameRecords));
      expect(cnameRepository.fetchCallCount, 1);
    });

    test('add CNAME appends record locally without refetch', () async {
      await viewModel.loadRecords.runAsync();
      const record = CnameRecord(
        alias: 'media.home.arpa',
        target: 'server.home.arpa',
        ttl: 120,
      );

      await viewModel.addCnameRecord.runAsync(record);

      expect(cnameRepository.addCallCount, 1);
      expect(cnameRepository.fetchCallCount, 1);
      expect(viewModel.data.cnameRecords.last, record);
    });

    test('update CNAME replaces the selected record locally', () async {
      await viewModel.loadRecords.runAsync();
      const updated = CnameRecord(
        alias: 'printer.home.arpa',
        target: 'new-printer.home.arpa',
        ttl: 600,
      );

      await viewModel.updateCnameRecord.runAsync((
        oldRecord: kCnameRecords.first,
        record: updated,
      ));

      expect(cnameRepository.updateCallCount, 1);
      expect(viewModel.data.cnameRecords.first, updated);
      expect(viewModel.data.cnameRecords, isNot(contains(kCnameRecords.first)));
    });

    test('delete CNAME removes the selected record locally', () async {
      await viewModel.loadRecords.runAsync();

      await viewModel.deleteCnameRecord.runAsync(kCnameRecords.first);

      expect(cnameRepository.deleteCallCount, 1);
      expect(viewModel.data.cnameRecords, isNot(contains(kCnameRecords.first)));
    });
  });
}

const kCnameRecords = [
  CnameRecord(
    alias: 'printer.home.arpa',
    target: 'printer.home.arpa',
    ttl: 300,
  ),
  CnameRecord(alias: 'nas.home.arpa', target: 'server.home.arpa'),
];

class FakeCnameRepository implements CnameRepository {
  int fetchCallCount = 0;
  int addCallCount = 0;
  int updateCallCount = 0;
  int deleteCallCount = 0;

  @override
  Future<Result<List<CnameRecord>>> fetchCnameRecords() async {
    fetchCallCount++;
    return const Success(kCnameRecords);
  }

  @override
  Future<Result<Unit>> addCnameRecord({required CnameRecord record}) async {
    addCallCount++;
    return const Success(unit);
  }

  @override
  Future<Result<Unit>> updateCnameRecord({
    required CnameRecord oldRecord,
    required CnameRecord record,
  }) async {
    updateCallCount++;
    return const Success(unit);
  }

  @override
  Future<Result<Unit>> deleteCnameRecord({required CnameRecord record}) async {
    deleteCallCount++;
    return const Success(unit);
  }
}
