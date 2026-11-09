import 'package:flutter/material.dart';

import 'app.dart';
import 'data/sqlite_repository.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repo = await SqliteRepository.open();
  final state = AppState(repo);
  await state.load();
  runApp(MyWeatherApp(state: state));
}
