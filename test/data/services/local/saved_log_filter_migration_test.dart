import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/services/local/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('migrates an existing v10 database to saved_log_filters in v11', () async {
    final temp = await Directory.systemTemp.createTemp('pihole-preset-upgrade-');
    addTearDown(() => temp.delete(recursive: true));
    final path = temp.uri.resolve('app.db').toFilePath();

    // A minimal valid v10 database with the server table already present.
    final old = await openDatabase(
      path,
      version: 10,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE servers (
            address TEXT PRIMARY KEY NOT NULL
          )
        ''');
        await db.insert('servers', {'address': 'http://pi.hole'});
      },
    );
    await old.close();

    final database = DatabaseService(path: path);
    (await database.open()).getOrThrow();
    addTearDown(() => database.close());

    final version = await database.instance.getVersion();
    expect(version, 11);
    final tables = await database.instance.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      ['saved_log_filters'],
    );
    expect(tables, hasLength(1));
    await database.instance.insert('saved_log_filters', {
      'server_address': 'http://pi.hole',
      'api_version': 'v6',
      'name': 'Blocked',
      'filters_json': '{"version":1,"statusKeys":["GRAVITY"],"requestStatus":"blocked"}',
    });
    expect((await database.query('saved_log_filters')).getOrThrow(), hasLength(1));
  });
}
