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

/// Redacts common credential forms from diagnostic text.
///
/// This is intentionally conservative. It covers key/value text, JSON-like
/// values and HTTP authorization/cookie headers. It never tries to preserve the
/// secret value itself.
String redactSensitiveText(String input) {
  var output = input;

  final jsonSecret = RegExp(
    r'(["\x27]?)(password|token|sid|totp)(["\x27]?\s*:\s*)(["\x27]?)[^"\x27,}\s]+(["\x27]?)',
    caseSensitive: false,
  );
  output = output.replaceAllMapped(
    jsonSecret,
    (match) =>
        '${match.group(1) ?? ''}${match.group(2)}${match.group(3)}<redacted>',
  );

  final keyValueSecret = RegExp(
    r'\b(password|token|sid|totp)\s*([=:])\s*[^\s,;]+',
    caseSensitive: false,
  );
  output = output.replaceAllMapped(
    keyValueSecret,
    (match) => '${match.group(1)}${match.group(2)}<redacted>',
  );

  final sensitiveHeader = RegExp(
    r'\b(authorization|cookie|set-cookie)\s*:\s*[^\r\n]+',
    caseSensitive: false,
  );
  output = output.replaceAllMapped(
    sensitiveHeader,
    (match) => '${match.group(1)}: <redacted>',
  );

  return output;
}
