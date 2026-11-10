import 'package:flutter_test/flutter_test.dart';
import 'package:my_weather/data/weather_api.dart';
import 'package:my_weather/models/forecast.dart';
import 'package:my_weather/models/location.dart';

import 'support/fake_weather.dart';

void main() {
  final f = Forecast.fromOpenMeteo(sampleForecastJson());

  test('7日分の日ごとの値を読み取る', () {
    expect(f.daily.length, 7);
    final d = f.daily.first;
    expect(d.date, '2026-11-10');
    expect(d.maxC, 18.4);
    expect(d.minC, 9.6);
    expect(d.weatherCode, 1);
    expect(d.precipProbMax, 10);
    expect(d.windMaxMs, 4.2);
    expect(f.hourly.length, 7 * 24);
  });

  test('「今日」は端末ではなく、その場所の現地日付で決まる', () {
    // UTCでは11/9の15:30だが、東京（+9時間）では11/10の0:30
    final now = DateTime.utc(2026, 11, 9, 15, 30);
    expect(f.localDate(now), '2026-11-10');
    expect(f.today(now)!.date, '2026-11-10');
    // UTC 11/9 14:59 は東京で11/9 23:59。予報に11/9はない
    expect(f.today(DateTime.utc(2026, 11, 9, 14, 59)), isNull);
  });

  test('最高気温は四捨五入した整数を表示と記録のキーに使う', () {
    expect(roundTemp(18.4), 18);
    expect(roundTemp(18.5), 19);
    expect(roundTemp(-0.4), 0);
    expect(f.daily.first.roundedHigh, 18);
    expect(f.daily[2].roundedHigh, 20);
  });

  test('時間別の気温は、現地の今の時刻から今日の終わりまで', () {
    // 東京の10:20
    final hours = f.restOfToday(DateTime.utc(2026, 11, 10, 1, 20));
    expect(hours.first.time, '2026-11-10T10:00');
    expect(hours.last.time, '2026-11-10T23:00');
    expect(hours.length, 14);
  });

  test('欠測（null）の日は読み飛ばす', () {
    final json = sampleForecastJson();
    final daily = json['daily'] as Map<String, dynamic>;
    daily['temperature_2m_max'] = <double?>[
      ...daily['temperature_2m_max'] as List<double>,
    ]..[3] = null;
    expect(Forecast.fromOpenMeteo(json).daily.length, 6);
  });

  test('Open-Meteoには、場所のタイムゾーンと必要な項目をすべて指定する', () {
    final uri = OpenMeteoApi.forecastUri(
      Location(
        name: '那覇市',
        admin1: '沖縄県',
        country: '日本',
        lat: 26.2124,
        lon: 127.6809,
        timezone: 'Asia/Tokyo',
        createdAt: DateTime.utc(2026),
      ),
    );
    expect(uri.host, 'api.open-meteo.com');
    final q = uri.queryParameters;
    expect(q['timezone'], 'Asia/Tokyo');
    expect(q['forecast_days'], '7');
    expect(q['wind_speed_unit'], 'ms');
    expect(q['hourly'], 'temperature_2m');
    expect(
      q['daily']!.split(','),
      containsAll([
        'temperature_2m_max',
        'temperature_2m_min',
        'weather_code',
        'precipitation_probability_max',
        'wind_speed_10m_max',
      ]),
    );
  });
}
