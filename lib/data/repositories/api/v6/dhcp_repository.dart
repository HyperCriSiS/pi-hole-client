import 'package:pi_hole_client/data/mapper/v6/dhcp_mapper.dart';
import 'package:pi_hole_client/data/model/v6/dhcp/dhcp.dart' as legacy_dhcp;
import 'package:pi_hole_client/data/repositories/api/interfaces/dhcp_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/base_v6_sid_repository.dart';
import 'package:pi_hole_client/data/repositories/utils/call_with_retry.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pi_hole_client/domain/model/dhcp/dhcp.dart';
import 'package:result_dart/result_dart.dart';

class DhcpRepositoryV6 extends BaseV6SidRepository implements DhcpRepository {
  DhcpRepositoryV6({
    required PiholeV6Service service,
    required super.sessionCache,
  }) : _service = service;

  final PiholeV6Service _service;

  @override
  Future<Result<List<DhcpLease>>> fetchDhcpLeases() async {
    return runWithResultRetry<List<DhcpLease>>(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final result = await _service.getDhcpLeases();
        return result.map(
          (e) => legacy_dhcp.Dhcp.fromJson(e.toJson()).toDomain(),
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<Unit>> deleteDhcpLeaseByIp(String ip) async {
    return runWithResultRetry<Unit>(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final result = await _service.deleteDhcpLease(ip: ip);
        return result.map((_) => unit);
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }
}
