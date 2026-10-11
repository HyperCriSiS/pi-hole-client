import 'package:pi_hole_client/data/model/local/saved_log_filter_preset.dart';
import 'package:pi_hole_client/data/services/local/database_service.dart';
import 'package:sqflite/sqflite.dart';

/// Storage contract for server- and API-version-scoped query-log presets.
abstract interface class SavedLogFiltersRepository {
  Future<List<SavedLogFilterPreset>> list(String serverAddress, String apiVersion);
  Future<void> save(String serverAddress, SavedLogFilterPreset preset);
  Future<void> delete(String serverAddress, String apiVersion, String name);
}

class LocalSavedLogFiltersRepository implements SavedLogFiltersRepository {
  LocalSavedLogFiltersRepository(this._database);

  final DatabaseService _database;
  static const _table = 'saved_log_filters';

  @override
  Future<List<SavedLogFilterPreset>> list(
    String serverAddress,
    String apiVersion,
  ) async {
    final rows = (await _database.query(
      _table,
      where: 'server_address = ? AND api_version = ?',
      whereArgs: [serverAddress, apiVersion],
      orderBy: 'name COLLATE NOCASE ASC',
    )).getOrThrow();
    return rows.map((row) => SavedLogFilterPreset.decode(
      name: row['name'] as String,
      apiVersion: row['api_version'] as String,
      json: row['filters_json'] as String,
    )).toList();
  }

  @override
  Future<void> save(String serverAddress, SavedLogFilterPreset preset) async {
    (await _database.insert(
      _table,
      {
        'server_address': serverAddress,
        'api_version': preset.apiVersion,
        'name': preset.name,
        'filters_json': preset.encode(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    )).getOrThrow();
  }

  @override
  Future<void> delete(
    String serverAddress,
    String apiVersion,
    String name,
  ) async {
    (await _database.delete(
      _table,
      where: 'server_address = ? AND api_version = ? AND name = ?',
      whereArgs: [serverAddress, apiVersion, name],
    )).getOrThrow();
  }
}
