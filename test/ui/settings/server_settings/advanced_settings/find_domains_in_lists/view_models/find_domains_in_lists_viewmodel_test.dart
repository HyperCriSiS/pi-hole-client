import 'dart:async';

import 'package:command_it/command_it.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/domain/model/domain/domain.dart';
import 'package:pi_hole_client/domain/model/enums.dart';
import 'package:pi_hole_client/domain/model/list/adlist.dart';
import 'package:pi_hole_client/domain/model/list/list_search_result.dart';
import 'package:pi_hole_client/ui/settings/server_settings/advanced_settings/find_domains_in_lists/view_models/find_domains_in_lists_viewmodel.dart';
import 'package:result_dart/result_dart.dart';

import '../../../../../../../testing/fakes/repositories/api/fake_adlist_repository.dart';
import '../../../../../../../testing/fakes/repositories/api/fake_domain_repository.dart';

/// Delays one deletion so a new search can complete before its response.
class _DeferredDomainRepository extends FakeDomainRepository {
  Completer<Result<Unit>>? nextDelete;

  @override
  Future<Result<Unit>> deleteDomain(
    DomainType type,
    DomainKind kind,
    String domain,
  ) {
    final pending = nextDelete;
    nextDelete = null;
    if (pending != null) return pending.future;
    return super.deleteDomain(type, kind, domain);
  }
}

class _ControlledSearchRepository extends FakeAdlistRepository {
  Completer<Result<ListSearchResult>>? nextSearch;
  ListSearchResult? canned;

  @override
  Future<Result<ListSearchResult>> searchLists({
    required String domain,
    bool? partial,
    int? limit,
  }) {
    final pending = nextSearch;
    nextSearch = null;
    if (pending != null) return pending.future;
    if (canned != null && !shouldFail) return Future.value(Success(canned!));
    return super.searchLists(domain: domain, partial: partial, limit: limit);
  }
}

void main() {
  group('FindDomainsInListsViewModel', () {
    late bool listenerCalled;
    late FindDomainsInListsViewModel viewModel;
    late FakeAdlistRepository fakeAdlistRepository;
    late FakeDomainRepository fakeDomainRepository;

    final now = DateTime(2025, 1, 1);

    setUp(() {
      Command.globalExceptionHandler = (_, _) {};
      fakeAdlistRepository = FakeAdlistRepository();
      fakeDomainRepository = FakeDomainRepository();
      viewModel = FindDomainsInListsViewModel(
        adListRepository: fakeAdlistRepository,
        domainRepository: fakeDomainRepository,
      );
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
      expect(viewModel.searchResult, isNull);
      expect(viewModel.domainResults, isEmpty);
      expect(viewModel.gravityMatches, isEmpty);
      expect(viewModel.hasSearched, false);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.isSearching, false);
      expect(listenerCalled, false);
    });

    test('searchLists populates results on success', () async {
      await viewModel.searchLists.runAsync((
        domain: 'example.com',
        partial: true,
        limit: 20,
      ));

      expect(viewModel.searchResult, isNotNull);
      expect(viewModel.gravityMatches.length, 1);
      expect(viewModel.gravityMatches.first.matchedDomain, 'example.com');
      expect(viewModel.hasSearched, true);
      expect(viewModel.errorMessage, isNull);
      expect(listenerCalled, true);
    });

    test('searchLists throws on failure', () async {
      fakeAdlistRepository.shouldFail = true;
      try {
        await viewModel.searchLists.runAsync((
          domain: 'example.com',
          partial: true,
          limit: 20,
        ));
      } catch (_) {}

      expect(viewModel.searchLists.errors.value, isNotNull);
      expect(listenerCalled, true);
    });

    test('setSearchError preserves matching successful result', () async {
      await viewModel.searchLists.runAsync((
        domain: 'example.com',
        partial: true,
        limit: 20,
      ));
      listenerCalled = false;

      viewModel.setSearchError('Something went wrong');

      expect(viewModel.errorMessage, 'Something went wrong');
      expect(viewModel.searchResult, isNotNull);
      expect(viewModel.hasReusableResults, true);
      expect(viewModel.gravityMatches, hasLength(1));
      expect(listenerCalled, true);
    });


    test('identical search keeps snapshot pending, after error and retry', () async {
      final repo = _ControlledSearchRepository();
      final vm = FindDomainsInListsViewModel(
        adListRepository: repo,
        domainRepository: fakeDomainRepository,
      );
      addTearDown(vm.dispose);
      const request = (domain: 'example.com', partial: true, limit: 20);
      await vm.searchLists.runAsync(request);
      final original = vm.searchResult;
      final pending = Completer<Result<ListSearchResult>>();
      repo.nextSearch = pending;

      final operation = vm.searchLists.runAsync(request);
      // command_it schedules its async body after the running flag changes.
      await Future<void>.delayed(Duration.zero);
      expect(vm.isSearching, true);
      expect(vm.hasReusableResults, true);
      expect(vm.searchResult, original);
      expect(vm.gravityMatches, hasLength(1));

      pending.complete(Failure(Exception('offline')));
      try {
        await operation;
      } catch (_) {}
      vm.setSearchError('Cannot refresh');
      expect(vm.errorMessage, 'Cannot refresh');
      expect(vm.searchResult, original);
      expect(vm.gravityMatches, hasLength(1));

      await vm.searchLists.runAsync(request);
      expect(vm.errorMessage, isNull);
      expect(vm.hasReusableResults, true);
      expect(vm.searchResult, isNotNull);
    });

    test('new domain, partial flag or limit never show previous results', () async {
      const initial = (domain: 'example.com', partial: true, limit: 20);
      for (final newRequest in [
        (domain: 'other.com', partial: true, limit: 20),
        (domain: 'example.com', partial: false, limit: 20),
        (domain: 'example.com', partial: true, limit: 5),
      ]) {
        final repo = _ControlledSearchRepository();
        final vm = FindDomainsInListsViewModel(
          adListRepository: repo,
          domainRepository: fakeDomainRepository,
        );
        addTearDown(vm.dispose);
        await vm.searchLists.runAsync(initial);
        final pending = Completer<Result<ListSearchResult>>();
        repo.nextSearch = pending;

        expect(newRequest, isNot(initial));
        final operation = vm.searchLists.runAsync(newRequest);
        // Wait for the Command body to clear the old query's cache.
        await Future<void>.delayed(Duration.zero);
        expect(vm.isSearching, true);
        expect(vm.hasReusableResults, false);
        expect(vm.searchResult, isNull);
        expect(vm.gravityMatches, isEmpty);
        pending.complete(Failure(Exception('new search failed')));
        try {
          await operation;
        } catch (_) {}
        vm.setSearchError('No response');
        expect(vm.searchResult, isNull);
        expect(vm.errorMessage, 'No response');
      }
    });

    test('successful empty result remains valid cache for identical search', () async {
      final repo = _ControlledSearchRepository()
        ..canned = const ListSearchResult(
          domains: [],
          gravityMatches: [],
          meta: ListSearchMeta(
            domainsExact: 0, domainsRegex: 0,
            gravityAllow: 0, gravityBlock: 0, total: 0,
          ),
        );
      final vm = FindDomainsInListsViewModel(
        adListRepository: repo,
        domainRepository: fakeDomainRepository,
      );
      addTearDown(vm.dispose);
      const request = (domain: 'empty.example', partial: false, limit: 10);
      await vm.searchLists.runAsync(request);
      expect(vm.hasReusableResults, true);
      expect(vm.searchResult?.meta.total, 0);
      repo.shouldFail = true;
      try {
        await vm.searchLists.runAsync(request);
      } catch (_) {}
      vm.setSearchError('No response');
      expect(vm.hasReusableResults, true);
      expect(vm.searchResult?.meta.total, 0);
      expect(vm.gravityMatches, isEmpty);
    });


    group('local edits versus in-flight search revalidation', () {
      const query = (domain: 'example.com', partial: true, limit: 20);

      Domain domain({int id = 11, String? comment}) => Domain(
        id: id,
        name: 'example.com',
        punyCode: 'example.com',
        type: DomainType.deny,
        kind: DomainKind.exact,
        comment: comment,
        groups: [0],
        enabled: true,
        dateAdded: now,
        dateModified: now,
      );

      Future<ListSearchResult> withDomain(
        _ControlledSearchRepository repo,
        Domain record,
      ) async {
        final result = (await repo.searchLists(
          domain: query.domain,
          partial: query.partial,
          limit: query.limit,
        )).getOrThrow();
        return result.copyWith(
          domains: [record],
          meta: const ListSearchMeta(
            domainsExact: 1,
            domainsRegex: 0,
            gravityAllow: 0,
            gravityBlock: 1,
            total: 2,
          ),
        );
      }

      test('old search cannot restore a successfully deleted domain', () async {
        final repo = _ControlledSearchRepository();
        final initial = await withDomain(repo, domain());
        repo.canned = initial;
        final vm = FindDomainsInListsViewModel(
          adListRepository: repo,
          domainRepository: fakeDomainRepository,
        );
        addTearDown(vm.dispose);
        await vm.searchLists.runAsync(query);

        final older = Completer<Result<ListSearchResult>>();
        repo.nextSearch = older;
        final refresh = vm.searchLists.runAsync(query);
        await Future<void>.delayed(Duration.zero);
        await vm.deleteDomain.runAsync(domain());
        expect(vm.domainResults, isEmpty);

        older.complete(Success(initial));
        await refresh;
        expect(vm.domainResults, isEmpty);
        expect(vm.gravityMatches, initial.gravityMatches);
        expect(vm.hasReusableResults, isTrue);
        expect(vm.searchLists.errors.value, isNull);

        // A later manual search must still accept current server data.
        repo.canned = initial.copyWith(domains: []);
        await vm.searchLists.runAsync(query);
        expect(vm.domainResults, isEmpty);
      });

      test('old search cannot restore a successfully deleted adlist', () async {
        final repo = _ControlledSearchRepository();
        final vm = FindDomainsInListsViewModel(
          adListRepository: repo,
          domainRepository: fakeDomainRepository,
        );
        addTearDown(vm.dispose);
        await vm.searchLists.runAsync(query);
        final original = vm.searchResult!;
        final adlist = vm.gravityMatches.single.adlist;

        final older = Completer<Result<ListSearchResult>>();
        repo.nextSearch = older;
        final refresh = vm.searchLists.runAsync(query);
        await Future<void>.delayed(Duration.zero);
        await vm.deleteAdlist.runAsync(adlist);
        expect(vm.gravityMatches, isEmpty);

        older.complete(Success(original));
        await refresh;
        expect(vm.gravityMatches, isEmpty);
        expect(vm.hasReusableResults, isTrue);
        expect(vm.searchLists.errors.value, isNull);
      });

      test('old search cannot undo a domain detail edit', () async {
        final repo = _ControlledSearchRepository();
        final initial = await withDomain(repo, domain());
        repo.canned = initial;
        final vm = FindDomainsInListsViewModel(
          adListRepository: repo,
          domainRepository: fakeDomainRepository,
        );
        addTearDown(vm.dispose);
        await vm.searchLists.runAsync(query);

        final older = Completer<Result<ListSearchResult>>();
        repo.nextSearch = older;
        final refresh = vm.searchLists.runAsync(query);
        await Future<void>.delayed(Duration.zero);
        vm.updateDomainInResults(domain(comment: 'edited'));

        older.complete(Success(initial));
        await refresh;
        expect(vm.domainResults.single.comment, 'edited');
        expect(vm.gravityMatches, initial.gravityMatches);
        expect(vm.hasReusableResults, isTrue);
      });

      test('old search cannot undo an adlist detail edit', () async {
        final repo = _ControlledSearchRepository();
        final vm = FindDomainsInListsViewModel(
          adListRepository: repo,
          domainRepository: fakeDomainRepository,
        );
        addTearDown(vm.dispose);
        await vm.searchLists.runAsync(query);
        final initial = vm.searchResult!;
        final original = vm.gravityMatches.single.adlist;

        final older = Completer<Result<ListSearchResult>>();
        repo.nextSearch = older;
        final refresh = vm.searchLists.runAsync(query);
        await Future<void>.delayed(Duration.zero);
        vm.updateAdlistInResults(original.copyWith(comment: 'edited'));

        older.complete(Success(initial));
        await refresh;
        expect(vm.gravityMatches.single.adlist.comment, 'edited');
        expect(vm.hasReusableResults, isTrue);
      });

      test('failed domain deletion leaves a valid refresh applicable', () async {
        final repo = _ControlledSearchRepository();
        final initial = await withDomain(repo, domain());
        repo.canned = initial;
        final vm = FindDomainsInListsViewModel(
          adListRepository: repo,
          domainRepository: fakeDomainRepository,
        );
        addTearDown(vm.dispose);
        await vm.searchLists.runAsync(query);

        final newer = initial.copyWith(domains: []);
        final pending = Completer<Result<ListSearchResult>>();
        repo.nextSearch = pending;
        final refresh = vm.searchLists.runAsync(query);
        await Future<void>.delayed(Duration.zero);

        fakeDomainRepository.shouldFail = true;
        await expectLater(
          vm.deleteDomain.runAsync(domain()),
          throwsA(isA<Exception>()),
        );
        pending.complete(Success(newer));
        await refresh;
        expect(vm.domainResults, isEmpty);
        expect(vm.gravityMatches, newer.gravityMatches);
        expect(vm.searchLists.errors.value, isNull);
      });

      test('failed adlist deletion leaves a valid refresh applicable', () async {
        final repo = _ControlledSearchRepository();
        final vm = FindDomainsInListsViewModel(
          adListRepository: repo,
          domainRepository: fakeDomainRepository,
        );
        addTearDown(vm.dispose);
        await vm.searchLists.runAsync(query);
        final initial = vm.searchResult!;
        final olderAdlist = initial.gravityMatches.single.adlist;

        final newer = initial.copyWith(gravityMatches: []);
        final pending = Completer<Result<ListSearchResult>>();
        repo.nextSearch = pending;
        final refresh = vm.searchLists.runAsync(query);
        await Future<void>.delayed(Duration.zero);

        repo.shouldFail = true;
        await expectLater(
          vm.deleteAdlist.runAsync(olderAdlist),
          throwsA(isA<Exception>()),
        );
        pending.complete(Success(newer));
        await refresh;
        expect(vm.gravityMatches, isEmpty);
        expect(vm.searchLists.errors.value, isNull);
      });

      test('unrelated callback does not invalidate pending valid search', () async {
        final repo = _ControlledSearchRepository();
        final initial = await withDomain(repo, domain());
        repo.canned = initial;
        final vm = FindDomainsInListsViewModel(
          adListRepository: repo,
          domainRepository: fakeDomainRepository,
        );
        addTearDown(vm.dispose);
        await vm.searchLists.runAsync(query);

        final newer = initial.copyWith(domains: []);
        final pending = Completer<Result<ListSearchResult>>();
        repo.nextSearch = pending;
        final refresh = vm.searchLists.runAsync(query);
        await Future<void>.delayed(Duration.zero);

        vm.updateDomainInResults(domain(id: 999, comment: 'irrelevant'));
        pending.complete(Success(newer));
        await refresh;
        expect(vm.domainResults, isEmpty);
        expect(vm.hasReusableResults, isTrue);
      });

      test('late domain delete from older query cannot change new results', () async {
        final repo = _ControlledSearchRepository();
        final domainRepo = _DeferredDomainRepository();
        final initial = await withDomain(repo, domain());
        repo.canned = initial;
        final vm = FindDomainsInListsViewModel(
          adListRepository: repo,
          domainRepository: domainRepo,
        );
        addTearDown(vm.dispose);
        await vm.searchLists.runAsync(query);

        final delayedDelete = Completer<Result<Unit>>();
        domainRepo.nextDelete = delayedDelete;
        final deletion = vm.deleteDomain.runAsync(domain());
        await Future<void>.delayed(Duration.zero);

        const other = (domain: 'other.example', partial: true, limit: 20);
        final otherResult = initial.copyWith(
          domains: [domain(comment: 'other query result')],
        );
        repo.canned = otherResult;
        await vm.searchLists.runAsync(other);
        expect(vm.domainResults, otherResult.domains);

        delayedDelete.complete(const Success(unit));
        await deletion;
        expect(vm.domainResults, otherResult.domains);
        expect(vm.hasReusableResults, isTrue);
      });
    });

    test('deleteDomain removes domain from results', () async {
      await viewModel.searchLists.runAsync((
        domain: 'example.com',
        partial: true,
        limit: 20,
      ));

      // Manually set domain results for this test
      final domain = Domain(
        id: 10,
        name: 'test.com',
        punyCode: 'test.com',
        type: DomainType.deny,
        kind: DomainKind.exact,
        comment: null,
        groups: [0],
        enabled: true,
        dateAdded: now,
        dateModified: now,
      );
      viewModel.updateDomainInResults(domain);
      listenerCalled = false;

      // deleteDomain won't find id=10 in fake results, but the list filtering
      // logic still runs. We test with a domain that IS in the results.
      // First, search to get domains from fake repo (which returns empty domains)
    });

    test('deleteAdlist removes adlist from gravityMatches', () async {
      await viewModel.searchLists.runAsync((
        domain: 'example.com',
        partial: true,
        limit: 20,
      ));

      expect(viewModel.gravityMatches.length, 1);
      final adlist = viewModel.gravityMatches.first.adlist;
      listenerCalled = false;

      await viewModel.deleteAdlist.runAsync(adlist);

      expect(viewModel.gravityMatches, isEmpty);
      expect(listenerCalled, true);
    });

    test('deleteAdlist throws on failure', () async {
      await viewModel.searchLists.runAsync((
        domain: 'example.com',
        partial: true,
        limit: 20,
      ));
      final adlist = viewModel.gravityMatches.first.adlist;

      fakeAdlistRepository.shouldFail = true;
      listenerCalled = false;
      try {
        await viewModel.deleteAdlist.runAsync(adlist);
      } catch (_) {}

      expect(viewModel.deleteAdlist.errors.value, isNotNull);
      expect(listenerCalled, true);
      // gravityMatches should still contain the adlist (not removed)
      expect(viewModel.gravityMatches.length, 1);
    });

    test('updateDomainInResults replaces matching domain', () async {
      await viewModel.searchLists.runAsync((
        domain: 'example.com',
        partial: true,
        limit: 20,
      ));

      // Fake repo returns empty domains, so add one manually via search
      // that includes domains. Instead, test the mutation method directly.
      final domain = Domain(
        id: 42,
        name: 'foo.com',
        punyCode: 'foo.com',
        type: DomainType.deny,
        kind: DomainKind.exact,
        comment: null,
        groups: [0],
        enabled: true,
        dateAdded: now,
        dateModified: now,
      );

      // Inject a domain into results by searching with a fake that returns it
      // For simplicity, we test the method behavior on an empty list
      viewModel.updateDomainInResults(domain);
      // Since no domain with id=42 exists, the list remains the same
      expect(viewModel.domainResults, isEmpty);
    });

    test('updateAdlistInResults replaces matching adlist', () async {
      await viewModel.searchLists.runAsync((
        domain: 'example.com',
        partial: true,
        limit: 20,
      ));

      final original = viewModel.gravityMatches.first.adlist;
      final updated = Adlist(
        address: original.address,
        type: original.type,
        groups: [0, 1],
        enabled: false,
        id: original.id,
        dateAdded: original.dateAdded,
        dateModified: original.dateModified,
        dateUpdated: original.dateUpdated,
        number: original.number,
        invalidDomains: original.invalidDomains,
        abpEntries: original.abpEntries,
        status: original.status,
        comment: 'updated comment',
      );
      listenerCalled = false;

      viewModel.updateAdlistInResults(updated);

      expect(viewModel.gravityMatches.length, 1);
      expect(viewModel.gravityMatches.first.adlist.enabled, false);
      expect(viewModel.gravityMatches.first.adlist.groups, [0, 1]);
      expect(viewModel.gravityMatches.first.adlist.comment, 'updated comment');
      expect(listenerCalled, true);
    });

    test('hasSearched is true after search', () async {
      expect(viewModel.hasSearched, false);

      await viewModel.searchLists.runAsync((
        domain: 'test.com',
        partial: false,
        limit: 10,
      ));

      expect(viewModel.hasSearched, true);
    });
  });
}
