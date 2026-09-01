import 'package:pi_hole_client/data/mapper/v6/dns_mapper.dart';
import 'package:pi_hole_client/data/model/v6/dns/dns.dart' as legacy_dns;
import 'package:pi_hole_client/data/repositories/api/interfaces/dns_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/base_v6_sid_repository.dart';
import 'package:pi_hole_client/data/repositories/utils/call_with_retry.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pi_hole_client/domain/model/dns/dns.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart' show SetBlockingRequest;
import 'package:result_dart/result_dart.dart';

class DnsRepositoryV6 extends BaseV6SidRepository implements DnsRepository {
  DnsRepositoryV6({
    required PiholeV6Service service,
    required super.sessionCache,
  }) : _service = service;

  final PiholeV6Service _service;

  @override
  Future<Result<Blocking>> fetchBlockingStatus({
    bool skipRenewal = false,
  }) async {
    return runWithResultRetry<Blocking>(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final result = await _service.getDnsBlocking();
        return result.map(
          (e) => legacy_dns.Blocking.fromJson(e.toJson()).toDomain(),
        );
      },
      onRetry: skipRenewal ? null : (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<Blocking>> enableBlocking() async {
    return _updateBlockingStatus(true);
  }

  @override
  Future<Result<Blocking>> disableBlocking(int timer) async {
    return _updateBlockingStatus(false, timer: timer);
  }

  Future<Result<Blocking>> _updateBlockingStatus(
    bool enabled, {
    int? timer,
  }) async {
    return runWithResultRetry<Blocking>(
      action: () async {
        final sid = await getSid();
        final time = enabled ? null : timer;
        _service.setSid(sid);
        final result = await _service.setDnsBlocking(
          request: SetBlockingRequest(blocking: enabled, timer: time),
        );
        return result.map(
          (e) => legacy_dns.Blocking.fromJson(e.toJson()).toDomain(),
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }
}
