import 'package:pi_hole_client/data/mapper/v6/auth_mapper.dart';
import 'package:pi_hole_client/data/model/v6/auth/auth.dart' as legacy_auth;
import 'package:pi_hole_client/data/model/v6/auth/sessions.dart'
    as legacy_sessions;
import 'package:pi_hole_client/data/repositories/api/interfaces/auth_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/base_v6_sid_repository.dart';
import 'package:pi_hole_client/data/repositories/utils/call_with_retry.dart';
import 'package:pi_hole_client/data/services/api/pihole_v6_api_client.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pi_hole_client/domain/model/auth/auth.dart';
import 'package:pi_hole_client/utils/widget_channel.dart';
import 'package:result_dart/result_dart.dart';

class AuthRepositoryV6 extends BaseV6SidRepository implements AuthRepository {
  AuthRepositoryV6({
    required PiholeV6ApiClient client,
    required PiholeV6Service service,
    required super.sessionCache,
  }) : _client = client,
       _service = service;

  final PiholeV6ApiClient _client;
  final PiholeV6Service _service;

  @override
  Future<Result<Auth>> createSession(String password, {String? totp}) async {
    return runWithResultRetry<Auth>(
      // POST /api/auth is non-idempotent - retrying creates duplicate sessions.
      // Keep this on the handwritten client because the generated Password
      // schema does not expose Pi-hole's TOTP field.
      maxRetries: 0,
      action: () async {
        final result = await _client.postAuth(
          password: password,
          totp: totp != null ? int.tryParse(totp) : null,
        );
        final auth = result.map((e) => e.toDomain());
        final value = auth.getOrNull();
        // Persist only a real sid. An empty sid (no app password) is
        // intentionally not saved; any leftover sid is harmless since a
        // password-less v6 server ignores the sid header.
        if (value != null && value.valid && value.sid.isNotEmpty) {
          await saveSid(value.sid);
          await WidgetChannel.sendSidUpdated(
            serverAddress: serverAddress,
            sid: value.sid,
          );
        }
        return auth;
      },
    );
  }

  @override
  Future<Result<Auth>> getAuth({bool useSid = true}) async {
    // `useSid: false` must stay handwritten. PiholeV6Service retains the most
    // recently configured generated-client API key and has no public "clear
    // sid" operation, so using it here could accidentally authenticate the
    // server 2FA-status probe.
    if (!useSid) {
      return runWithResultRetry<Auth>(
        action: () async {
          final result = await _client.getAuth(null);
          return result.map((e) => e.toDomain());
        },
      );
    }

    return runWithResultRetry<Auth>(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final result = await _service.getAuth();
        return result.map(
          (e) => legacy_auth.Session.fromJson(e.toJson()).toDomain(),
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<Unit>> deleteCurrentSession() async {
    return runWithResultRetry<Unit>(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        return _service.deleteAuth();
      },
      // A 401 renews the shared SID and runWithResultRetry then repeats the
      // same DELETE once with the refreshed generated-client API key.
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<List<AuthSession>>> getAllSessions() async {
    return runWithResultRetry<List<AuthSession>>(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final result = await _service.getAuthSessions();
        return result.map(
          (e) => legacy_sessions.AuthSessions.fromJson(e.toJson()).toDomain(),
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<Unit>> deleteSessionById(int id) async {
    return runWithResultRetry<Unit>(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        return _service.deleteAuthSession(id: id);
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }
}
