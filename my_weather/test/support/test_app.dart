import 'package:flutter_test/flutter_test.dart';
import 'package:my_weather/app.dart';
import 'package:my_weather/state/app_state.dart';

import 'memory_repository.dart';

/// メモリ上のデータでアプリを起動する
Future<AppState> pumpTestApp(
  WidgetTester tester, {
  MemoryRepository? repo,
}) async {
  final state = AppState(repo ?? MemoryRepository());
  await state.load();
  await tester.pumpWidget(MyWeatherApp(state: state));
  return state;
}
