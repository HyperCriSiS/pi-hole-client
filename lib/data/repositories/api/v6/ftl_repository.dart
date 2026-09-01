import 'package:pi_hole_client/data/mapper/v6/ftl_mapper.dart';
import 'package:pi_hole_client/data/model/v6/ftl/host.dart' as legacy_host;
import 'package:pi_hole_client/data/model/v6/ftl/messages.dart'
    as legacy_messages;
import 'package:pi_hole_client/data/model/v6/ftl/metrics.dart'
    as legacy_metrics;
import 'package:pi_hole_client/data/model/v6/ftl/sensors.dart'
    as legacy_sensors;
import 'package:pi_hole_client/data/model/v6/ftl/system.dart' as legacy_system;
import 'package:pi_hole_client/data/model/v6/ftl/version.dart' as legacy;
import 'package:pi_hole_client/data/repositories/api/interfaces/ftl_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/base_v6_sid_repository.dart';
import 'package:pi_hole_client/data/repositories/utils/call_with_retry.dart';
import 'package:pi_hole_client/data/services/api/pihole_v6_api_client.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pi_hole_client/domain/model/ftl/client.dart';
import 'package:pi_hole_client/domain/model/ftl/ftl.dart';
import 'package:pi_hole_client/domain/model/ftl/host.dart';
import 'package:pi_hole_client/domain/model/ftl/message.dart';
import 'package:pi_hole_client/domain/model/ftl/metrics.dart';
import 'package:pi_hole_client/domain/model/ftl/pihole_server.dart';
import 'package:pi_hole_client/domain/model/ftl/sensor.dart';
import 'package:pi_hole_client/domain/model/ftl/system.dart';
import 'package:pi_hole_client/domain/model/ftl/version.dart';
import 'package:result_dart/result_dart.dart';

class FtlRepositoryV6 extends BaseV6SidRepository implements FtlRepository {
  FtlRepositoryV6({
    required PiholeV6ApiClient client,
    required PiholeV6Service service,
    required super.sessionCache,
  }) : _client = client,
       _service = service;

  final PiholeV6ApiClient _client;
  final PiholeV6Service _service;

  @override
  Future<Result<FtlClient>> fetchInfoClient() {
    return runWithResultRetry(
      action: () async {
        final sid = await getSid();
        final result = await _client.getInfoClient(sid);
        return result.map((e) => e.toDomain());
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<FtlInfo>> fetchInfoFtl() {
    return runWithResultRetry(
      action: () async {
        final sid = await getSid();
        final result = await _client.getInfoFtl(sid);
        return result.map((e) => e.toDomain());
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<FtlHost>> fetchInfoHost() {
    return runWithResultRetry(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final result = await _service.getInfoHost();
        return result.map(
          (e) => legacy_host.InfoHost.fromJson(e.toJson()).toDomain(),
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<List<FtlMessage>>> fetchInfoMessages() {
    return runWithResultRetry(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final result = await _service.getInfoMessages();
        return result.map(
          (e) => legacy_messages.InfoMessages.fromJson(e.toJson()).toDomain(),
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<Unit>> deleteInfoMessage(int messageId) {
    return runWithResultRetry(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        return _service.deleteInfoMessage(messageId: messageId);
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<FtlDnsMetrics>> fetchInfoMetrics() {
    return runWithResultRetry(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final result = await _service.getInfoMetrics();
        return result.map(
          (e) => legacy_metrics.InfoMetrics.fromJson(e.toJson()).toDomain(),
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<FtlSensor>> fetchInfoSensors() {
    return runWithResultRetry(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final result = await _service.getInfoSensors();
        return result.map(
          (e) => legacy_sensors.InfoSensors.fromJson(e.toJson()).toDomain(),
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<FtlSystem>> fetchInfoSystem() {
    return runWithResultRetry(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final result = await _service.getInfoSystem();
        return result.map(
          (e) => legacy_system.InfoSystem.fromJson(e.toJson()).toDomain(),
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<FtlVersion>> fetchInfoVersion() {
    return runWithResultRetry(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final result = await _service.getInfoVersion();
        return result.map(
          (e) => legacy.InfoVersion.fromJson(e.toJson()).toDomain(),
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<PiholeServer>> fetchAllServerInfo() {
    return runWithResultRetry(
      action: () async {
        final result = await Future.wait([
          fetchInfoHost(),
          fetchInfoSensors(),
          fetchInfoSystem(),
          fetchInfoVersion(),
        ]);

        return Success(
          PiholeServer(
            host: (result[0] as Result<FtlHost>).getOrThrow(),
            sensor: (result[1] as Result<FtlSensor>).getOrThrow(),
            system: (result[2] as Result<FtlSystem>).getOrThrow(),
            version: (result[3] as Result<FtlVersion>).getOrThrow(),
          ),
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }
}
