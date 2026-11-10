import 'package:flutter_test/flutter_test.dart';
import 'package:my_weather/app.dart';
import 'package:my_weather/data/prefectures.dart';
import 'package:my_weather/state/app_state.dart';
import 'package:my_weather/state/weather_controller.dart';

import 'fake_locator.dart';
import 'fake_place_search.dart';
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
  FakePlaceSearch? placeSearch,
  FakeLocator? locator,
}) async {
  final r = repo ?? MemoryRepository();
  final c = clock ?? () => testNow;
  final state = AppState(r, clock: c);
  await state.load();
  final weather = WeatherController(r, api ?? FakeWeatherApi(), clock: c);
  await tester.pumpWidget(
    MyWeatherApp(
      state: state,
      weather: weather,
      placeSearch: placeSearch ?? FakePlaceSearch(),
      locator: locator ?? FakeLocator(),
    ),
  );
  return state;
}

/// 東京都（新宿区）を登録済み・表示中にしておく
Future<void> seedTokyo(MemoryRepository repo) async {
  final tokyo = prefectureRegions
      .expand((r) => r.prefectures)
      .firstWhere((p) => p.prefecture == '東京都');
  final saved = await repo.insertLocation(tokyo.toLocation(testNow));
  repo.settings = repo.settings.copyWith(
    homeLocationId: () => saved.id,
    selectedLocationId: () => saved.id,
  );
}

/// 初回設定が出ていればそのボタン、出ていなければ場所タブの行を押す
Future<void> openAddScreen(
  WidgetTester tester, {
  required String onboardingLabel,
  required String placesLabel,
}) async {
  if (find.text(onboardingLabel).evaluate().isNotEmpty) {
    await tester.tap(find.text(onboardingLabel));
  } else {
    await tester.tap(find.text('場所').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(placesLabel));
  }
  await tester.pumpAndSettle();
}
