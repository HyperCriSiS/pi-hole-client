import 'package:pi_hole_client/domain/model/app/app_log.dart';

typedef AppLogListener = void Function();

/// In-memory sink backing the App Logs screen.
///
/// All entries pass through a final redaction layer before they are exposed to
/// the UI. Callers should still avoid putting secrets in diagnostic messages,
/// but this protects against common credential/header formats appearing in an
/// exception string.
class AppLogService {
  final List<AppLog> _logs = [];
  final Set<AppLogListener> _listeners = {};

  List<AppLog> get logs => List<AppLog>.unmodifiable(_logs);

  void addListener(AppLogListener listener) => _listeners.add(listener);

  void removeListener(AppLogListener listener) => _listeners.remove(listener);

  void addLog(AppLog log) {
    _logs.add(
      AppLog(
        type: log.type,
        dateTime: log.dateTime,
        message: redactSensitiveText(log.message),
        statusCode: log.statusCode,
        resBody: log.resBody == null ? null : redactSensitiveText(log.resBody!),
      ),
    );
    for (final listener in List<AppLogListener>.of(_listeners)) {
      listener();
    }
  }

  void addDiagnostic({
    required String type,
    required String message,
    String? statusCode,
    String? resBody,
  }) {
    addLog(
      AppLog(
        type: type,
        dateTime: DateTime.now(),
        message: message,
        statusCode: statusCode,
        resBody: resBody,
      ),
    );
  }
}

/// Redacts common credential forms before diagnostics reach the UI/clipboard.
///
/// Quoted values are handled first: a password such as "two words" must not
/// leave its second word visible. This is defense in depth, not a general
/// guarantee that arbitrary free-form secrets can be detected.
String redactSensitiveText(String input) {
  var output = input;

  // Consume the *entire* quoted value, including whitespace and escaped
  // quotes. The closing quote must match the opening quote.
  final quotedSecret = RegExp(
    r'''((?:"|')?\b(?:password|passwd|token|access[_-]?token|refresh[_-]?token|auth[_-]?token|sid|session[_-]?id|totp|api[_-]?key|client[_-]?secret)(?:"|')?\s*[:=]\s*)(["'])(?:\\.|(?!\2)[^\\])*\2''',
    caseSensitive: false,
  );
  output = output.replaceAllMapped(
    quotedSecret,
    (match) =>
        '${match.group(1)}${match.group(2)}<redacted>${match.group(2)}',
  );

  // Numeric and unquoted values, including query parameters, must also be
  // redacted. Exclude quotes to preserve already-redacted JSON structure.
  final plainSecret = RegExp(
    r'''((?:"|')?\b(?:password|passwd|token|access[_-]?token|refresh[_-]?token|auth[_-]?token|sid|session[_-]?id|totp|api[_-]?key|client[_-]?secret)(?:"|')?\s*[:=]\s*)([^"'\s,;}&\]]+)''',
    caseSensitive: false,
  );
  output = output.replaceAllMapped(plainSecret, (match) {
    final prefix = match.group(1)!;
    // JSON numerics/bools must turn into JSON *strings*; a bare redaction
    // marker is not valid JSON. For key=value diagnostics, keep the existing
    // unquoted marker format.
    final jsonKey = prefix.startsWith('"') && prefix.trimRight().endsWith(':');
    return jsonKey ? '${prefix}"<redacted>"' : '${prefix}<redacted>';
  });

  // Cover request headers and exceptions which only contain a bare bearer
  // scheme, rather than a named Authorization header.
  final sensitiveHeader = RegExp(
    r'\b(authorization|proxy-authorization|cookie|set-cookie|x-api-key)\s*:\s*[^\r\n]+',
    caseSensitive: false,
  );
  output = output.replaceAllMapped(
    sensitiveHeader,
    (match) => '${match.group(1)}: <redacted>',
  );
  final bareBearer = RegExp(r'\b(Bearer)\s+[^\s,;]+', caseSensitive: false);
  output = output.replaceAllMapped(
    bareBearer,
    (match) => '${match.group(1)} <redacted>',
  );

  // URI userinfo is a second common leakage path in transport exceptions.
  final uriUserInfo = RegExp(
    r'\b(https?://)[^/\s:@]+:[^/\s@]+@',
    caseSensitive: false,
  );
  output = output.replaceAllMapped(
    uriUserInfo,
    (match) => '${match.group(1)}<redacted>@',
  );

  return output;
}
 + '{prefix}"<redacted>"' : '

  // Cover request headers and exceptions which only contain a bare bearer
  // scheme, rather than a named Authorization header.
  final sensitiveHeader = RegExp(
    r'\b(authorization|proxy-authorization|cookie|set-cookie|x-api-key)\s*:\s*[^\r\n]+',
    caseSensitive: false,
  );
  output = output.replaceAllMapped(
    sensitiveHeader,
    (match) => '${match.group(1)}: <redacted>',
  );
  final bareBearer = RegExp(r'\b(Bearer)\s+[^\s,;]+', caseSensitive: false);
  output = output.replaceAllMapped(
    bareBearer,
    (match) => '${match.group(1)} <redacted>',
  );

  // URI userinfo is a second common leakage path in transport exceptions.
  final uriUserInfo = RegExp(
    r'\b(https?://)[^/\s:@]+:[^/\s@]+@',
    caseSensitive: false,
  );
  output = output.replaceAllMapped(
    uriUserInfo,
    (match) => '${match.group(1)}<redacted>@',
  );

  return output;
}
 + '{prefix}<redacted>';
  });

  // Cover request headers and exceptions which only contain a bare bearer
  // scheme, rather than a named Authorization header.
  final sensitiveHeader = RegExp(
    r'\b(authorization|proxy-authorization|cookie|set-cookie|x-api-key)\s*:\s*[^\r\n]+',
    caseSensitive: false,
  );
  output = output.replaceAllMapped(
    sensitiveHeader,
    (match) => '${match.group(1)}: <redacted>',
  );
  final bareBearer = RegExp(r'\b(Bearer)\s+[^\s,;]+', caseSensitive: false);
  output = output.replaceAllMapped(
    bareBearer,
    (match) => '${match.group(1)} <redacted>',
  );

  // URI userinfo is a second common leakage path in transport exceptions.
  final uriUserInfo = RegExp(
    r'\b(https?://)[^/\s:@]+:[^/\s@]+@',
    caseSensitive: false,
  );
  output = output.replaceAllMapped(
    uriUserInfo,
    (match) => '${match.group(1)}<redacted>@',
  );

  return output;
}
