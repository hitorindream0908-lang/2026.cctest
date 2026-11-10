import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/location.dart';

/// 天気の取得元。テストでは差し替える。
abstract class WeatherApi {
  /// 7日分の予報をOpen-Meteo形式のJSONで返す。失敗したら例外を投げる。
  Future<Map<String, dynamic>> fetchForecast(Location location);
}

/// Open-Meteo Forecast API（APIキー不要）。
class OpenMeteoApi implements WeatherApi {
  OpenMeteoApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static Uri forecastUri(Location l) =>
      Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': l.lat.toStringAsFixed(4),
        'longitude': l.lon.toStringAsFixed(4),
        'daily': [
          'temperature_2m_max',
          'temperature_2m_min',
          'weather_code',
          'precipitation_probability_max',
          'wind_speed_10m_max',
        ].join(','),
        'hourly': 'temperature_2m',
        'timezone': l.timezone,
        'forecast_days': '7',
        'wind_speed_unit': 'ms',
      });

  @override
  Future<Map<String, dynamic>> fetchForecast(Location location) async {
    final res = await _client
        .get(forecastUri(location))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw WeatherFetchException('天気の取得に失敗しました（${res.statusCode}）');
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }
}

class WeatherFetchException implements Exception {
  WeatherFetchException(this.message);
  final String message;
  @override
  String toString() => message;
}
