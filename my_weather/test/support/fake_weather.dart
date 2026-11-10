import 'package:my_weather/data/weather_api.dart';
import 'package:my_weather/models/location.dart';

/// Open-Meteoの応答の見本（東京、2026-11-10からの7日分）
Map<String, dynamic> sampleForecastJson({
  double todayMax = 18.4,
  String startDate = '2026-11-10',
}) {
  final start = DateTime.parse(startDate);
  final dates = [
    for (var i = 0; i < 7; i++)
      start.add(Duration(days: i)).toIso8601String().substring(0, 10),
  ];
  return <String, dynamic>{
    'latitude': 35.7,
    'longitude': 139.7,
    'utc_offset_seconds': 32400,
    'timezone': 'Asia/Tokyo',
    'daily': <String, dynamic>{
      'time': dates,
      'temperature_2m_max': [todayMax, 16.5, 20.2, 14.0, 13.6, 15.1, 17.9],
      'temperature_2m_min': [9.6, 8.1, 11.0, 7.4, 6.0, 7.7, 9.0],
      'weather_code': [1, 3, 61, 0, 2, 80, 95],
      'precipitation_probability_max': [10, 30, 80, 0, 20, 60, 70],
      'wind_speed_10m_max': [4.2, 5.0, 7.8, 3.1, 2.4, 6.6, 9.3],
    },
    'hourly': <String, dynamic>{
      'time': [
        for (final d in dates)
          for (var h = 0; h < 24; h++)
            '${d}T${h.toString().padLeft(2, '0')}:00',
      ],
      'temperature_2m': [for (var i = 0; i < 7 * 24; i++) 10 + (i % 24) / 3],
    },
  };
}

/// 呼ばれた回数を数え、失敗も再現できる偽の天気API
class FakeWeatherApi implements WeatherApi {
  FakeWeatherApi({Map<String, dynamic>? json})
    : json = json ?? sampleForecastJson();

  Map<String, dynamic> json;
  bool fail = false;
  int calls = 0;

  @override
  Future<Map<String, dynamic>> fetchForecast(Location location) async {
    calls++;
    if (fail) throw Exception('offline');
    return json;
  }
}
