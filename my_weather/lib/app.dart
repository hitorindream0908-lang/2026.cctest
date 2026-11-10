import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'data/place_search.dart';
import 'screens/home_shell.dart';
import 'state/app_state.dart';
import 'state/weather_controller.dart';
import 'theme/app_theme.dart';

class MyWeatherApp extends StatelessWidget {
  const MyWeatherApp({
    super.key,
    required this.state,
    required this.weather,
    required this.placeSearch,
  });

  final AppState state;
  final WeatherController weather;
  final PlaceSearchApi placeSearch;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: state),
        ChangeNotifierProvider<WeatherController>.value(value: weather),
        Provider<PlaceSearchApi>.value(value: placeSearch),
      ],
      child: MaterialApp(
        title: 'My Weather',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        // 日本語ロケールを指定すると、端末標準の日本語フォント
        // （iOSはヒラギノ角ゴ系、Androidは標準の日本語フォント）が選ばれる。
        locale: const Locale('ja', 'JP'),
        supportedLocales: const [Locale('ja', 'JP')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const HomeShell(),
      ),
    );
  }
}
