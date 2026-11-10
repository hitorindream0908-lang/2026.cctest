import 'package:flutter/material.dart';

/// WMO天気コード（Open-Meteoのweather_code）を日本語とアイコンにする。
class WeatherCodeInfo {
  const WeatherCodeInfo(this.label, this.icon);
  final String label;
  final IconData icon;

  static WeatherCodeInfo of(int? code) {
    switch (code) {
      case 0:
        return const WeatherCodeInfo('快晴', Icons.wb_sunny_outlined);
      case 1:
        return const WeatherCodeInfo('晴れ', Icons.wb_sunny_outlined);
      case 2:
        return const WeatherCodeInfo('晴れ時々くもり', Icons.wb_cloudy_outlined);
      case 3:
        return const WeatherCodeInfo('くもり', Icons.cloud_outlined);
      case 45:
      case 48:
        return const WeatherCodeInfo('霧', Icons.foggy);
      case 51:
      case 53:
      case 55:
        return const WeatherCodeInfo('霧雨', Icons.grain);
      case 56:
      case 57:
        return const WeatherCodeInfo('着氷性の霧雨', Icons.ac_unit);
      case 61:
        return const WeatherCodeInfo('小雨', Icons.umbrella_outlined);
      case 63:
        return const WeatherCodeInfo('雨', Icons.umbrella_outlined);
      case 65:
        return const WeatherCodeInfo('強い雨', Icons.umbrella_outlined);
      case 66:
      case 67:
        return const WeatherCodeInfo('着氷性の雨', Icons.ac_unit);
      case 71:
        return const WeatherCodeInfo('小雪', Icons.ac_unit);
      case 73:
        return const WeatherCodeInfo('雪', Icons.ac_unit);
      case 75:
        return const WeatherCodeInfo('大雪', Icons.ac_unit);
      case 77:
        return const WeatherCodeInfo('霧雪', Icons.ac_unit);
      case 80:
      case 81:
        return const WeatherCodeInfo('にわか雨', Icons.umbrella_outlined);
      case 82:
        return const WeatherCodeInfo('激しいにわか雨', Icons.umbrella_outlined);
      case 85:
      case 86:
        return const WeatherCodeInfo('にわか雪', Icons.ac_unit);
      case 95:
        return const WeatherCodeInfo('雷雨', Icons.thunderstorm_outlined);
      case 96:
      case 99:
        return const WeatherCodeInfo('ひょうを伴う雷雨', Icons.thunderstorm_outlined);
      default:
        return const WeatherCodeInfo('不明', Icons.help_outline);
    }
  }
}
