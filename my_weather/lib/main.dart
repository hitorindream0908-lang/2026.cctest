import 'package:flutter/material.dart';

import 'app.dart';
import 'data/device_locator.dart';
import 'data/place_search.dart';
import 'data/sqlite_repository.dart';
import 'data/weather_api.dart';
import 'state/app_state.dart';
import 'state/weather_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repo = await SqliteRepository.open();
  final state = AppState(repo);
  await state.load();
  final weather = WeatherController(repo, OpenMeteoApi());
  runApp(
    MyWeatherApp(
      state: state,
      weather: weather,
      placeSearch: HttpPlaceSearch(),
      locator: GeolocatorDeviceLocator(),
    ),
  );
}
