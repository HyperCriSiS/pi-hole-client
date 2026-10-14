import 'dart:async';

import 'package:command_it/command_it.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/cname_repository.dart';
import 'package:pi_hole_client/domain/model/local_dns/cname_record.dart';
import 'package:pi_hole_client/domain/model/local_dns/local_dns.dart';
import 'package:pi_hole_client/ui/settings/server_settings/advanced_settings/local_dns/view_models/local_dns_viewmodel.dart';
import 'package:pi_hole_client/utils/exceptions.dart';
import 'package:result_dart/result_dart.dart';

import '../../../../../../../testing/fakes/repositories/api/fake_local_dns_repository.dart';
import '../../../../../../../testing/fakes/repositories/api/fake_network_repository.dart';
import '../../../../../../../testing/models/v6/local_dns.dart';

const sameIpRecords = [
  LocalDns(ip: '192.168.1.10', name: 'nas'),
  LocalDns(ip: '192.168.1.10', name: 'printer'),
];

class _FakeCnameRepository implements CnameRepository {
  bool shouldFail = false;
  List<CnameRecord> records = const [];
  Completer<Result<List<CnameRecord>>>? pendingFetch;

  @override
  Future<Result<List<CnameRecord>>> fetchCnameRecords() async {
    final pending = pendingFetch;
    if (pending != null) {
      pendingFetch = null;
      return pending.future;
    }
    if (shouldFail) return Failure(Exception('Force CNAME fetch failure'));
    return Success(records);
  }

  @override
  Future<Result<Unit>> addCnameRecord({required CnameRecord record}) async {
    if (shouldFail) return Failure(Exception('Force CNAME add failure'));
    return const Success(unit);
  }

  @override
  Future<Result<Unit>> updateCnameRecord({
    required CnameRecord oldRecord,
    required CnameRecord record,
  }) async {
    if (shouldFail) return Failure(Exception('Force CNAME update failure'));
    return const Success(unit);
  }

  @override
  Future<Result<Unit>> deleteCnameRecord({required CnameRecord record}) async {
    if (shouldFail) return Failure(Exception('Force CNAME delete failure'));
    return const Success(unit);
  }
}

class _DeferredLocalDnsRepository extends FakeLocalDnsRepository {
  Completer<Result<List<LocalDns>>>? pendingFetch;

  @override
  Future<Result<List<LocalDns>>> fetchRecords() {
    final pending = pendingFetch;
    if (pending != null) {
      pendingFetch = null;
      return pending.future;
    }
    return super.fetchRecords();
  }
}

void main() {
  group('LocalDnsViewModel', () {
    late FakeLocalDnsRepository fakeLocalDnsRepository;
    late FakeNetworkRepository fakeNetworkRepository;
    late _FakeCnameRepository fakeCnameRepository;
    late LocalDnsViewModel viewModel;

    setUp(() {
      Command.globalExceptionHandler = (_, _) {};
      fakeLocalDnsRepository = FakeLocalDnsRepository();
      fakeNetworkRepository = FakeNetworkRepository();
      fakeCnameRepository = _FakeCnameRepository();
      viewModel = LocalDnsViewModel(
        localDnsRepository: fakeLocalDnsRepository,
        networkRepository: fakeNetworkRepository,
        cnameRepository: fakeCnameRepository,
      );
    });

    tearDown(() {
      viewModel.dispose();
      Command.globalExceptionHandler = null;
    });

    test('loadRecords success populates records and deviceOptions', () async {
      await viewModel.loadRecords.runAsync();

      expect(viewModel.data.records, equals(kRepoFetchLocalDnsRecords));
      expect(viewModel.data.records.length, 3);
      expect(viewModel.data.deviceOptions, isNotEmpty);
    });

    test('keeps last successful result after failed revalidation and retry', () async {
      expect(viewModel.hasLoadedSuccessfully, isFalse);
      await viewModel.loadRecords.runAsync();
      expect(viewModel.hasLoadedSuccessfully, isTrue);
      expect(viewModel.data.records, equals(kRepoFetchLocalDnsRecords));

      fakeLocalDnsRepository.shouldFail = true;
      await expectLater(
        viewModel.loadRecords.runAsync(),
        throwsA(isA<Exception>()),
      );
      expect(viewModel.hasLoadedSuccessfully, isTrue);
      expect(viewModel.data.records, equals(kRepoFetchLocalDnsRecords));

      fakeLocalDnsRepository.shouldFail = false;
      await viewModel.loadRecords.runAsync();
      expect(viewModel.loadRecords.errors.value, isNull);
      expect(viewModel.data.records, equals(kRepoFetchLocalDnsRecords));
    });

    test('successful empty result counts as loaded', () async {
      fakeLocalDnsRepository.records = [];
      expect(viewModel.hasLoadedSuccessfully, isFalse);
      await viewModel.loadRecords.runAsync();
      expect(viewModel.hasLoadedSuccessfully, isTrue);
      expect(viewModel.data.records, isEmpty);
      fakeLocalDnsRepository.shouldFail = true;
      await expectLater(
        viewModel.loadRecords.runAsync(),
        throwsA(isA<Exception>()),
      );
      expect(viewModel.hasLoadedSuccessfully, isTrue);
      expect(viewModel.data.records, isEmpty);
    });

    test('loadRecords failure sets error', () async {
      fakeLocalDnsRepository.shouldFail = true;

      final completer = Completer<void>();
      viewModel.loadRecords.errors.addListener(() {
        if (!completer.isCompleted) completer.complete();
      });
      viewModel.loadRecords.run();
      await completer.future;

      expect(viewModel.loadRecords.errors.value, isNotNull);
    });

    test('loadRecords failure and retry notify screen listeners', () async {
      var sawLoading = false;
      var sawError = false;
      var sawRecovered = false;
      final errorNotified = Completer<void>();

      viewModel.addListener(() {
        final isLoading = viewModel.loadRecords.isRunning.value;
        final hasError = viewModel.loadRecords.errors.value != null;
        if (isLoading) sawLoading = true;
        if (hasError) {
          sawError = true;
          if (!errorNotified.isCompleted) errorNotified.complete();
        }
        if (sawError && !isLoading && !hasError) {
          sawRecovered = true;
        }
      });

      fakeLocalDnsRepository.shouldFail = true;
      viewModel.loadRecords.run();
      await errorNotified.future;
      await Future<void>.delayed(Duration.zero);

      expect(sawLoading, isTrue);
      expect(sawError, isTrue);
      expect(viewModel.loadRecords.isRunning.value, isFalse);

      fakeLocalDnsRepository.shouldFail = false;
      await viewModel.loadRecords.runAsync();

      expect(viewModel.loadRecords.errors.value, isNull);
      expect(viewModel.loadRecords.isRunning.value, isFalse);
      expect(sawRecovered, isTrue);
    });



    group('refresh overlapping successful host mutations', () {
      for (final operation in ['add', 'update', 'delete']) {
        test('does not undo a completed host $operation', () async {
          final repository = _DeferredLocalDnsRepository();
          final scoped = LocalDnsViewModel(
            localDnsRepository: repository,
            networkRepository: fakeNetworkRepository,
            cnameRepository: fakeCnameRepository,
          );
          addTearDown(scoped.dispose);

          await scoped.loadRecords.runAsync();
          final original = List<LocalDns>.of(scoped.data.records);
          final options = scoped.data.deviceOptions;

          final pending = Completer<Result<List<LocalDns>>>();
          repository.pendingFetch = pending;
          final refresh = scoped.loadRecords.runAsync();
          expect(scoped.loadRecords.isRunning.value, isTrue);

          if (operation == 'add') {
            await scoped.addRecord.runAsync(
              const LocalDns(ip: '192.168.1.250', name: 'added'),
            );
          } else if (operation == 'update') {
            await scoped.updateRecord.runAsync((
              oldRecord: original.first,
              newRecord: const LocalDns(
                ip: '192.168.1.251',
                name: 'updated',
              ),
            ));
          } else {
            await scoped.deleteRecord.runAsync(original.first);
          }

          final afterMutation = List<LocalDns>.of(scoped.data.records);
          expect(afterMutation, isNot(equals(original)));

          // The delayed response is a pre-mutation snapshot.
          pending.complete(Success(original));
          await refresh;

          expect(scoped.data.records, afterMutation);
          expect(scoped.data.deviceOptions, options);
          expect(scoped.hasLoadedSuccessfully, isTrue);
          expect(scoped.loadRecords.errors.value, isNull);
        });
      }
    });

    group('refresh overlapping successful CNAME mutations', () {
      const oldRecord = CnameRecord(
        alias: 'old.example',
        target: 'target.example',
      );
      const newRecord = CnameRecord(
        alias: 'new.example',
        target: 'target.example',
      );

      for (final operation in ['add', 'update', 'delete']) {
        test('does not undo a completed CNAME $operation', () async {
          fakeCnameRepository.records = [oldRecord];
          await viewModel.loadRecords.runAsync();
          final hostSnapshot = List<LocalDns>.of(viewModel.data.records);
          final options = viewModel.data.deviceOptions;

          final pending = Completer<Result<List<CnameRecord>>>();
          fakeCnameRepository.pendingFetch = pending;
          final refresh = viewModel.loadRecords.runAsync();

          if (operation == 'add') {
            await viewModel.addCnameRecord.runAsync(newRecord);
          } else if (operation == 'update') {
            await viewModel.updateCnameRecord.runAsync((
              oldRecord: oldRecord,
              record: newRecord,
            ));
          } else {
            await viewModel.deleteCnameRecord.runAsync(oldRecord);
          }

          final afterMutation = List<CnameRecord>.of(
            viewModel.data.cnameRecords,
          );
          expect(afterMutation, isNot(equals([oldRecord])));

          pending.complete(const Success([oldRecord]));
          await refresh;

          expect(viewModel.data.cnameRecords, afterMutation);
          expect(viewModel.data.records, hostSnapshot);
          expect(viewModel.data.deviceOptions, options);
          expect(viewModel.hasLoadedSuccessfully, isTrue);
          expect(viewModel.loadRecords.errors.value, isNull);
        });
      }
    });

    test('failed host mutation preserves an earlier valid refresh', () async {
      final repository = _DeferredLocalDnsRepository();
      final scoped = LocalDnsViewModel(
        localDnsRepository: repository,
        networkRepository: fakeNetworkRepository,
        cnameRepository: fakeCnameRepository,
      );
      addTearDown(scoped.dispose);

      await scoped.loadRecords.runAsync();
      final pending = Completer<Result<List<LocalDns>>>();
      repository.pendingFetch = pending;
      final refresh = scoped.loadRecords.runAsync();

      repository.shouldFail = true;
      await expectLater(
        scoped.addRecord.runAsync(
          const LocalDns(ip: '192.168.1.253', name: 'failed'),
        ),
        throwsA(isA<Exception>()),
      );

      const remoteRecord = LocalDns(
        ip: '192.168.1.252',
        name: 'remote',
      );
      pending.complete(const Success([remoteRecord]));
      await refresh;

      expect(scoped.data.records, const [remoteRecord]);
      expect(scoped.hasLoadedSuccessfully, isTrue);
      expect(scoped.loadRecords.errors.value, isNull);
    });

    test('failed CNAME mutation preserves an earlier valid refresh', () async {
      const remoteRecord = CnameRecord(
        alias: 'remote.example',
        target: 'target.example',
      );
      final pending = Completer<Result<List<CnameRecord>>>();
      fakeCnameRepository.pendingFetch = pending;
      final refresh = viewModel.loadRecords.runAsync();

      fakeCnameRepository.shouldFail = true;
      await expectLater(
        viewModel.deleteCnameRecord.runAsync(remoteRecord),
        throwsA(isA<Exception>()),
      );

      pending.complete(const Success([remoteRecord]));
      await refresh;

      expect(viewModel.data.cnameRecords, const [remoteRecord]);
      expect(viewModel.hasLoadedSuccessfully, isTrue);
      expect(viewModel.loadRecords.errors.value, isNull);
    });

    test('older empty refresh cannot undo an added host', () async {
      final repository = _DeferredLocalDnsRepository()..records = [];
      final scoped = LocalDnsViewModel(
        localDnsRepository: repository,
        networkRepository: fakeNetworkRepository,
        cnameRepository: fakeCnameRepository,
      );
      addTearDown(scoped.dispose);

      await scoped.loadRecords.runAsync();
      expect(scoped.hasLoadedSuccessfully, isTrue);
      expect(scoped.data.records, isEmpty);

      final pending = Completer<Result<List<LocalDns>>>();
      repository.pendingFetch = pending;
      final refresh = scoped.loadRecords.runAsync();
      const newRecord = LocalDns(ip: '192.168.1.254', name: 'new');
      await scoped.addRecord.runAsync(newRecord);

      pending.complete(const Success([]));
      await refresh;

      expect(scoped.data.records, const [newRecord]);
      expect(scoped.hasLoadedSuccessfully, isTrue);
    });

    test('addRecord success appends record locally', () async {
      await viewModel.loadRecords.runAsync();

      await viewModel.addRecord.runAsync(
        const LocalDns(ip: '192.168.1.200', name: 'newhost'),
      );

      expect(fakeLocalDnsRepository.addRecordCallCount, 1);
      // No re-fetch — local state update only
      expect(fakeLocalDnsRepository.fetchRecordsCallCount, 1);
      expect(viewModel.data.records.length, 4);
      expect(viewModel.data.records.last.ip, '192.168.1.200');
    });

    test('addRecord failure sets error', () async {
      await viewModel.loadRecords.runAsync();
      fakeLocalDnsRepository.shouldFail = true;

      final completer = Completer<void>();
      viewModel.addRecord.errors.addListener(() {
        if (!completer.isCompleted) completer.complete();
      });
      viewModel.addRecord.run(
        const LocalDns(ip: '192.168.1.200', name: 'newhost'),
      );
      await completer.future;

      expect(viewModel.addRecord.errors.value, isNotNull);
    });

    test('updateRecord success replaces record locally', () async {
      await viewModel.loadRecords.runAsync();

      await viewModel.updateRecord.runAsync((
        oldRecord: const LocalDns(ip: '192.168.1.100', name: 'server1'),
        newRecord: const LocalDns(ip: '192.168.1.200', name: 'updated'),
      ));

      expect(fakeLocalDnsRepository.updateRecordCallCount, 1);
      // No re-fetch — local state update only
      expect(fakeLocalDnsRepository.fetchRecordsCallCount, 1);
      expect(viewModel.data.records.length, 3);
      expect(
        viewModel.data.records.any(
          (r) => r == const LocalDns(ip: '192.168.1.100', name: 'server1'),
        ),
        isFalse,
      );
      expect(
        viewModel.data.records.any(
          (r) => r == const LocalDns(ip: '192.168.1.200', name: 'updated'),
        ),
        isTrue,
      );
    });

    test(
      'updateRecord changes only the record with the same IP and name',
      () async {
        fakeLocalDnsRepository.records = sameIpRecords;
        await viewModel.loadRecords.runAsync();

        await viewModel.updateRecord.runAsync((
          oldRecord: const LocalDns(ip: '192.168.1.10', name: 'printer'),
          newRecord: const LocalDns(ip: '192.168.1.10', name: 'printer2'),
        ));

        expect(viewModel.data.records, const [
          LocalDns(ip: '192.168.1.10', name: 'nas'),
          LocalDns(ip: '192.168.1.10', name: 'printer2'),
        ]);
      },
    );

    test('updateRecord failure sets error and keeps records', () async {
      await viewModel.loadRecords.runAsync();
      fakeLocalDnsRepository.shouldFail = true;

      final completer = Completer<void>();
      viewModel.updateRecord.errors.addListener(() {
        if (!completer.isCompleted) completer.complete();
      });
      viewModel.updateRecord.run((
        oldRecord: const LocalDns(ip: '192.168.1.100', name: 'server1'),
        newRecord: const LocalDns(ip: '192.168.1.200', name: 'updated'),
      ));
      await completer.future;

      expect(viewModel.updateRecord.errors.value, isNotNull);
      expect(viewModel.data.records, equals(kRepoFetchLocalDnsRecords));
    });

    test('deleteRecord success removes record locally', () async {
      await viewModel.loadRecords.runAsync();

      await viewModel.deleteRecord.runAsync(
        const LocalDns(ip: '192.168.1.100', name: 'server1'),
      );

      expect(fakeLocalDnsRepository.deleteRecordCallCount, 1);
      // No re-fetch — local state update only
      expect(fakeLocalDnsRepository.fetchRecordsCallCount, 1);
      expect(viewModel.data.records.length, 2);
      expect(
        viewModel.data.records.any(
          (r) => r == const LocalDns(ip: '192.168.1.100', name: 'server1'),
        ),
        isFalse,
      );
    });

    test(
      'deleteRecord removes only the record with the same IP and name',
      () async {
        fakeLocalDnsRepository.records = sameIpRecords;
        await viewModel.loadRecords.runAsync();

        await viewModel.deleteRecord.runAsync(
          const LocalDns(ip: '192.168.1.10', name: 'printer'),
        );

        expect(viewModel.data.records, const [
          LocalDns(ip: '192.168.1.10', name: 'nas'),
        ]);
      },
    );

    test('deleteRecord failure sets error', () async {
      await viewModel.loadRecords.runAsync();
      fakeLocalDnsRepository.shouldFail = true;

      final completer = Completer<void>();
      viewModel.deleteRecord.errors.addListener(() {
        if (!completer.isCompleted) completer.complete();
      });
      viewModel.deleteRecord.run(
        const LocalDns(ip: '192.168.1.100', name: 'server1'),
      );
      await completer.future;

      expect(viewModel.deleteRecord.errors.value, isNotNull);
    });

    group('duplicate records', () {
      const duplicates = [
        LocalDns(ip: '192.168.1.10', name: 'nas'),
        LocalDns(ip: '192.168.1.10', name: 'nas'),
        LocalDns(ip: '192.168.1.20', name: 'printer'),
      ];

      test('add rejects a normalized duplicate', () async {
        fakeLocalDnsRepository.records = const [
          LocalDns(ip: '192.168.1.10', name: 'test  ok'),
        ];
        await viewModel.loadRecords.runAsync();
        await expectLater(
          viewModel.addRecord.runAsync(
            const LocalDns(ip: ' 192.168.1.10 ', name: ' test\tok '),
          ),
          throwsA(isA<AlreadyExistsException>()),
        );
        expect(fakeLocalDnsRepository.addRecordCallCount, 0);
      });

      test('update rejects a value used by another record', () async {
        await viewModel.loadRecords.runAsync();
        await expectLater(
          viewModel.updateRecord.runAsync((
            oldRecord: const LocalDns(ip: '192.168.1.101', name: 'printer1'),
            newRecord: const LocalDns(ip: '192.168.1.100', name: 'server1'),
          )),
          throwsA(isA<AlreadyExistsException>()),
        );
        expect(fakeLocalDnsRepository.updateRecordCallCount, 0);
      });

      test('update changes only first identical record', () async {
        fakeLocalDnsRepository.records = duplicates;
        await viewModel.loadRecords.runAsync();
        await viewModel.updateRecord.runAsync((
          oldRecord: const LocalDns(ip: '192.168.1.10', name: 'nas'),
          newRecord: const LocalDns(ip: '192.168.1.10', name: 'nas2'),
        ));
        expect(viewModel.data.records, const [
          LocalDns(ip: '192.168.1.10', name: 'nas2'),
          LocalDns(ip: '192.168.1.10', name: 'nas'),
          LocalDns(ip: '192.168.1.20', name: 'printer'),
        ]);
      });

      test('delete removes only first identical record', () async {
        fakeLocalDnsRepository.records = duplicates;
        await viewModel.loadRecords.runAsync();
        await viewModel.deleteRecord.runAsync(
          const LocalDns(ip: '192.168.1.10', name: 'nas'),
        );
        expect(viewModel.data.records, const [
          LocalDns(ip: '192.168.1.10', name: 'nas'),
          LocalDns(ip: '192.168.1.20', name: 'printer'),
        ]);
      });
    });

    test('add/update/delete failures do not call global handler', () async {
      var globalCalled = false;
      Command.globalExceptionHandler = (_, _) => globalCalled = true;
      await viewModel.loadRecords.runAsync();
      fakeLocalDnsRepository.shouldFail = true;

      await expectLater(
        viewModel.addRecord.runAsync(
          const LocalDns(ip: '192.168.1.200', name: 'newhost'),
        ),
        throwsA(anything),
      );
      await expectLater(
        viewModel.updateRecord.runAsync((
          oldRecord: const LocalDns(ip: '192.168.1.100', name: 'server1'),
          newRecord: const LocalDns(ip: '192.168.1.200', name: 'updated'),
        )),
        throwsA(anything),
      );
      await expectLater(
        viewModel.deleteRecord.runAsync(
          const LocalDns(ip: '192.168.1.100', name: 'server1'),
        ),
        throwsA(anything),
      );

      expect(globalCalled, isFalse);
    });

    test('CNAME failures do not call global handler', () async {
      var globalCalled = false;
      Command.globalExceptionHandler = (_, _) => globalCalled = true;
      await viewModel.loadRecords.runAsync();
      fakeCnameRepository.shouldFail = true;

      const oldRecord = CnameRecord(alias: 'old.test', target: 'target.test');
      const newRecord = CnameRecord(alias: 'new.test', target: 'target.test');

      await expectLater(
        viewModel.addCnameRecord.runAsync(newRecord),
        throwsA(anything),
      );
      await expectLater(
        viewModel.updateCnameRecord.runAsync((
          oldRecord: oldRecord,
          record: newRecord,
        )),
        throwsA(anything),
      );
      await expectLater(
        viewModel.deleteCnameRecord.runAsync(oldRecord),
        throwsA(anything),
      );

      expect(globalCalled, isFalse);
    });

    test('deviceOptions excludes loopback and sorts IPv4 first', () async {
      await viewModel.loadRecords.runAsync();

      final options = viewModel.data.deviceOptions;
      for (final option in options) {
        expect(option.ip, isNot('127.0.0.1'));
        expect(option.ip, isNot('::'));
        expect(option.ip, isNot('::1'));
      }
    });

    test('isRunning is true while loading', () async {
      final future = viewModel.loadRecords.runAsync();

      expect(viewModel.loadRecords.isRunning.value, isTrue);

      await future;

      expect(viewModel.loadRecords.isRunning.value, isFalse);
    });

    test('notifies listeners on state changes', () async {
      var notifyCount = 0;
      viewModel.addListener(() => notifyCount++);

      await viewModel.loadRecords.runAsync();

      expect(notifyCount, greaterThan(0));
    });
  });
}
