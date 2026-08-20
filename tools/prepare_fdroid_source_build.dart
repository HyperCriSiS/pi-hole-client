import 'dart:io';

const _sqliteSystemHook = '''
hooks:
  user_defines:
    sqlite3:
      source: system
''';

void main() {
  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    stderr.writeln('pubspec.yaml was not found in the current directory.');
    exitCode = 2;
    return;
  }

  final contents = pubspec.readAsStringSync();
  final normalized = contents.replaceAll('\r\n', '\n');

  if (normalized.contains(_sqliteSystemHook.trim())) {
    stdout.writeln('F-Droid SQLite system hook is already configured.');
    return;
  }

  final hooksPattern = RegExp(r'^hooks\s*:', multiLine: true);
  if (hooksPattern.hasMatch(normalized)) {
    stderr.writeln(
      'pubspec.yaml already contains a hooks section. Refusing to modify it '
      'automatically; merge the sqlite3 system hook explicitly instead.',
    );
    exitCode = 3;
    return;
  }

  final output = '${normalized.trimRight()}\n\n$_sqliteSystemHook';
  pubspec.writeAsStringSync(output);
  stdout.writeln(
    'Configured sqlite3 to use Android system SQLite for this source build.',
  );
}
