import 'package:command_it/command_it.dart';
import 'package:flutter/foundation.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/adlist_repository.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/domain_repository.dart';
import 'package:pi_hole_client/domain/model/domain/domain.dart';
import 'package:pi_hole_client/domain/model/list/adlist.dart';
import 'package:pi_hole_client/domain/model/list/list_search_result.dart';
import 'package:result_dart/result_dart.dart';

class FindDomainsInListsViewModel extends ChangeNotifier {
  FindDomainsInListsViewModel({
    required AdListRepository adListRepository,
    required DomainRepository domainRepository,
  }) : _adListRepository = adListRepository,
       _domainRepository = domainRepository {
    searchLists = Command.createAsyncNoResult(_searchLists);
    deleteDomain = Command.createAsyncNoResult<Domain>(_deleteDomain);
    deleteAdlist = Command.createAsyncNoResult<Adlist>(_deleteAdlist);

    searchLists.addListener(notifyListeners);
    searchLists.isRunning.addListener(notifyListeners);
    searchLists.errors.addListener(notifyListeners);
    deleteDomain.addListener(notifyListeners);
    deleteDomain.errors.addListener(notifyListeners);
    deleteAdlist.addListener(notifyListeners);
    deleteAdlist.errors.addListener(notifyListeners);
  }

  final AdListRepository _adListRepository;
  final DomainRepository _domainRepository;

  // --- Commands ---
  late final Command<({String domain, bool partial, int limit}), void>
  searchLists;
  late final Command<Domain, void> deleteDomain;
  late final Command<Adlist, void> deleteAdlist;

  // --- State ---
  ListSearchResult? _searchResult;
  List<Domain> _domainResults = [];
  List<GravityMatch> _gravityMatches = [];
  bool _hasSearched = false;
  String? _errorMessage;
  // Only results for exactly these successful search parameters can be reused.
  ({String domain, bool partial, int limit})? _lastSuccessfulQuery;
  // Independent revisions keep an older search from resurrecting an entry
  // committed or edited locally, and keep late writes scoped to their query.
  int _mutationRevision = 0;
  int _queryGeneration = 0;

  // --- Getters ---
  ListSearchResult? get searchResult => _searchResult;
  List<Domain> get domainResults => _domainResults;
  List<GravityMatch> get gravityMatches => _gravityMatches;
  bool get hasSearched => _hasSearched;
  String? get errorMessage => _errorMessage;

  bool get isSearching => searchLists.isRunning.value;
  bool get hasReusableResults =>
      _searchResult != null && _lastSuccessfulQuery != null;

  // --- Command implementations ---
  Future<void> _searchLists(
    ({String domain, bool partial, int limit}) params,
  ) async {
    _errorMessage = null;
    _hasSearched = true;
    if (_lastSuccessfulQuery != params) {
      ++_queryGeneration;
      // Never show an earlier domain/partial/limit result for a new query.
      _lastSuccessfulQuery = null;
      _searchResult = null;
      _domainResults = [];
      _gravityMatches = [];
    }
    notifyListeners();

    final queryAtStart = _queryGeneration;
    final mutationAtStart = _mutationRevision;
    final result = await _adListRepository.searchLists(
      domain: params.domain,
      partial: params.partial,
      limit: params.limit,
    );
    switch (result) {
      case Success():
        // A result predating a local deletion/edit or a different query
        // is not authoritative for the current visible search.
        if (queryAtStart != _queryGeneration ||
            mutationAtStart != _mutationRevision) {
          return;
        }
        final data = result.getOrNull();
        _searchResult = data;
        _lastSuccessfulQuery = params;
        _domainResults = data.domains;
        _gravityMatches = data.gravityMatches;
        notifyListeners();
      case Failure():
        throw result.exceptionOrNull();
    }
  }

  void setSearchError(String message) {
    _errorMessage = message;
    // An identical search may retain a successful snapshot, including empty
    // results. Different search parameters cleared that snapshot on submit.
    if (!hasReusableResults) {
      _searchResult = null;
      _domainResults = [];
      _gravityMatches = [];
    }
    notifyListeners();
  }

  Future<void> _deleteDomain(Domain domain) async {
    final queryAtStart = _queryGeneration;
    final result = await _domainRepository.deleteDomain(
      domain.type,
      domain.kind,
      domain.punyCode,
    );
    switch (result) {
      case Success():
        // A completed delete from an earlier query must not edit a new query.
        if (queryAtStart != _queryGeneration ||
            !_domainResults.any((d) => d.id == domain.id)) {
          return;
        }
        ++_mutationRevision;
        _domainResults = _domainResults
            .where((d) => d.id != domain.id)
            .toList();
        notifyListeners();
      case Failure():
        throw result.exceptionOrNull();
    }
  }

  Future<void> _deleteAdlist(Adlist adlist) async {
    final queryAtStart = _queryGeneration;
    final result = await _adListRepository.deleteAdlist(
      adlist.address,
      adlist.type,
    );
    switch (result) {
      case Success():
        if (queryAtStart != _queryGeneration ||
            !_gravityMatches.any((m) => m.adlist.id == adlist.id)) {
          return;
        }
        ++_mutationRevision;
        _gravityMatches = _gravityMatches
            .where((m) => m.adlist.id != adlist.id)
            .toList();
        notifyListeners();
      case Failure():
        throw result.exceptionOrNull();
    }
  }

  // --- State mutation (details screen update callbacks) ---
  void updateDomainInResults(Domain updated) {
    if (!_domainResults.any((d) => d.id == updated.id && d != updated)) {
      return;
    }
    ++_mutationRevision;
    _domainResults = _domainResults
        .map((d) => d.id == updated.id ? updated : d)
        .toList();
    notifyListeners();
  }

  void updateAdlistInResults(Adlist updated) {
    final addr = updated.address.trim().toLowerCase();
    if (!_gravityMatches.any(
      (m) =>
          (m.adlist.id == updated.id ||
              m.adlist.address.trim().toLowerCase() == addr) &&
          m.adlist != updated,
    )) {
      return;
    }
    ++_mutationRevision;
    _gravityMatches = _gravityMatches.map((m) {
      if (m.adlist.id == updated.id ||
          m.adlist.address.trim().toLowerCase() == addr) {
        return GravityMatch(adlist: updated, matchedDomain: m.matchedDomain);
      }
      return m;
    }).toList();
    notifyListeners();
  }

  @override
  void dispose() {
    searchLists.removeListener(notifyListeners);
    searchLists.isRunning.removeListener(notifyListeners);
    searchLists.errors.removeListener(notifyListeners);
    deleteDomain.removeListener(notifyListeners);
    deleteDomain.errors.removeListener(notifyListeners);
    deleteAdlist.removeListener(notifyListeners);
    deleteAdlist.errors.removeListener(notifyListeners);
    searchLists.dispose();
    deleteDomain.dispose();
    deleteAdlist.dispose();
    super.dispose();
  }
}
