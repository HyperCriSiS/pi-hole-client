import 'package:pi_hole_client/data/mapper/v6/adlist_mapper.dart';
import 'package:pi_hole_client/data/mapper/v6/list_search_mapper.dart';
import 'package:pi_hole_client/data/model/v6/lists/lists.dart' as legacy_lists;
import 'package:pi_hole_client/data/model/v6/lists/search.dart' as legacy_search;
import 'package:pi_hole_client/data/repositories/api/interfaces/adlist_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/base_v6_sid_repository.dart';
import 'package:pi_hole_client/data/repositories/utils/call_with_retry.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pi_hole_client/domain/model/enums.dart';
import 'package:pi_hole_client/domain/model/list/adlist.dart';
import 'package:pi_hole_client/domain/model/list/list_search_result.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart';
import 'package:result_dart/result_dart.dart';

class AdlistRepositoryV6 extends BaseV6SidRepository
    implements AdListRepository {
  AdlistRepositoryV6({
    required PiholeV6Service service,
    required super.sessionCache,
  }) : _service = service;

  final PiholeV6Service _service;

  @override
  Future<Result<List<Adlist>>> fetchAdlists({
    String? adlist,
    ListType? type,
  }) async {
    return runWithResultRetry<List<Adlist>>(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final result = adlist == null
            ? await _service.getAllLists(type: type?.name)
            : await _service.getLists(list: adlist, type: type?.name);
        return result.map(
          (e) => legacy_lists.Lists.fromJson(e.toJson()).toDomain(),
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<Adlist>> addAdlist(
    String address,
    ListType type, {
    List<int> groups = const [0],
    String? comment = '',
    bool? enabled = true,
  }) async {
    return runWithResultRetry<Adlist>(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final result = await _service.addList(
          type: type.name,
          body: ListsPost(
            address: StringOrList.fromString(address),
            groups: groups,
            comment: comment,
            enabled: enabled,
          ),
        );
        return result.map(
          (e) => legacy_lists.Lists.fromJson(e.toJson()).toSingleDomain(),
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<Adlist>> updateAdlist(
    String address,
    ListType type, {
    List<int> groups = const [0],
    String? comment = '',
    bool? enabled = true,
  }) async {
    return runWithResultRetry<Adlist>(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final result = await _service.replaceList(
          list: address,
          type: type.name,
          body: ListsPut(
            type: _generatedType(type),
            groups: groups,
            comment: comment,
            enabled: enabled,
          ),
        );
        return result.map(
          (e) => legacy_lists.Lists.fromJson(e.toJson()).toSingleDomain(),
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<Unit>> deleteAdlist(String address, ListType type) async {
    return runWithResultRetry<Unit>(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        return _service.deleteList(list: address, type: type.name);
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<ListSearchResult>> searchLists({
    required String domain,
    bool? partial,
    int? limit,
  }) async {
    return runWithResultRetry<ListSearchResult>(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final result = await _service.searchDomainInLists(
          domain: domain,
          n: limit,
          partial: partial,
        );
        return result.map(
          (e) => legacy_search.Search.fromJson(e.toJson()).toDomain(),
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  ListsPutTypeEnum? _generatedType(ListType type) {
    return switch (type) {
      ListType.allow => ListsPutTypeEnum.allow,
      ListType.block => ListsPutTypeEnum.block,
      ListType.unknown => null,
    };
  }
}
