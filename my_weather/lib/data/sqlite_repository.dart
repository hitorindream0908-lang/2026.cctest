import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/app_settings.dart';
import '../models/location.dart';
import 'app_repository.dart';

/// sqfliteによる端末内データベース。
///
/// テーブルは段階ごとに足していく。スキーマを変えるときは
/// [_version] を上げ、[_migrate] に手順を追加する（既存データを消さない）。
class SqliteRepository implements AppRepository {
  SqliteRepository._(this._db);

  final Database _db;

  static const _version = 2;

  static Future<SqliteRepository> open({
    DatabaseFactory? factory,
    String? path,
  }) async {
    final f = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await f.getDatabasesPath(), 'my_weather.db');
    final db = await f.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _version,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) => _migrate(db, 0, version),
        onUpgrade: _migrate,
      ),
    );
    return SqliteRepository._(db);
  }

  static Future<void> _migrate(Database db, int from, int to) async {
    if (from < 1) {
      await db.execute('''
        CREATE TABLE locations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          admin1 TEXT NOT NULL,
          country TEXT NOT NULL,
          lat REAL NOT NULL,
          lon REAL NOT NULL,
          timezone TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE settings (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          plan TEXT NOT NULL DEFAULT 'free',
          notify_time TEXT NOT NULL DEFAULT '07:00',
          evening_notify_time TEXT NOT NULL DEFAULT '20:00',
          home_location_id INTEGER,
          selected_location_id INTEGER
        )
      ''');
      await db.insert('settings', const AppSettings().toRow());
    }
    if (from < 2) {
      await db.execute('''
        CREATE TABLE weather_cache (
          location_id INTEGER PRIMARY KEY
            REFERENCES locations(id) ON DELETE CASCADE,
          json TEXT NOT NULL,
          fetched_at TEXT NOT NULL
        )
      ''');
    }
  }

  Future<void> close() => _db.close();

  @override
  Future<AppSettings> loadSettings() async {
    final rows = await _db.query('settings', where: 'id = 1');
    if (rows.isEmpty) return const AppSettings();
    return AppSettings.fromRow(rows.first);
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    await _db.insert(
      'settings',
      settings.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<Location>> listLocations() async {
    final rows = await _db.query('locations', orderBy: 'created_at, id');
    return rows.map(Location.fromRow).toList();
  }

  @override
  Future<Location> insertLocation(Location location) async {
    final row = location.toRow()..remove('id');
    final id = await _db.insert('locations', row);
    return location.copyWith(id: id);
  }

  @override
  Future<void> deleteLocation(int id) async {
    await _db.delete('locations', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<WeatherCacheEntry?> loadWeatherCache(int locationId) async {
    final rows = await _db.query(
      'weather_cache',
      where: 'location_id = ?',
      whereArgs: [locationId],
    );
    if (rows.isEmpty) return null;
    return WeatherCacheEntry(
      json: rows.first['json'] as String,
      fetchedAt: DateTime.parse(rows.first['fetched_at'] as String),
    );
  }

  @override
  Future<void> saveWeatherCache(int locationId, WeatherCacheEntry entry) async {
    await _db.insert('weather_cache', {
      'location_id': locationId,
      'json': entry.json,
      'fetched_at': entry.fetchedAt.toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// テスト用: 天気キャッシュの件数
  Future<int> countWeatherCache() async =>
      Sqflite.firstIntValue(
        await _db.rawQuery('SELECT COUNT(*) FROM weather_cache'),
      ) ??
      0;
}
