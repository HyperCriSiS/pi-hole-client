import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pi_hole_client/domain/services/app_log_service.dart';
import 'package:pi_hole_client/utils/logger.dart';
import 'package:result_dart/result_dart.dart';

/// A service for securely managing key-value pairs using [FlutterSecureStorage].
///
/// This service provides a simple and consistent API for performing secure
/// storage operations such as saving, reading, deleting, and clearing data.
///
/// All methods return [Result] objects to encapsulate success or failure,
/// allowing robust error handling without throwing exceptions directly.
///
/// The underlying [FlutterSecureStorage] instance can be injected, which is
/// useful for testing or customization. If not provided, a default instance
/// is created internally.
class SecureStorageService {
  SecureStorageService({
    FlutterSecureStorage? secureStorage,
    AppLogService? appLogService,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _appLogService = appLogService;

  final FlutterSecureStorage _secureStorage;
  final AppLogService? _appLogService;

  String _safeKeyLabel(String key) {
    if (key.endsWith('_password')) return 'password credential';
    if (key.endsWith('_token')) return 'token credential';
    if (key.endsWith('_sid')) return 'session credential';
    return 'secure value';
  }

  void _recordFailure({
    required String operation,
    required Object error,
    required StackTrace stackTrace,
    String? key,
  }) {
    final target = key == null ? 'secure storage' : _safeKeyLabel(key);
    logger.e(
      'Secure storage $operation failed for $target',
      error: error,
      stackTrace: stackTrace,
    );
    _appLogService?.addDiagnostic(
      type: 'secure-storage',
      message:
          'Secure storage $operation failed for $target: '
          '${error.runtimeType}: $error',
    );
  }

  /// Saves a [value] securely associated with the given [key].
  ///
  /// Returns a [Result<void>] indicating the outcome:
  /// - [Success] containing no value if the operation succeeded.
  /// - [Failure] if an exception occurred.
  Future<Result<void>> saveValue(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
      logger.d('Secure value saved successfully: ${_safeKeyLabel(key)}');
      return Success.unit();
    } catch (e, st) {
      _recordFailure(
        operation: 'write',
        key: key,
        error: e,
        stackTrace: st,
      );
      return Failure(Exception('Failed to save value: $e\n$st'));
    }
  }

  /// Retrieves a value securely for the given [key].
  ///
  /// Returns a [Result<String>] with:
  /// - [Success] containing the value if found.
  /// - [Failure] if not found or an error occurs.
  Future<Result<String>> getValue(String key) async {
    try {
      final value = await _secureStorage.read(key: key);
      if (value == null) {
        logger.w('No secure value found for ${_safeKeyLabel(key)}');
        return Failure(
          Exception('No value found for key: $key'),
        );
      }
      logger.d('Secure value retrieved successfully: ${_safeKeyLabel(key)}');
      return Success(value);
    } catch (e, st) {
      _recordFailure(
        operation: 'read',
        key: key,
        error: e,
        stackTrace: st,
      );
      return Failure(Exception('Failed to read value: $e\n$st'));
    }
  }

  /// Deletes the value associated with the given [key].
  ///
  /// Returns a [Result<void>] indicating the outcome:
  /// - [Success] containing no value if the operation succeeded.
  /// - [Failure] if an error occurred.
  Future<Result<void>> deleteValue(String key) async {
    try {
      await _secureStorage.delete(key: key);
      logger.d('Secure value deleted successfully: ${_safeKeyLabel(key)}');
      return Success.unit();
    } catch (e, st) {
      _recordFailure(
        operation: 'delete',
        key: key,
        error: e,
        stackTrace: st,
      );
      return Failure(Exception('Failed to delete value: $e\n$st'));
    }
  }

  /// Clears all key-value pairs stored securely.
  ///
  /// Returns a [Result<void>] indicating the outcome:
  /// - [Success] containing no value if the operation succeeded.
  /// - [Failure] if an error occurred.
  Future<Result<void>> clearAll() async {
    try {
      await _secureStorage.deleteAll();
      logger.d('All secure values cleared successfully');
      return Success.unit();
    } catch (e, st) {
      _recordFailure(
        operation: 'clear',
        error: e,
        stackTrace: st,
      );
      return Failure(Exception('Failed to clear all values: $e\n$st'));
    }
  }

  /// Reads all securely stored key-value pairs.
  ///
  /// Returns a [Result<Map<String, String>>] with:
  /// - [Success] containing a map of all key-value pairs.
  /// - [Failure] if an error occurs.
  Future<Result<Map<String, String>>> readAll() async {
    try {
      final allValues = await _secureStorage.readAll();
      logger.d('All secure values read successfully: ${allValues.length} items');
      return Success(allValues);
    } catch (e, st) {
      _recordFailure(
        operation: 'read-all',
        error: e,
        stackTrace: st,
      );
      return Failure(Exception('Failed to read all values: $e\n$st'));
    }
  }
}
