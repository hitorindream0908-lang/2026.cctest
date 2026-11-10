import 'package:flutter_test/flutter_test.dart';
import 'package:my_weather/data/app_repository.dart';
import 'package:my_weather/models/location.dart';
import 'package:my_weather/state/weather_controller.dart';

import 'support/fake_weather.dart';
import 'support/memory_repository.dart';

void main() {
  late MemoryRepository repo;
  late FakeWeatherApi api;
  late DateTime now;
  late WeatherController c;
  late Location tokyo;

  setUp(() async {
    repo = MemoryRepository();
    api = FakeWeatherApi();
    now = DateTime.utc(2026, 11, 10, 1, 0);
    c = WeatherController(repo, api, clock: () => now);
    tokyo = await repo.insertLocation(
      Location(
        name: '新宿区',
        admin1: '東京都',
        country: '日本',
        lat: 35.69,
        lon: 139.69,
        timezone: 'Asia/Tokyo',
        createdAt: now,
      ),
    );
  });

  test('取得した天気はキャッシュし、1時間未満なら取り直さない', () async {
    await c.ensure(tokyo);
    expect(api.calls, 1);
    expect(repo.weather[tokyo.id], isNotNull);
    expect(c.viewFor(tokyo.id!).fetchedAt, now);

    now = now.add(const Duration(minutes: 59));
    await c.ensure(tokyo);
    expect(api.calls, 1);

    now = now.add(const Duration(minutes: 1)); // ちょうど1時間
    await c.ensure(tokyo);
    expect(api.calls, 2);
  });

  test('アプリを起動し直しても、端末内のキャッシュが新しければ通信しない', () async {
    await c.ensure(tokyo);
    final restarted = WeatherController(repo, api, clock: () => now);
    await restarted.ensure(tokyo);
    expect(api.calls, 1);
    expect(restarted.viewFor(tokyo.id!).forecast!.daily.length, 7);
  });

  test('更新ボタン（force）はキャッシュが新しくても取り直す', () async {
    await c.ensure(tokyo);
    await c.ensure(tokyo, force: true);
    expect(api.calls, 2);
  });

  test('通信できないときは、前回の天気を出したまま失敗を伝える', () async {
    await c.ensure(tokyo);
    final firstFetch = now;
    now = now.add(const Duration(hours: 3));
    api.fail = true;
    await c.ensure(tokyo);

    final v = c.viewFor(tokyo.id!);
    expect(v.forecast, isNotNull);
    expect(v.fetchedAt, firstFetch); // 取得時刻は前回のまま
    expect(v.error, isNotNull);
    expect(v.loading, isFalse);

    // つながったら、エラーは消える
    api.fail = false;
    await c.ensure(tokyo, force: true);
    expect(c.viewFor(tokyo.id!).error, isNull);
    expect(c.viewFor(tokyo.id!).fetchedAt, now);
  });

  test('キャッシュがなく通信もできないときは、天気なしで失敗を伝える', () async {
    api.fail = true;
    await c.ensure(tokyo);
    final v = c.viewFor(tokyo.id!);
    expect(v.forecast, isNull);
    expect(v.error, isNotNull);
  });

  test('取得時刻が未来（端末の時計が戻った）なら古いとみなす', () async {
    repo.weather[tokyo.id!] = WeatherCacheEntry(
      json: '{"daily":{"time":[]},"utc_offset_seconds":32400}',
      fetchedAt: now.add(const Duration(hours: 2)),
    );
    await c.ensure(tokyo);
    expect(api.calls, 1);
  });
}
