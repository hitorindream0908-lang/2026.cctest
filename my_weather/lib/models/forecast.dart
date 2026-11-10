/// 予報（Open-Meteo Forecast APIの応答から作る）。
///
/// 日付と時刻はすべて、その場所の現地時刻の文字列のまま持つ
/// （端末のタイムゾーンに左右されないようにするため）。
class Forecast {
  const Forecast({
    required this.timezone,
    required this.utcOffsetSeconds,
    required this.daily,
    required this.hourly,
  });

  final String timezone;
  final int utcOffsetSeconds;
  final List<DailyForecast> daily;
  final List<HourlyTemp> hourly;

  factory Forecast.fromOpenMeteo(Map<String, dynamic> json) {
    final d = json['daily'] as Map<String, dynamic>;
    final dates = (d['time'] as List).cast<String>();
    T? at<T>(String key, int i) {
      final list = d[key] as List?;
      if (list == null || i >= list.length) return null;
      return list[i] as T?;
    }

    final daily = <DailyForecast>[];
    for (var i = 0; i < dates.length; i++) {
      final max = at<num>('temperature_2m_max', i);
      final min = at<num>('temperature_2m_min', i);
      if (max == null || min == null) continue; // 欠測日は出さない
      daily.add(
        DailyForecast(
          date: dates[i],
          maxC: max.toDouble(),
          minC: min.toDouble(),
          weatherCode: at<num>('weather_code', i)?.toInt(),
          precipProbMax: at<num>('precipitation_probability_max', i)?.toInt(),
          windMaxMs: at<num>('wind_speed_10m_max', i)?.toDouble(),
        ),
      );
    }

    final hourly = <HourlyTemp>[];
    final h = json['hourly'] as Map<String, dynamic>?;
    if (h != null) {
      final times = (h['time'] as List).cast<String>();
      final temps = h['temperature_2m'] as List;
      for (var i = 0; i < times.length && i < temps.length; i++) {
        final t = temps[i] as num?;
        if (t != null) hourly.add(HourlyTemp(times[i], t.toDouble()));
      }
    }

    return Forecast(
      timezone: json['timezone'] as String? ?? 'UTC',
      utcOffsetSeconds: (json['utc_offset_seconds'] as num?)?.toInt() ?? 0,
      daily: daily,
      hourly: hourly,
    );
  }

  /// その場所の現地時刻（UTCに時差を足した値。年月日時分だけを使う）
  DateTime localNow(DateTime now) =>
      now.toUtc().add(Duration(seconds: utcOffsetSeconds));

  /// その場所の現地日付（YYYY-MM-DD）
  String localDate(DateTime now) => formatDate(localNow(now));

  /// 現地の「今日」の予報。キャッシュが古すぎて含まれていなければnull
  DailyForecast? today(DateTime now) {
    final date = localDate(now);
    for (final d in daily) {
      if (d.date == date) return d;
    }
    return null;
  }

  /// 今日以降の予報（最大7日）
  List<DailyForecast> fromToday(DateTime now) {
    final date = localDate(now);
    return daily.where((d) => d.date.compareTo(date) >= 0).take(7).toList();
  }

  /// 現地の今の時刻から、今日の終わりまでの時間別気温
  List<HourlyTemp> restOfToday(DateTime now) {
    final local = localNow(now);
    final date = formatDate(local);
    final hourPrefix = '${date}T${_two(local.hour)}';
    return hourly
        .where(
          (h) => h.time.startsWith(date) && h.time.compareTo(hourPrefix) >= 0,
        )
        .toList();
  }

  static String formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';
}

String _two(int n) => n.toString().padLeft(2, '0');

/// 気温の表示と記録のキーに使う、丸めた最高気温（SPEC.md「天気の取得」）。
/// 画面表示と記録で丸め方がずれないよう、必ずこの関数を通す。
int roundTemp(double c) => c.round();

class DailyForecast {
  const DailyForecast({
    required this.date,
    required this.maxC,
    required this.minC,
    this.weatherCode,
    this.precipProbMax,
    this.windMaxMs,
  });

  /// 現地日付 YYYY-MM-DD
  final String date;
  final double maxC;
  final double minC;
  final int? weatherCode;

  /// 降水確率の最大値（%）
  final int? precipProbMax;

  /// 最大風速（m/s）
  final double? windMaxMs;

  int get roundedHigh => roundTemp(maxC);
  int get roundedLow => roundTemp(minC);
}

class HourlyTemp {
  const HourlyTemp(this.time, this.tempC);

  /// 現地時刻 YYYY-MM-DDTHH:MM
  final String time;
  final double tempC;

  int get hour => int.parse(time.substring(11, 13));
}
