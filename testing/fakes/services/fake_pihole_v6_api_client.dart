import 'dart:async';

import 'package:pi_hole_client/data/model/v6/auth/auth.dart' show Session;
import 'package:pi_hole_client/data/model/v6/ftl/ftl.dart' show InfoFtl;
import 'package:pi_hole_client/data/model/v6/network/gateway.dart' show Gateway;
import 'package:pi_hole_client/data/services/api/pihole_v6_api_client.dart';
import 'package:pi_hole_client/utils/exceptions.dart';
import 'package:result_dart/result_dart.dart';

import '../../models/v6/actions.dart';
import '../../models/v6/auth.dart';
import '../../models/v6/ftl.dart';
import '../../models/v6/network.dart';

class FakePiholeV6ApiClient implements PiholeV6ApiClient {
  bool shouldFail = false;
  bool shouldFlushNetworkReturn404 = false;
  bool shouldPostDnsBlockingReturnEnabled = false;
  bool shouldReturnNoPasswordSession = false;
  int postAuthCallCount = 0;
  Completer<void>? authPauseCompleter;

  /// When true, a password-only login (totp == null) fails with
  /// [TotpRequiredException], mimicking a 2FA-enabled server.
  bool shouldRequireTotp = false;

  /// When set, a login whose totp does not equal this value fails with
  /// [TotpInvalidException].
  int? validTotp;

  /// The totp passed to the most recent [postAuth] call.
  int? lastTotp;
  bool shouldGetInfoVersionWithDocker = false;
  bool shouldGetInfoSystemOld = false;
  bool shouldGetInfoFtlV63 = false;

  @override
  void close() {}

  // ==========================================================================
  // Authentication
  // ==========================================================================
  @override
  Future<Result<Session>> postAuth({
    required String password,
    int? totp,
  }) async {
    postAuthCallCount++;
    lastTotp = totp;
    if (authPauseCompleter != null) await authPauseCompleter!.future;
    if (shouldRequireTotp && totp == null) {
      return Failure(TotpRequiredException());
    }
    if (validTotp != null && totp != null && totp != validTotp) {
      return Failure(TotpInvalidException());
    }
    if (shouldFail) {
      return Failure(Exception('Forced postAuth failure'));
    }
    if (shouldReturnNoPasswordSession) {
      return Success(kSrvPostAuthNoPassword);
    }
    return Success(kSrvPostAuth);
  }

  int getAuthCallCount = 0;

  /// Legacy auth-capability fixture state retained for compatibility tests.
  bool serverTotpEnabled = false;

  // ==========================================================================
  // Metrics
  // ==========================================================================
  // ==========================================================================
  // DNS control
  // ==========================================================================
  // ==========================================================================
  // Group management
  // ==========================================================================
  // ==========================================================================
  // Client management
  // ==========================================================================
  // ==========================================================================
  // Domain management
  // ==========================================================================
  // ==========================================================================
  // List management
  // ==========================================================================
  // ==========================================================================
  // FTL information
  // ==========================================================================
  @override
  Future<Result<InfoFtl>> getInfoFtl(String sid) async {
    if (shouldFail) {
      return Failure(Exception('Forced getInfoFtl failure'));
    }
    if (shouldGetInfoFtlV63) {
      return const Success(kSrvGetInfoFtlV63);
    }
    return const Success(kSrvGetInfoFtl);
  }

  // ==========================================================================
  // Network information
  // ==========================================================================
  @override
  Future<Result<Gateway>> getNetworkGateway(
    String sid, {
    bool? isDetailed,
  }) async {
    if (shouldFail) {
      return Failure(Exception('Forced getNetworkGateway failure'));
    }

    if (isDetailed == true) {
      return const Success(kSrvGetNetworkGatewayDetailed);
    }
    return const Success(kSrvGetNetworkGateway);
  }

  // ==========================================================================
  // Actions
  // ==========================================================================
  @override
  Stream<Result<List<String>>> postActionGravity(String sid) async* {
    if (shouldFail) {
      yield Failure(Exception('Forced postActionGravity failure'));
    }

    yield* Stream.fromIterable(
      kSrvPostActionGravity.map(
        (e) => Success(e.map((item) => item as String).toList()),
      ),
    );
  }

  // ==========================================================================
  // Pi-hole Configuration
  // ==========================================================================
  // ==========================================================================
  // DHCP
  // ==========================================================================
}
