import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/model/local/saved_log_filter_preset.dart';
import 'package:pi_hole_client/data/repositories/local/saved_log_filters_repository.dart';
import 'package:pi_hole_client/data/services/local/database_service.dart';
import 'package:pi_hole_client/domain/model/enums.dart';
import 'package:pi_hole_client/ui/logs/view_models/logs_viewmodel.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _MemoryPresets implements SavedLogFiltersRepository {
  final records = <String, SavedLogFilterPreset>{};

  String key(String address, String api, String name) =>
      address + '|' + api + '|' + name.toLowerCase();

  @override
  Future<List<SavedLogFilterPreset>> list(String address, String api) async =>
      records.entries
          .where((entry) => entry.key.startsWith(address + '|' + api + '|'))
          .map((entry) => entry.value)
          .toList();

  @override
  Future<void> save(String address, SavedLogFilterPreset preset) async {
    records[key(address, preset.apiVersion, preset.name)] = preset;
  }

  @override
  Future<void> delete(String address, String api, String name) async {
    records.remove(key(address, api, name));
  }
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('SavedLogFilterPreset serialization', () {
    test('round-trips client subset, status keys and exact time range', () {
      final item = SavedLogFilterPreset(
        name: 'DNS failures',
        apiVersion: 'v6',
        statusKeys: const ['GRAVITY', 'REGEX'],
        requestStatus: 'blocked',
        selectedClients: const ['host-a'],
        domain: 'example.com',
        startTime: DateTime.utc(2026, 10, 1),
        endTime: DateTime.utc(2026, 10, 2),
      );
      final decoded = SavedLogFilterPreset.decode(
        name: item.name, apiVersion: item.apiVersion, json: item.encode(),
      );
      expect(decoded.statusKeys, ['GRAVITY', 'REGEX']);
      expect(decoded.selectedClients, ['host-a']);
      expect(decoded.domain, 'example.com');
      expect(decoded.startTime, DateTime.utc(2026, 10, 1));
      expect(decoded.endTime, DateTime.utc(2026, 10, 2));
    });

    test('rejects unknown format versions and malformed lists', () {
      expect(
        () => SavedLogFilterPreset.decode(
          name: 'a', apiVersion: 'v6', json: '{"version":2}',
        ),
        throwsFormatException,
      );
      expect(
        () => SavedLogFilterPreset.decode(
          name: 'a', apiVersion: 'v6',
          json: '{"version":1,"statusKeys":[3],"requestStatus":"all"}',
        ),
        throwsFormatException,
      );
    });
  });

  group('SQLite saved log filters', () {
    late DatabaseService database;
    late LocalSavedLogFiltersRepository store;

    setUp(() async {
      database = DatabaseService(path: inMemoryDatabasePath);
      (await database.open()).getOrThrow();
      store = LocalSavedLogFiltersRepository(database);
      for (final address in ['server-a', 'server-b']) {
        (await database.insert('servers', {
          'address': address, 'alias': address, 'isDefaultServer': 0,
          'apiVersion': 'v6', 'allowUntrustedCert': 0,
          'ignoreCertificateErrors': 0, 'pinnedCertificateSha256': null,
        })).getOrThrow();
      }
    });
    tearDown(() async => database.close());

    SavedLogFilterPreset preset(String name, String api) =>
        SavedLogFilterPreset(
          name: name, apiVersion: api, statusKeys: const ['GRAVITY'],
          requestStatus: 'blocked', selectedClients: null,
        );

    test('server and API isolation with case-insensitive upsert', () async {
      await store.save('server-a', preset('Blocked', 'v6'));
      await store.save('server-a', preset('blocked', 'v6'));
      await store.save('server-a', preset('Blocked', 'v5'));
      await store.save('server-b', preset('Blocked', 'v6'));
      final a = await store.list('server-a', 'v6');
      expect(a, hasLength(1));
      expect(a.single.name, 'blocked');
      expect(await store.list('server-a', 'v5'), hasLength(1));
      expect(await store.list('server-b', 'v6'), hasLength(1));
      await store.delete('server-a', 'v6', 'BLOCKED');
      expect(await store.list('server-a', 'v6'), isEmpty);
      expect(await store.list('server-b', 'v6'), hasLength(1));
    });

    test('server deletion cascades to saved presets', () async {
      await store.save('server-a', preset('Blocked', 'v6'));
      (await database.delete('servers', where: 'address = ?',
          whereArgs: ['server-a'])).getOrThrow();
      expect(await store.list('server-a', 'v6'), isEmpty);
    });

    test('missing server does not accept a saved preset', () async {
      await expectLater(
        store.save('missing-server', preset('Blocked', 'v6')),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('LogsViewModel saved presets', () {
    late _MemoryPresets storage;
    late LogsViewModel vm;
    setUp(() {
      storage = _MemoryPresets();
      vm = LogsViewModel(savedLogFiltersRepository: storage);
      vm.update(apiVersion: 'v6', selectedServerAddress: 'server-a');
      vm.setClients(['host-a', 'host-b']);
    });
    tearDown(() => vm.dispose());

    test('save and apply restores status, client, domain and time', () async {
      vm.setRequestStatus(RequestStatus.blocked);
      vm.setSelectedClients(['host-a']);
      vm.setSelectedDomain('example.com');
      vm.setStartTime(DateTime(2026, 10, 1));
      vm.setEndTime(DateTime(2026, 10, 2));
      await vm.saveCurrentFilterPreset('DNS');
      vm.resetFilters();
      expect(vm.selectedDomain, isNull);
      await vm.applyFilterPreset((await vm.loadFilterPresets()).single);
      expect(vm.requestStatus, RequestStatus.blocked);
      expect(vm.selectedClients, ['host-a']);
      expect(vm.selectedDomain, 'example.com');
      expect(vm.startTime, DateTime(2026, 10, 1));
      expect(vm.endTime, DateTime(2026, 10, 2));
    });

    test('switching server and API version hides presets', () async {
      await vm.saveCurrentFilterPreset('DNS');
      vm.update(apiVersion: 'v6', selectedServerAddress: 'server-b');
      expect(await vm.loadFilterPresets(), isEmpty);
      vm.update(apiVersion: 'v5', selectedServerAddress: 'server-a');
      expect(await vm.loadFilterPresets(), isEmpty);
      vm.update(apiVersion: 'v6', selectedServerAddress: 'server-a');
      expect(await vm.loadFilterPresets(), hasLength(1));
    });

    test('obsolete status filter rejected without changing state', () async {
      vm.setSelectedDomain('before.example');
      final old = SavedLogFilterPreset(
        name: 'old', apiVersion: 'v6',
        statusKeys: const ['STATUS_NOT_SUPPORTED'],
        requestStatus: 'all', selectedClients: null,
      );
      await expectLater(vm.applyFilterPreset(old), throwsFormatException);
      expect(vm.selectedDomain, 'before.example');
    });

    test('rejects empty name and missing server', () async {
      await expectLater(vm.saveCurrentFilterPreset(' '), throwsFormatException);
      vm.update(apiVersion: 'v6', selectedServerAddress: null);
      await expectLater(vm.saveCurrentFilterPreset('DNS'), throwsStateError);
    });
  });
}
