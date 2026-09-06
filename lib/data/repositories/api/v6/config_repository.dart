import 'package:pi_hole_client/data/mapper/v6/config_mapper.dart';
import 'package:pi_hole_client/data/model/v6/config/config.dart' as legacy_config;
import 'package:pi_hole_client/data/repositories/api/interfaces/config_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/base_v6_sid_repository.dart';
import 'package:pi_hole_client/data/repositories/utils/call_with_retry.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pi_hole_client/domain/model/config/config.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart' as generated;
import 'package:result_dart/result_dart.dart';

class ConfigRepositoryV6 extends BaseV6SidRepository
    implements ConfigRepository {
  ConfigRepositoryV6({
    required PiholeV6Service service,
    required super.sessionCache,
  }) : _service = service;

  final PiholeV6Service _service;

  @override
  Future<Result<Config>> fetchDnsQueryLogging() async {
    return runWithResultRetry<Config>(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final result = await _service.getConfig();
        return result.map(
          (e) => legacy_config.Config.fromJson(e.toJson()).toDomain(),
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<Config>> setDnsQueryLogging(bool status) async {
    return runWithResultRetry<Config>(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final result = await _service.patchConfig(
          body: generated.GetConfig200Response(
            config: generated.ConfigConfig(
              dns: generated.ConfigConfigDns(queryLogging: status),
            ),
          ),
          restart: true,
        );
        return result.map(
          (e) => legacy_config.Config.fromJson(e.toJson()).toDomain(),
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }
}
