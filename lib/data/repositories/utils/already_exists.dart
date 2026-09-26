import 'package:pi_hole_client/data/services/api/utils/api_exception.dart';
import 'package:pi_hole_client/utils/exceptions.dart';
import 'package:result_dart/result_dart.dart';

/// Whether a Pi-hole error text means the item already exists.
///
/// - 400, "The item is already present": FTL v6.7 and later
/// - 201, "UNIQUE constraint failed": before FTL v6.7
/// - 400, "Item already present": Local DNS, in all versions
/// - v5, "... is already on the list": domains
bool isDuplicateError(String text) {
  final lower = text.toLowerCase();
  return lower.contains('item is already present') ||
      lower.contains('item already present') ||
      lower.contains('unique constraint failed') ||
      lower.contains('already on the list');
}

/// Turns a 4xx response whose body says the item already exists into an
/// [AlreadyExistsException]. Other results are returned as they are.
///
/// Generated v6 calls expose [ApiException], while legacy/http-package paths
/// use [HttpStatusCodeException]. Pi-hole may put the useful duplicate detail
/// in either the error message or its hint, so both are inspected.
Result<T> mapDuplicateFailure<T extends Object>(Result<T> result) {
  final error = result.exceptionOrNull();

  int? statusCode;
  String? errorText;
  if (error is HttpStatusCodeException) {
    statusCode = error.statusCode;
    errorText = error.message;
  } else if (error is ApiException) {
    statusCode = error.statusCode;
    final hint = error.hint;
    errorText = hint == null || hint.isEmpty
        ? error.message
        : '${error.message} $hint';
  }

  if (statusCode != null &&
      statusCode >= 400 &&
      statusCode < 500 &&
      errorText != null &&
      isDuplicateError(errorText)) {
    return Failure(AlreadyExistsException());
  }
  return result;
}

/// Checks the `processed.errors` texts of a successful response.
Result<T> checkProcessedErrors<T extends Object>(
  Iterable<String?>? errors,
  T Function() onSuccess,
) {
  final messages = errors?.whereType<String>().toList() ?? const <String>[];
  if (messages.isEmpty) return Success(onSuccess());
  if (messages.any(isDuplicateError)) return Failure(AlreadyExistsException());
  return Failure(Exception(messages.join(', ')));
}
