import 'package:pi_hole_client/domain/model/config/config.dart';
import 'package:result_dart/result_dart.dart';

typedef WebPanelPaths = ({String? prefix, String? webHome});

abstract interface class ConfigRepository {
  /// Fetches DNS query logging status.
  Future<Result<Config>> fetchDnsQueryLogging();

  /// Enables or disables DNS query logging.
  Future<Result<Config>> setDnsQueryLogging(bool status);

  /// Returns the Pi-hole web interface path capability when available.
  Future<Result<WebPanelPaths?>> fetchWebPanelPaths();
}