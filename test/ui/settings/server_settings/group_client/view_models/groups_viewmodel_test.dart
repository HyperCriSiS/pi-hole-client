import 'dart:async';

import 'package:command_it/command_it.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/domain/model/group/group.dart';
import 'package:result_dart/result_dart.dart';
import 'package:pi_hole_client/domain/model/enums.dart';
import 'package:pi_hole_client/ui/settings/server_settings/group_client/view_models/groups_viewmodel.dart';

import '../../../../../../testing/fakes/repositories/api/fake_group_repository.dart';

void main() {
  group('GroupsViewModel', () {
    late bool listenerCalled;
    late GroupsViewModel viewModel;
    late FakeGroupRepository fakeGroupRepository;

    setUp(() {
      Command.globalExceptionHandler = (_, _) {};
      fakeGroupRepository = FakeGroupRepository();
      viewModel = GroupsViewModel(groupRepository: fakeGroupRepository);
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
      expect(viewModel.groups, []);
      expect(viewModel.filteredGroups, []);
      expect(viewModel.searchTerm, '');
      expect(viewModel.searchMode, false);
      expect(viewModel.groupItems, {});
      expect(listenerCalled, false);
    });


    test('first groups load remains loading until a successful empty result', () async {
      final pending = Completer<Result<List<Group>>>();
      fakeGroupRepository.fetchGroupsOverride = () => pending.future;

      expect(viewModel.loadingStatus, LoadStatus.loading);
      expect(viewModel.hasSuccessfulLoad, isFalse);
      expect(viewModel.groups, isEmpty);

      final firstLoad = viewModel.loadGroups.runAsync();
      expect(viewModel.loadingStatus, LoadStatus.loading);
      expect(viewModel.hasSuccessfulLoad, isFalse);

      pending.complete(const Success<List<Group>, Exception>([]));
      await firstLoad;
      expect(viewModel.loadingStatus, LoadStatus.loaded);
      expect(viewModel.hasSuccessfulLoad, isTrue);
      expect(viewModel.groups, isEmpty);
      expect(viewModel.isRevalidating, isFalse);
    });

    test('failed initial groups load shows error until manual recovery', () async {
      fakeGroupRepository.shouldFail = true;
      expect(viewModel.loadingStatus, LoadStatus.loading);

      await expectLater(
        viewModel.loadGroups.runAsync(),
        throwsA(isA<Exception>()),
      );
      expect(viewModel.loadingStatus, LoadStatus.error);
      expect(viewModel.hasSuccessfulLoad, isFalse);
      expect(viewModel.hasRevalidationError, isFalse);

      fakeGroupRepository.shouldFail = false;
      final pending = Completer<Result<List<Group>>>();
      fakeGroupRepository.fetchGroupsOverride = () => pending.future;
      final recovery = viewModel.loadGroups.runAsync();
      expect(viewModel.loadingStatus, LoadStatus.loading);

      pending.complete(const Success<List<Group>, Exception>([]));
      await recovery;
      expect(viewModel.loadingStatus, LoadStatus.loaded);
      expect(viewModel.groups, isEmpty);
      expect(viewModel.hasRevalidationError, isFalse);
    });

    test('retains successful cache during refresh, failure and recovery', () async {
      await viewModel.loadGroups.runAsync();
      expect(viewModel.hasSuccessfulLoad, isTrue);
      final prior = List<Group>.of(viewModel.groups);
      final pending = Completer<Result<List<Group>>>();
      fakeGroupRepository.fetchGroupsOverride = () => pending.future;

      final refresh = viewModel.loadGroups.runAsync();
      expect(viewModel.loadingStatus, LoadStatus.loaded);
      expect(viewModel.isRevalidating, isTrue);
      expect(viewModel.groups, prior);

      pending.complete(Failure(Exception('refresh unavailable')));
      await expectLater(refresh, throwsA(isA<Exception>()));

      expect(viewModel.loadingStatus, LoadStatus.loaded);
      expect(viewModel.hasRevalidationError, isTrue);
      expect(viewModel.isRevalidating, isFalse);
      expect(viewModel.groups, prior);

      fakeGroupRepository.fetchGroupsOverride = null;
      await viewModel.loadGroups.runAsync();
      expect(viewModel.groups, prior);
      expect(viewModel.hasRevalidationError, isFalse);
    });

    test('successful empty cache is retained after refresh failure', () async {
      fakeGroupRepository.fetchGroupsOverride =
          () async => const Success<List<Group>, Exception>([]);
      await viewModel.loadGroups.runAsync();
      expect(viewModel.groups, isEmpty);
      expect(viewModel.hasSuccessfulLoad, isTrue);

      fakeGroupRepository.fetchGroupsOverride =
          () async => Failure(Exception('offline'));
      await expectLater(viewModel.loadGroups.runAsync(), throwsA(isA<Exception>()));
      expect(viewModel.loadingStatus, LoadStatus.loaded);
      expect(viewModel.groups, isEmpty);
      expect(viewModel.hasRevalidationError, isTrue);
    });


    group('stale refresh overlapping successful mutations', () {
      for (final operation in ['add', 'update', 'delete']) {
        test('keeps successful group $operation over an older read', () async {
          await viewModel.loadGroups.runAsync();
          final original = List<Group>.of(viewModel.groups);
          final stale = Completer<Result<List<Group>>>();
          fakeGroupRepository.fetchGroupsOverride = () => stale.future;
          final refresh = viewModel.loadGroups.runAsync();

          if (operation == 'add') {
            await viewModel.addGroup.runAsync((
              name: 'created',
              comment: 'new group',
              enabled: true,
            ));
          } else if (operation == 'update') {
            await viewModel.updateGroup.runAsync((
              name: 'test',
              comment: 'changed while refreshing',
              enabled: true,
            ));
          } else {
            await viewModel.deleteGroup.runAsync(original.last);
          }

          final newer = List<Group>.of(viewModel.groups);
          expect(newer, isNot(equals(original)));
          stale.complete(Success(original));
          await refresh;

          expect(viewModel.groups, newer);
          expect(viewModel.filteredGroups, newer);
          expect(viewModel.hasSuccessfulLoad, isTrue);
          expect(viewModel.loadGroups.errors.value, isNull);
        });
      }
    });

    test('failed group mutation does not invalidate a legitimate refresh', () async {
      await viewModel.loadGroups.runAsync();
      final stale = Completer<Result<List<Group>>>();
      fakeGroupRepository.fetchGroupsOverride = () => stale.future;
      final refresh = viewModel.loadGroups.runAsync();

      fakeGroupRepository.shouldFail = true;
      await expectLater(
        viewModel.addGroup.runAsync((
          name: 'failed',
          comment: null,
          enabled: true,
        )),
        throwsA(isA<Exception>()),
      );
      stale.complete(const Success<List<Group>, Exception>([]));
      await refresh;

      expect(viewModel.groups, isEmpty);
      expect(viewModel.filteredGroups, isEmpty);
      expect(viewModel.hasSuccessfulLoad, isTrue);
      expect(viewModel.loadGroups.errors.value, isNull);
    });

    test('older empty refresh cannot remove a newly added group', () async {
      fakeGroupRepository.fetchGroupsOverride =
          () async => const Success<List<Group>, Exception>([]);
      await viewModel.loadGroups.runAsync();
      expect(viewModel.groups, isEmpty);

      final stale = Completer<Result<List<Group>>>();
      fakeGroupRepository.fetchGroupsOverride = () => stale.future;
      final refresh = viewModel.loadGroups.runAsync();
      await viewModel.addGroup.runAsync((
        name: 'new',
        comment: null,
        enabled: true,
      ));
      final newer = List<Group>.of(viewModel.groups);
      stale.complete(const Success<List<Group>, Exception>([]));
      await refresh;

      expect(viewModel.groups, newer);
      expect(viewModel.groups, hasLength(1));
      expect(viewModel.hasSuccessfulLoad, isTrue);
    });

    test('setSearchMode updates search mode', () {
      viewModel.setSearchMode(true);
      expect(viewModel.searchMode, true);
      expect(listenerCalled, true);
    });

    test('loadGroups fetches groups', () async {
      await viewModel.loadGroups.runAsync();
      expect(viewModel.groups.length, 2);
      expect(viewModel.filteredGroups.length, 2);
      expect(viewModel.loadingStatus, LoadStatus.loaded);
      expect(listenerCalled, true);
    });

    test('loadGroups sets error on failure', () async {
      fakeGroupRepository.shouldFail = true;
      try {
        await viewModel.loadGroups.runAsync();
      } catch (_) {}
      expect(viewModel.loadingStatus, LoadStatus.error);
      expect(listenerCalled, true);
    });

    test('groupItems returns correct map', () async {
      await viewModel.loadGroups.runAsync();
      expect(viewModel.groupItems, {0: 'Default', 5: 'test'});
    });

    test('onSearch filters groups based on search term', () async {
      await viewModel.loadGroups.runAsync();
      listenerCalled = false;

      viewModel.onSearch('default');
      expect(viewModel.filteredGroups.length, 1);
      expect(viewModel.filteredGroups.first.name, 'Default');
      expect(listenerCalled, true);
    });

    test('onSearch matches comment', () async {
      await viewModel.loadGroups.runAsync();
      listenerCalled = false;

      viewModel.onSearch('default group');
      expect(viewModel.filteredGroups.length, 1);
      expect(viewModel.filteredGroups.first.id, 0);
      expect(listenerCalled, true);
    });

    test('onSearch is case-insensitive', () async {
      await viewModel.loadGroups.runAsync();
      listenerCalled = false;

      viewModel.onSearch('TEST');
      expect(viewModel.filteredGroups.length, 1);
      expect(listenerCalled, true);
    });

    test('deleteGroup removes group from the list', () async {
      await viewModel.loadGroups.runAsync();
      final group = viewModel.groups.last;
      listenerCalled = false;

      await viewModel.deleteGroup.runAsync(group);
      expect(viewModel.groups.where((g) => g.id == group.id), isEmpty);
      expect(listenerCalled, true);
    });

    test('addGroup appends group to list without reloading', () async {
      await viewModel.loadGroups.runAsync();
      listenerCalled = false;

      await viewModel.addGroup.runAsync((
        name: 'new-group',
        comment: 'new comment',
        enabled: true,
      ));

      expect(viewModel.groups.length, 3);
      expect(viewModel.groups.any((g) => g.name == 'new-group'), isTrue);
      expect(viewModel.loadingStatus, LoadStatus.loaded);
      expect(listenerCalled, true);
    });

    test('updateGroup updates group in list without reloading', () async {
      await viewModel.loadGroups.runAsync();
      listenerCalled = false;

      await viewModel.updateGroup.runAsync((
        name: 'test',
        comment: 'updated comment',
        enabled: false,
      ));

      // FakeGroupRepository.updateGroup returns id:5 with the new values
      final updated = viewModel.groups.firstWhere((g) => g.id == 5);
      expect(updated.comment, 'updated comment');
      expect(updated.enabled, false);
      expect(viewModel.groups.length, 2);
      expect(viewModel.loadingStatus, LoadStatus.loaded);
      expect(listenerCalled, true);
    });

    test('deleteGroup sets error on failure', () async {
      await viewModel.loadGroups.runAsync();
      final group = viewModel.groups.last;

      fakeGroupRepository.shouldFail = true;
      listenerCalled = false;
      try {
        await viewModel.deleteGroup.runAsync(group);
      } catch (_) {}

      expect(viewModel.deleteGroup.errors.value, isNotNull);
      expect(listenerCalled, true);
    });
  });
}
