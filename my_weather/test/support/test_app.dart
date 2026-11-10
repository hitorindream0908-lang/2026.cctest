import 'package:flutter_test/flutter_test.dart';
import 'package:my_weather/app.dart';
import 'package:my_weather/state/app_state.dart';
import 'package:my_weather/state/weather_controller.dart';

import 'fake_weather.dart';
import 'memory_repository.dart';

/// テストの「今」: 2026-11-10 10:00（日本時間）
final testNow = DateTime.utc(2026, 11, 10, 1, 0);

/// メモリ上のデータと偽の天気APIでアプリを起動する
Future<AppState> pumpTestApp(
  WidgetTester tester, {
  MemoryRepository? repo,
  FakeWeatherApi? api,
  DateTime Function()? clock,
}) async {
  final r = repo ?? MemoryRepository();
  final c = clock ?? () => testNow;
  final state = AppState(r, clock: c);
  await state.load();
  final weather = WeatherController(r, api ?? FakeWeatherApi(), clock: c);
  await tester.pumpWidget(MyWeatherApp(state: state, weather: weather));
  return state;
}
