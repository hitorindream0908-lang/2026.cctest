import 'package:flutter_test/flutter_test.dart';
import 'package:my_weather/data/app_repository.dart';
import 'package:my_weather/data/sqlite_repository.dart';
import 'package:my_weather/models/location.dart';
import 'package:my_weather/state/app_state.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test('端末内DBに場所と設定が保存され、開き直しても残る', () async {
    final dir = await databaseFactoryFfi.getDatabasesPath();
    final path =
        '$dir/my_weather_test_${DateTime.now().microsecondsSinceEpoch}.db';

    var repo = await SqliteRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    final s = await repo.loadSettings();
    expect(s.plan, 'free');
    expect(s.notifyTime, '07:00');
    expect(s.eveningNotifyTime, '20:00');

    final state = AppState(repo);
    await state.load();
    await state.addOrSelect(
      Location(
        name: '名古屋市',
        admin1: '愛知県',
        country: '日本',
        lat: 35.18,
        lon: 136.91,
        timezone: 'Asia/Tokyo',
        createdAt: DateTime.utc(2026, 11, 10, 1, 2, 3),
      ),
    );
    await repo.close();

    repo = await SqliteRepository.open(factory: databaseFactoryFfi, path: path);
    final reloaded = AppState(repo);
    await reloaded.load();
    expect(reloaded.locations.single.name, '名古屋市');
    expect(reloaded.homeLocation!.admin1, '愛知県');
    expect(reloaded.selectedLocation!.timezone, 'Asia/Tokyo');
    await repo.close();
    await databaseFactoryFfi.deleteDatabase(path);
  });

  test('天気キャッシュは場所ごとに1件で、場所を消すと一緒に消える', () async {
    final repo = await SqliteRepository.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    final l = await repo.insertLocation(
      Location(
        name: '那覇市',
        admin1: '沖縄県',
        country: '日本',
        lat: 26.21,
        lon: 127.68,
        timezone: 'Asia/Tokyo',
        createdAt: DateTime.utc(2026),
      ),
    );
    await repo.saveWeatherCache(
      l.id!,
      WeatherCacheEntry(json: '{"a":1}', fetchedAt: DateTime.utc(2026, 1, 1)),
    );
    await repo.saveWeatherCache(
      l.id!,
      WeatherCacheEntry(json: '{"a":2}', fetchedAt: DateTime.utc(2026, 1, 2)),
    );
    expect(await repo.countWeatherCache(), 1);
    final c = await repo.loadWeatherCache(l.id!);
    expect(c!.json, '{"a":2}');
    expect(c.fetchedAt, DateTime.utc(2026, 1, 2));

    await repo.deleteLocation(l.id!);
    expect(await repo.countWeatherCache(), 0);
    await repo.close();
  });
}
