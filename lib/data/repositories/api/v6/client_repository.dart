import 'package:pi_hole_client/data/mapper/v6/client_mapper.dart';
import 'package:pi_hole_client/data/model/v6/clients/clients.dart'
    as legacy_clients;
import 'package:pi_hole_client/data/repositories/api/interfaces/client_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/base_v6_sid_repository.dart';
import 'package:pi_hole_client/data/repositories/utils/call_with_retry.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pi_hole_client/domain/model/client/managed_client.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart';
import 'package:result_dart/result_dart.dart';

class ClientRepositoryV6 extends BaseV6SidRepository
    implements ClientRepository {
  ClientRepositoryV6({
    required PiholeV6Service service,
    required super.sessionCache,
  }) : _service = service;

  final PiholeV6Service _service;

  @override
  Future<Result<List<ManagedClient>>> fetchClients() async {
    return runWithResultRetry<List<ManagedClient>>(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final result = await _service.getAllClients();
        return result.map(
          (e) => legacy_clients.Clients.fromJson(e.toJson()).toDomain(),
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<ManagedClient>> addClient(
    String client, {
    String? comment,
    List<int>? groups = const [0],
  }) async {
    return runWithResultRetry<ManagedClient>(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final result = await _service.addClient(
          body: AddClientRequest(
            client: StringOrList.fromString(client),
            comment: comment,
            groups: groups,
          ),
        );
        return result.map(
          (e) => legacy_clients.Clients.fromJson(e.toJson()).toSingleDomain(),
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<ManagedClient>> updateClient(
    String client, {
    String? comment,
    List<int>? groups = const [0],
  }) async {
    return runWithResultRetry<ManagedClient>(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final result = await _service.replaceClient(
          client: client,
          body: ReplaceClientRequest(comment: comment, groups: groups),
        );
        return result.map(
          (e) => legacy_clients.Clients.fromJson(e.toJson()).toSingleDomain(),
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<Unit>> deleteClient(String client) async {
    return runWithResultRetry<Unit>(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        return _service.deleteClient(client: client);
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }
}
