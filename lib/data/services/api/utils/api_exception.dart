import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

/// Transport failure observed without an authoritative HTTP error response.
///
/// Preserve this independently of the HTTP status, so connection diagnostics
/// do not mistake network failures for server-generated 503/504 responses.
enum ApiTransportFailure {
  connectTimeout,
  sendTimeout,
  receiveTimeout,
  transformTimeout,
  timeout,
  connection,
  tls,
  cancelled,
  unexpected,
}

/// Returns a fixed, credential-free diagnostic rather than forwarding a Dio
/// message containing URLs, headers, or underlying exception details.
String _transportMessage(ApiTransportFailure failure) => switch (failure) {
  ApiTransportFailure.connectTimeout => 'Connection timed out.',
  ApiTransportFailure.sendTimeout => 'Request upload timed out.',
  ApiTransportFailure.receiveTimeout => 'Server response timed out.',
  ApiTransportFailure.transformTimeout => 'Response processing timed out.',
  ApiTransportFailure.timeout => 'Request timed out.',
  ApiTransportFailure.connection => 'Network connection failed.',
  ApiTransportFailure.tls => 'TLS certificate or handshake failed.',
  ApiTransportFailure.cancelled => 'Request cancelled.',
  ApiTransportFailure.unexpected => 'Unexpected transport error.',
};

ApiTransportFailure? _classifyTransportFailure(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
      return ApiTransportFailure.connectTimeout;
    case DioExceptionType.sendTimeout:
      return ApiTransportFailure.sendTimeout;
    case DioExceptionType.receiveTimeout:
      return ApiTransportFailure.receiveTimeout;
    case DioExceptionType.transformTimeout:
      return ApiTransportFailure.transformTimeout;
    case DioExceptionType.badCertificate:
      return ApiTransportFailure.tls;
    case DioExceptionType.connectionError:
      return error.error is TlsException
          ? ApiTransportFailure.tls
          : ApiTransportFailure.connection;
    case DioExceptionType.cancel:
      return ApiTransportFailure.cancelled;
    case DioExceptionType.unknown:
      if (error.error is TlsException) return ApiTransportFailure.tls;
      if (error.error is SocketException) return ApiTransportFailure.connection;
      if (error.error is TimeoutException) return ApiTransportFailure.timeout;
      return null;
    case DioExceptionType.badResponse:
      return null;
  }
}

/// Exception representing an API error from Dio-based API calls.
///
/// Provides structured error information including HTTP status code,
/// human-readable message, and optional error code/hint from the Pi-hole API
/// response body.
class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.hint,
    this.transportFailure,
  });

  /// Creates an [ApiException] from a [DioException].
  ///
  /// Attempts to extract structured error information from the response body.
  /// Pi-hole v6 API returns errors in the format:
  /// ```json
  /// {
  ///   "error": {
  ///     "key": "unauthorized",
  ///     "message": "...",
  ///     "hint": "..."
  ///   }
  /// }
  /// ```
  factory ApiException.fromDioException(DioException e) {
    final transportFailure = _classifyTransportFailure(e);
    if (transportFailure != null) {
      return ApiException(
        message: _transportMessage(transportFailure),
        transportFailure: transportFailure,
      );
    }
    final response = e.response;
    // Unknown Dio errors can contain request URLs or credentials in the raw
    // exception text. Do not turn those into UI-facing API errors.
    if (response == null) {
      return ApiException(
        message: _transportMessage(ApiTransportFailure.unexpected),
        transportFailure: ApiTransportFailure.unexpected,
      );
    }
    String? errorCode;
    String? hint;
    String message;

    if (response?.data is Map<String, dynamic>) {
      final data = response!.data as Map<String, dynamic>;
      final error = data['error'];
      if (error is Map<String, dynamic>) {
        errorCode = error['key'] as String?;
        hint = error['hint'] as String?;
        message = error['message'] as String? ?? 'HTTP ${response.statusCode ?? 'error'}';
      } else {
        message = 'HTTP ${response.statusCode ?? 'error'}';
      }
    } else {
      message = 'HTTP ${response.statusCode ?? 'error'}';
    }

    return ApiException(
      message: message,
      statusCode: response?.statusCode,
      errorCode: errorCode,
      hint: hint,
    );
  }

  factory ApiException.unknown(String message) =>
      ApiException(message: message);

  final String message;
  final int? statusCode;
  final String? errorCode;
  final String? hint;
  final ApiTransportFailure? transportFailure;

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message, errorCode: $errorCode)';
}