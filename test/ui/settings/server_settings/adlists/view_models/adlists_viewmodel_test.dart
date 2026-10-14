import 'dart:async';

import 'package:command_it/command_it.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/domain/model/enums.dart';
import 'package:pi_hole_client/domain/model/list/adlist.dart';
import 'package:pi_hole_client/ui/settings/server_settings/adlists/view_models/adlists_viewmodel.dart';
import 'package:result_dart/result_dart.dart';

import '../../../../../../testing/fakes/repositories/api/fake_adlist_repository.dart';

class _ControllableAdlistRepository extends FakeAdlistRepository {
  Completer<Result<List<Adlist>>>? nextFetch;
  bool returnEmpty = false;

  @override
  Future<Result<List<Adlist>>> fetchAdlists({
    String? adlist,
    ListType? type,
  }) {
    final queued = nextFetch;
    nextFetch = null;
    if (queued != null) return queued.future;
    if (returnEmpty && !shouldFail) {
      return Future.value(const Success(<Adlist>[]));
    }
    return super.fetchAdlists(adlist: adlist, type: type);
  }
}

void main() {
  group('AdlistsViewModel', () {
    late bool listenerCalled;
    late AdlistsViewModel viewModel;
    late FakeAdlistRepository fakeAdlistRepository;

    setUp(() {
      Command.globalExceptionHandler = (_, _) {};
      fakeAdlistRepository = FakeAdlistRepository();
      viewModel = AdlistsViewModel(adListRepository: fakeAdlistRepository);
      listenerCalled = false;
      viewModel.addListener(() {
        listenerCalled = true;
      });
    });

    tearDown(() {
      viewModel.dispose();
      Command.globalExceptionHandler = null;
    });

    test('initial values are correct', () {
      expect(viewModel.loadingStatus, LoadStatus.loading);
      expect(viewModel.hasSuccessfulLoad, false);
      expect(viewModel.whitelistAdlists, []);
      expect(viewModel.blacklistAdlists, []);
      expect(viewModel.filteredWhitelistAdlists, []);
      expect(viewModel.filteredBlacklistAdlists, []);
      expect(viewModel.selectedTab, null);
      expect(viewModel.searchTerm, '');
      expect(viewModel.searchMode, false);
      expect(viewModel.groupFilter, null);
      expect(listenerCalled, false);
    });

    test('setSelectedTab updates selected tab', () {
      viewModel.setSelectedTab(1);
      expect(viewModel.selectedTab, 1);
      expect(listenerCalled, false);
    });

    test('setSearchMode updates search mode', () {
      viewModel.setSearchMode(true);
      expect(viewModel.searchMode, true);
      expect(listenerCalled, true);
    });

    test('loadAdlists fetches adlists', () async {
      await viewModel.loadAdlists.runAsync();
      // FakeAdlistRepository returns 1 allow + 2 block
      expect(viewModel.whitelistAdlists.length, 1);
      expect(viewModel.blacklistAdlists.length, 2);
      expect(viewModel.loadingStatus, LoadStatus.loaded);
      expect(viewModel.hasSuccessfulLoad, true);
      expect(listenerCalled, true);
    });

    test('loadAdlists sets error on failure', () async {
      fakeAdlistRepository.shouldFail = true;
      try {
        await viewModel.loadAdlists.runAsync();
      } catch (_) {}
      expect(viewModel.loadingStatus, LoadStatus.error);
      expect(listenerCalled, true);
    });


    test('revalidation retains existing lists while pending', () async {
      final repository = _ControllableAdlistRepository();
      final vm = AdlistsViewModel(adListRepository: repository);
      addTearDown(vm.dispose);
      await vm.loadAdlists.runAsync();
      final oldItems = List<Adlist>.of(vm.blacklistAdlists);
      final gate = Completer<Result<List<Adlist>>>();
      repository.nextFetch = gate;

      final pending = vm.loadAdlists.runAsync();
      expect(vm.hasSuccessfulLoad, true);
      expect(vm.loadingStatus, LoadStatus.loaded);
      expect(vm.isRevalidating, true);
      expect(vm.hasRevalidationError, false);
      expect(vm.blacklistAdlists, oldItems);

      gate.complete(Success(oldItems));
      await pending;
      expect(vm.isRevalidating, false);
      expect(vm.loadingStatus, LoadStatus.loaded);
    });

    test('failed revalidation preserves cached lists and retry clears warning',
        () async {
      final repository = _ControllableAdlistRepository();
      final vm = AdlistsViewModel(adListRepository: repository);
      addTearDown(vm.dispose);
      await vm.loadAdlists.runAsync();
      final old = List<Adlist>.of(vm.blacklistAdlists);

      repository.shouldFail = true;
      try {
        await vm.loadAdlists.runAsync();
      } catch (_) {}
      expect(vm.loadingStatus, LoadStatus.loaded);
      expect(vm.hasRevalidationError, true);
      expect(vm.blacklistAdlists, old);

      repository.shouldFail = false;
      await vm.loadAdlists.runAsync();
      expect(vm.hasRevalidationError, false);
      expect(vm.blacklistAdlists, old);
    });

    test('successful empty response remains a cache after a failed refresh',
        () async {
      final repository = _ControllableAdlistRepository()..returnEmpty = true;
      final vm = AdlistsViewModel(adListRepository: repository);
      addTearDown(vm.dispose);
      await vm.loadAdlists.runAsync();
      expect(vm.hasSuccessfulLoad, true);
      expect(vm.whitelistAdlists, isEmpty);
      expect(vm.blacklistAdlists, isEmpty);
      repository.shouldFail = true;
      try {
        await vm.loadAdlists.runAsync();
      } catch (_) {}
      expect(vm.loadingStatus, LoadStatus.loaded);
      expect(vm.hasRevalidationError, true);
      expect(vm.whitelistAdlists, isEmpty);
      expect(vm.blacklistAdlists, isEmpty);
    });


    group('stale refresh overlapping successful mutations', () {
      for (final operation in ['add', 'update', 'delete']) {
        test('keeps successful adlist $operation over an older read', () async {
          final repository = _ControllableAdlistRepository();
          final vm = AdlistsViewModel(adListRepository: repository);
          addTearDown(vm.dispose);
          await vm.loadAdlists.runAsync();
          final original = [
            ...vm.whitelistAdlists,
            ...vm.blacklistAdlists,
          ];
          final stale = Completer<Result<List<Adlist>>>();
          repository.nextFetch = stale;
          final refresh = vm.loadAdlists.runAsync();

          if (operation == 'add') {
            await vm.addAdlist.runAsync((
              address: 'https://new.example.com/hosts',
              type: ListType.allow,
              groups: [0],
              comment: 'new list',
              enabled: true,
            ));
          } else if (operation == 'update') {
            await vm.updateAdlist.runAsync(
              vm.blacklistAdlists.first.copyWith(
                comment: 'changed while refreshing',
              ),
            );
          } else {
            await vm.deleteAdlist.runAsync(vm.blacklistAdlists.first);
          }

          final allow = List<Adlist>.of(vm.whitelistAdlists);
          final block = List<Adlist>.of(vm.blacklistAdlists);
          expect([...allow, ...block], isNot(equals(original)));
          stale.complete(Success(original));
          await refresh;

          expect(vm.whitelistAdlists, allow);
          expect(vm.blacklistAdlists, block);
          expect(vm.filteredWhitelistAdlists, allow);
          expect(vm.filteredBlacklistAdlists, block);
          expect(vm.hasSuccessfulLoad, isTrue);
          expect(vm.loadAdlists.errors.value, isNull);
        });
      }
    });

    test('failed adlist mutation keeps a valid in-flight refresh', () async {
      final repository = _ControllableAdlistRepository();
      final vm = AdlistsViewModel(adListRepository: repository);
      addTearDown(vm.dispose);
      await vm.loadAdlists.runAsync();
      final stale = Completer<Result<List<Adlist>>>();
      repository.nextFetch = stale;
      final refresh = vm.loadAdlists.runAsync();

      repository.shouldFail = true;
      await expectLater(
        vm.addAdlist.runAsync((
          address: 'https://failed.example.com/hosts',
          type: ListType.block,
          groups: [0],
          comment: null,
          enabled: true,
        )),
        throwsA(isA<Exception>()),
      );
      stale.complete(const Success<List<Adlist>, Exception>([]));
      await refresh;

      expect(vm.whitelistAdlists, isEmpty);
      expect(vm.blacklistAdlists, isEmpty);
      expect(vm.hasSuccessfulLoad, isTrue);
      expect(vm.loadAdlists.errors.value, isNull);
    });

    test('older empty refresh cannot remove a newly added adlist', () async {
      final repository = _ControllableAdlistRepository()..returnEmpty = true;
      final vm = AdlistsViewModel(adListRepository: repository);
      addTearDown(vm.dispose);
      await vm.loadAdlists.runAsync();
      expect(vm.whitelistAdlists, isEmpty);

      final stale = Completer<Result<List<Adlist>>>();
      repository.nextFetch = stale;
      final refresh = vm.loadAdlists.runAsync();
      await vm.addAdlist.runAsync((
        address: 'https://new.example.com/hosts',
        type: ListType.allow,
        groups: [0],
        comment: null,
        enabled: true,
      ));
      stale.complete(const Success<List<Adlist>, Exception>([]));
      await refresh;

      expect(vm.whitelistAdlists, hasLength(1));
      expect(vm.filteredWhitelistAdlists, hasLength(1));
      expect(vm.hasSuccessfulLoad, isTrue);
    });

    test('onSearch filters adlists based on search term', () async {
      await viewModel.loadAdlists.runAsync();
      listenerCalled = false;

      viewModel.onSearch('another');
      expect(viewModel.filteredWhitelistAdlists.length, 0);
      expect(viewModel.filteredBlacklistAdlists.length, 1);
      expect(
        viewModel.filteredBlacklistAdlists.first.address,
        'https://another-blocklist.example.com/hosts',
      );
      expect(listenerCalled, true);
    });

    test('onSearch is case-insensitive', () async {
      await viewModel.loadAdlists.runAsync();
      listenerCalled = false;

      viewModel.onSearch('BLOCKLIST');
      expect(viewModel.filteredWhitelistAdlists.length, 0);
      expect(viewModel.filteredBlacklistAdlists.length, 2);
      expect(listenerCalled, true);
    });

    test('deleteAdlist removes adlist from the list', () async {
      await viewModel.loadAdlists.runAsync();
      final adlist = viewModel.blacklistAdlists.first;
      listenerCalled = false;

      await viewModel.deleteAdlist.runAsync(adlist);
      expect(
        viewModel.blacklistAdlists.where((a) => a.id == adlist.id),
        isEmpty,
      );
      expect(listenerCalled, true);
    });

    test('addAdlist appends adlist locally', () async {
      await viewModel.loadAdlists.runAsync();
      final initialCount = viewModel.whitelistAdlists.length;

      await viewModel.addAdlist.runAsync((
        address: 'https://new.example.com/hosts',
        type: ListType.allow,
        groups: [0],
        comment: 'new list',
        enabled: true,
      ));

      // Local state update — no re-fetch
      expect(viewModel.whitelistAdlists.length, initialCount + 1);
      expect(
        viewModel.whitelistAdlists.last.address,
        'https://new.example.com/hosts',
      );
    });

    test('updateAdlist replaces adlist locally', () async {
      await viewModel.loadAdlists.runAsync();
      final adlist = viewModel.blacklistAdlists.first;

      await viewModel.updateAdlist.runAsync(
        adlist.copyWith(comment: 'updated comment'),
      );

      // Local state update — no re-fetch
      expect(viewModel.blacklistAdlists.first.comment, 'updated comment');
    });

    test('deleteAdlist sets error on failure', () async {
      await viewModel.loadAdlists.runAsync();
      final adlist = viewModel.blacklistAdlists.first;

      fakeAdlistRepository.shouldFail = true;
      listenerCalled = false;
      try {
        await viewModel.deleteAdlist.runAsync(adlist);
      } catch (_) {}

      // deleteAdlist failure should throw
      expect(viewModel.deleteAdlist.errors.value, isNotNull);
      expect(listenerCalled, true);
    });

    group('Group Filter', () {
      test('setGroupFilter updates groupFilter and filters adlists', () async {
        await viewModel.loadAdlists.runAsync();
        listenerCalled = false;

        viewModel.setGroupFilter(0);
        expect(viewModel.groupFilter, 0);
        expect(listenerCalled, true);
      });

      test('clearGroupFilter clears the filter', () async {
        await viewModel.loadAdlists.runAsync();
        viewModel.setGroupFilter(1);
        listenerCalled = false;

        viewModel.clearGroupFilter();

        expect(viewModel.groupFilter, null);
        expect(listenerCalled, true);
      });

      test('group filter and search filter combine correctly', () async {
        await viewModel.loadAdlists.runAsync();

        viewModel.setGroupFilter(0);
        viewModel.onSearch('blocklist');

        // All blocklists have group 0, "blocklist" matches 2
        expect(viewModel.filteredBlacklistAdlists.length, 2);
      });

      test(
        'setGroupFilter with non-existent group returns empty list',
        () async {
          await viewModel.loadAdlists.runAsync();

          viewModel.setGroupFilter(999);

          expect(viewModel.filteredWhitelistAdlists.length, 0);
          expect(viewModel.filteredBlacklistAdlists.length, 0);
        },
      );

      test('group filter by group 1 filters correctly', () async {
        await viewModel.loadAdlists.runAsync();

        // Only the 3rd adlist (id=3) has groups [0, 1]
        viewModel.setGroupFilter(1);
        expect(viewModel.filteredWhitelistAdlists.length, 0);
        expect(viewModel.filteredBlacklistAdlists.length, 1);
        expect(viewModel.filteredBlacklistAdlists.first.id, 3);
      });
    });
  });
}
