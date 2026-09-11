import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:pi_hole_client/data/model/v6/auth/auth.dart' show Session;
import 'package:pi_hole_client/data/model/v6/ftl/ftl.dart' show InfoFtl;
import 'package:pi_hole_client/data/model/v6/network/gateway.dart' show Gateway;
import 'package:pi_hole_client/data/services/utils/safe_api_call.dart';
import 'package:pi_hole_client/utils/exceptions.dart';
import 'package:pi_hole_client/utils/misc.dart';
import 'package:result_dart/result_dart.dart';

enum HttpMethod { get, post, put, patch, delete }

class PiholeV6ApiClient {
  PiholeV6ApiClient({
    required String url,
    http.Client? client,
    bool? allowUntrustedCert,
    bool? ignoreCertificateErrors,
    String? pinnedCertificateSha256,
  }) : _url = url,
       _client =
           client ??
           IOClient(
             createHttpClient(
               allowUntrustedCert: allowUntrustedCert ?? true,
               ignoreCertificateErrors: ignoreCertificateErrors ?? false,
               pinnedCertificateSha256: pinnedCertificateSha256,
             ),
           );

  final String _url;
  final http.Client _client;

  void close() {
    _client.close();
  }

  // ==========================================================================
  // Authentication
  // ==========================================================================
  Future<Result<Session>> postAuth({
    required String password,
    int? totp,
  }) async {
    return safeApiCall<Session>(() async {
      final body = <String, dynamic>{'password': password};
      if (totp != null) {
        body['totp'] = totp;
      }
      final resp = await _sendRequest(
        method: HttpMethod.post,
        path: '/api/auth',
        body: body,
      );

      if (resp.statusCode == 200) {
        return Session.fromJson(jsonDecode(resp.body));
      }

      // Check for TOTP-related errors before throwing a generic HTTP exception
      final totpError = _parseTotpError(resp.statusCode, resp.body);
      if (totpError != null) {
        throw totpError;
      }

      throw HttpStatusCodeException(resp.statusCode, resp.body);
    });
  }

  /// Maps a Pi-hole v6 2FA error response to [TotpRequiredException] /
  /// [TotpInvalidException], or null when the response is not a TOTP error.
  Exception? _parseTotpError(int statusCode, String body) {
    if (statusCode != 400 && statusCode != 401 && statusCode != 429) {
      return null;
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;

      final error = decoded['error'];
      if (error is! Map<String, dynamic>) return null;

      final key = error['key'] as String?;
      final message = error['message'] as String? ?? '';
      if (!message.contains('2FA token')) return null;

      if (statusCode == 400 &&
          key == 'bad_request' &&
          message.contains('No 2FA token found in JSON payload')) {
        return TotpRequiredException(message);
      }
      if (statusCode == 401 && key == 'unauthorized') {
        if (message.contains('Reused 2FA token')) {
          return TotpReusedException(message);
        }
        if (message.contains('Invalid 2FA token')) {
          return TotpInvalidException(message);
        }
      }
      if (statusCode == 429 && key == 'rate_limiting') {
        // Rate-limiting 2FA token requests, try again later
        return TotpRateLimitException(message);
      }
    } catch (_) {
      // Fall through to the default HttpStatusCodeException.
    }
    return null;
  }

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
  Future<Result<InfoFtl>> getInfoFtl(String sid) async {
    return safeApiCall<InfoFtl>(() async {
      final resp = await _sendRequest(
        method: HttpMethod.get,
        path: '/api/info/ftl',
        sid: sid,
      );

      if (resp.statusCode == 200) {
        return InfoFtl.fromJson(jsonDecode(resp.body));
      }

      throw HttpStatusCodeException(resp.statusCode, resp.body);
    });
  }

  // ==========================================================================
  // Network information
  // ==========================================================================
  Future<Result<Gateway>> getNetworkGateway(
    String sid, {
    bool? isDetailed,
  }) async {
    final queryString = _buildQueryString({
      if (isDetailed != null) 'detailed': isDetailed.toString(),
    });

    final path = queryString.isEmpty
        ? '/api/network/gateway'
        : '/api/network/gateway?$queryString';

    return safeApiCall<Gateway>(() async {
      final resp = await _sendRequest(
        method: HttpMethod.get,
        path: path,
        sid: sid,
      );

      if (resp.statusCode == 200) {
        return Gateway.fromJson(jsonDecode(resp.body));
      }

      throw HttpStatusCodeException(resp.statusCode, resp.body);
    });
  }

  // ==========================================================================
  // Actions
  // ==========================================================================

  Stream<Result<List<String>>> postActionGravity(String sid) async* {
    yield* safeApiCallStream<List<String>>(() async* {
      final resp = await _sendStreamingRequest(
        method: 'POST',
        path: '/api/action/gravity',
        sid: sid,
      );

      if (resp.statusCode == 200) {
        final stream = resp.stream.transform(utf8.decoder);
        final buffer = StringBuffer();

        await for (final chunk in stream) {
          buffer.write(chunk);

          final rawLines = buffer.toString().split('\n');
          buffer.clear();

          if (!chunk.endsWith('\n')) {
            buffer.write(rawLines.removeLast());
          } else if (rawLines.isNotEmpty && rawLines.last.isEmpty) {
            rawLines.removeLast();
          }

          final trimmedLines = rawLines
              .map((line) => line.trimRight())
              .toList();

          if (trimmedLines.isNotEmpty) {
            yield trimmedLines;
          }
        }

        if (buffer.isNotEmpty) {
          yield [buffer.toString().trimRight()];
        }

        yield [];
      } else {
        final errorMessage = await resp.stream.bytesToString();
        throw HttpStatusCodeException(resp.statusCode, errorMessage);
      }
    });
  }

  // ==========================================================================
  // Pi-hole Configuration
  // ==========================================================================

  // ==========================================================================
  // DHCP
  // ==========================================================================
  // ==========================================================================
  // Helper methods
  // ==========================================================================

  /// Sends an HTTP request to the Pi-hole API.
  Future<http.Response> _sendRequest({
    required HttpMethod method,
    required String path,
    int timeout = 10,
    String? sid,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse(_url).resolve(path);

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'X-FTL-SID': ?sid,
    };

    final encodedBody = body != null ? jsonEncode(body) : null;
    final duration = Duration(seconds: timeout);

    switch (method) {
      case HttpMethod.get:
        return _client.get(uri, headers: headers).timeout(duration);

      case HttpMethod.post:
        return _client
            .post(uri, headers: headers, body: encodedBody)
            .timeout(duration);

      case HttpMethod.put:
        return _client
            .put(uri, headers: headers, body: encodedBody)
            .timeout(duration);

      case HttpMethod.patch:
        return _client
            .patch(uri, headers: headers, body: encodedBody)
            .timeout(duration);

      case HttpMethod.delete:
        return _client.delete(uri, headers: headers).timeout(duration);
    }
  }

  /// Sends a streaming HTTP request to the Pi-hole API.
  Future<http.StreamedResponse> _sendStreamingRequest({
    required String method,
    required String path,
    int timeout = 10,
    String? sid,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse(_url).resolve(path);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'X-FTL-SID': ?sid,
    };

    final request = http.Request(method.toUpperCase(), uri)
      ..headers.addAll(headers);

    if (body != null) {
      request.body = jsonEncode(body);
    }

    return _client.send(request).timeout(Duration(seconds: timeout));
  }

  /// Builds a query string from the provided parameters.
  ///
  /// Returns a string formatted as `key1=value1&key2=value2`, where
  /// only non-null and non-empty values are included.
  String _buildQueryString(Map<String, dynamic> params) {
    return params.entries
        .where((e) => e.value != null && e.value.toString().isNotEmpty)
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}',
        )
        .join('&');
  }
}
