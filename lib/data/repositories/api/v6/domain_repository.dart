import 'package:pi_hole_client/data/mapper/v6/domain_mapper.dart';
import 'package:pi_hole_client/data/model/v6/domains/domains.dart'
    as legacy_domains;
import 'package:pi_hole_client/data/repositories/api/interfaces/domain_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/base_v6_sid_repository.dart';
import 'package:pi_hole_client/data/repositories/utils/call_with_retry.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pi_hole_client/domain/model/domain/domain.dart';
import 'package:pi_hole_client/domain/model/enums.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart';
import 'package:result_dart/result_dart.dart';

class DomainRepositoryV6 extends BaseV6SidRepository
    implements DomainRepository {
  DomainRepositoryV6({
    required PiholeV6Service service,
    required super.sessionCache,
  }) : _service = service;

  final PiholeV6Service _service;

  @override
  Future<Result<DomainLists>> fetchAllDomains() async {
    return runWithResultRetry<DomainLists>(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final result = await _service.getAllDomains();
        return result.map(
          (e) => legacy_domains.Domains.fromJson(e.toJson()).toDomainLists(),
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<Domain>> addDomain(
    DomainType type,
    DomainKind kind,
    String domain, {
    String? comment,
    List<int>? groups = const [0],
    bool? enabled = true,
  }) async {
    return runWithResultRetry<Domain>(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final result = await _service.addDomain(
          type: type.name,
          kind: kind.name,
          body: Post(
            domain: StringOrList.fromString(domain),
            comment: comment,
            groups: groups,
            enabled: enabled,
          ),
        );
        return result.map(
          (e) => legacy_domains.Domains.fromJson(e.toJson()).toSingleDomain(),
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<Domain>> updateDomain(
    DomainType type,
    DomainKind kind,
    String domain, {
    String? comment,
    List<int>? groups = const [0],
    bool? enabled = true,
  }) async {
    return runWithResultRetry<Domain>(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final result = await _service.replaceDomain(
          type: type.name,
          kind: kind.name,
          domain: domain,
          body: ReplaceDomainRequest(
            type: _generatedType(type),
            kind: _generatedKind(kind),
            comment: comment,
            groups: groups,
            enabled: enabled,
          ),
        );
        return result.map(
          (e) => legacy_domains.Domains.fromJson(e.toJson()).toSingleDomain(),
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<Unit>> deleteDomain(
    DomainType type,
    DomainKind kind,
    String domain,
  ) async {
    return runWithResultRetry<Unit>(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        return _service.deleteDomain(
          type: type.name,
          kind: kind.name,
          domain: domain,
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  ReplaceDomainRequestTypeEnum _generatedType(DomainType type) {
    return switch (type) {
      DomainType.allow => ReplaceDomainRequestTypeEnum.allow,
      DomainType.deny => ReplaceDomainRequestTypeEnum.deny,
    };
  }

  ReplaceDomainRequestKindEnum _generatedKind(DomainKind kind) {
    return switch (kind) {
      DomainKind.exact => ReplaceDomainRequestKindEnum.exact,
      DomainKind.regex => ReplaceDomainRequestKindEnum.regex,
    };
  }
}
