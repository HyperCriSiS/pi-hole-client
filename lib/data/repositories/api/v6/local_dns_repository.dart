import 'package:pi_hole_client/data/repositories/api/interfaces/cname_repository.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/local_dns_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/base_v6_sid_repository.dart';
import 'package:pi_hole_client/data/repositories/utils/call_with_retry.dart';
import 'package:pi_hole_client/data/services/api/pihole_v6_api_client.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pi_hole_client/domain/model/local_dns/cname_record.dart';
import 'package:pi_hole_client/domain/model/local_dns/local_dns.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart' as generated;
import 'package:result_dart/result_dart.dart';

class LocalDnsRepositoryV6 extends BaseV6SidRepository
    implements LocalDnsRepository, CnameRepository {
  LocalDnsRepositoryV6({
    required PiholeV6ApiClient client,
    required PiholeV6Service service,
    required super.sessionCache,
  }) : _client = client,
       _service = service;

  final PiholeV6ApiClient _client;
  final PiholeV6Service _service;

  @override
  Future<Result<List<LocalDns>>> fetchRecords() async {
    return runWithResultRetry<List<LocalDns>>(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final result = await _service.getConfig();
        return result.map((config) => _parseHosts(config.config?.dns?.hosts));
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<Unit>> addRecord({
    required String ip,
    required String name,
  }) async {
    return runWithResultRetry<Unit>(
      action: () async {
        final sid = await getSid();
        return _client.putConfigElement(
          sid,
          element: 'dns/hosts',
          value: '$ip $name',
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<Unit>> deleteRecord({
    required String ip,
    required String name,
  }) async {
    return runWithResultRetry<Unit>(
      action: () async {
        final sid = await getSid();
        return _client.deleteConfigElement(
          sid,
          element: 'dns/hosts',
          value: '$ip $name',
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<Unit>> updateRecord({
    required LocalDns record,
    required String oldIp,
  }) async {
    return runWithResultRetry<Unit>(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);

        final configResult = await _service.getConfig();
        final config = configResult.getOrThrow();
        final hosts = List<String>.from(config.config?.dns?.hosts ?? []);

        final oldEntry = hosts.indexWhere(
          (h) => h.trim().split(RegExp(r'\s+')).first == oldIp,
        );
        if (oldEntry == -1) {
          throw Exception('Entry with IP $oldIp not found');
        }
        hosts[oldEntry] = '${record.ip} ${record.name}';

        final patchResult = await _service.patchConfig(
          body: generated.GetConfig200Response(
            config: generated.ConfigConfig(
              dns: generated.ConfigConfigDns(hosts: hosts),
            ),
          ),
          restart: true,
        );
        return patchResult.map((_) => unit);
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<List<CnameRecord>>> fetchCnameRecords() async {
    return runWithResultRetry<List<CnameRecord>>(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final result = await _service.getConfig();
        return result.map(
          (config) => _parseCnameRecords(config.config?.dns?.cnameRecords),
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<Unit>> addCnameRecord({required CnameRecord record}) async {
    return runWithResultRetry<Unit>(
      action: () async {
        final sid = await getSid();
        return _client.putConfigElement(
          sid,
          element: 'dns/cnameRecords',
          value: _serializeCnameRecord(record),
          isRestart: true,
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<Unit>> deleteCnameRecord({required CnameRecord record}) async {
    return runWithResultRetry<Unit>(
      action: () async {
        final sid = await getSid();
        return _client.deleteConfigElement(
          sid,
          element: 'dns/cnameRecords',
          value: _serializeCnameRecord(record),
          isRestart: true,
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<Unit>> updateCnameRecord({
    required CnameRecord oldRecord,
    required CnameRecord record,
  }) async {
    return runWithResultRetry<Unit>(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final configResult = await _service.getConfig();
        final config = configResult.getOrThrow();
        final records = List<String>.from(
          config.config?.dns?.cnameRecords ?? const <String>[],
        );

        final oldIndex = records.indexWhere(
          (entry) => _parseCnameRecord(entry) == oldRecord,
        );
        if (oldIndex == -1) {
          throw Exception(
            'CNAME record ${_serializeCnameRecord(oldRecord)} not found',
          );
        }
        records[oldIndex] = _serializeCnameRecord(record);

        final patchResult = await _service.patchConfig(
          body: generated.GetConfig200Response(
            config: generated.ConfigConfig(
              dns: generated.ConfigConfigDns(cnameRecords: records),
            ),
          ),
          restart: true,
        );
        return patchResult.map((_) => unit);
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  String _serializeCnameRecord(CnameRecord record) {
    final base = '${record.alias},${record.target}';
    return record.ttl == null ? base : '$base,${record.ttl}';
  }

  CnameRecord _parseCnameRecord(String entry) {
    final parts = entry.split(',').map((part) => part.trim()).toList();
    return CnameRecord(
      alias: parts.isNotEmpty ? parts[0] : '',
      target: parts.length > 1 ? parts[1] : '',
      ttl: parts.length > 2 ? int.tryParse(parts[2]) : null,
    );
  }

  List<CnameRecord> _parseCnameRecords(List<String>? records) {
    if (records == null || records.isEmpty) return const [];
    return records.map(_parseCnameRecord).toList();
  }

  List<LocalDns> _parseHosts(List<String>? hosts) {
    if (hosts == null || hosts.isEmpty) return [];
    return hosts.map((entry) {
      final trimmed = entry.trim();
      final sep = trimmed.indexOf(RegExp(r'\s'));
      if (sep == -1) return LocalDns(ip: trimmed, name: '');
      return LocalDns(
        ip: trimmed.substring(0, sep),
        name: trimmed.substring(sep).trimLeft(),
      );
    }).toList();
  }
}
