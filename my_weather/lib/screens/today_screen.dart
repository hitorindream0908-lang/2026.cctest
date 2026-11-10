import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/prefectures.dart';
import '../models/forecast.dart';
import '../models/location.dart';
import '../models/weather_code.dart';
import '../state/app_state.dart';
import '../state/weather_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/tab_page.dart';

/// 今日タブ。選択中の場所の天気（段階2-2）。服装の提案は段階3で表示する。
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key, required this.onGoToPlaces});

  final VoidCallback onGoToPlaces;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> with WidgetsBindingObserver {
  int? _requestedFor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// アプリに戻ってきたら、キャッシュが古ければ取り直す
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _ensure();
  }

  void _ensure({bool force = false}) {
    final l = context.read<AppState>().selectedLocation;
    if (l != null) context.read<WeatherController>().ensure(l, force: force);
  }

  @override
  Widget build(BuildContext context) {
    final location = context.watch<AppState>().selectedLocation;
    final weather = context.watch<WeatherController>();

    // 表示する場所が変わったら天気を用意する
    if (location?.id != _requestedFor) {
      _requestedFor = location?.id;
      if (location != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) weather.ensure(location);
        });
      }
    }

    if (location == null) {
      return TabPage(
        title: '今日',
        children: [
          const _Hero(location: null, day: null, loadingText: null),
          const SizedBox(height: 16),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '天気を表示する場所を、1つ登録してください。',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: widget.onGoToPlaces,
                  child: const Text('場所を登録する'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final view = weather.viewFor(location.id!);
    final now = weather.now();
    final forecast = view.forecast;
    final today = forecast?.today(now);

    String? heroNote;
    if (forecast == null) {
      heroNote = view.error != null ? '天気を取得できませんでした' : '天気を取得しています…';
    } else if (today == null) {
      heroNote = '今日の予報がありません';
    }

    return TabPage(
      title: '今日',
      onRefresh: () => weather.ensure(location, force: true),
      children: [
        _Hero(location: location, day: today, loadingText: heroNote),
        const SizedBox(height: 16),
        if (view.error != null)
          _Notice(
            text: view.fetchedAt == null
                ? '${view.error}。通信できる場所で、もう一度お試しください。'
                : '${view.error}。'
                      '${_formatFetched(view.fetchedAt!, forecast!, now)}に取得した天気を表示しています。',
          ),
        if (today != null) ...[
          _StatsCard(day: today),
          const SizedBox(height: 16),
        ],
        _FetchedRow(
          text: view.fetchedAt == null
              ? null
              : '${_formatFetched(view.fetchedAt!, forecast!, now)} 取得',
          loading: view.loading,
          onRefresh: () => _ensure(force: true),
        ),
        const SizedBox(height: 16),
        if (forecast != null && today != null) ...[
          const PlaceholderCard(message: '服装の提案は段階3で表示します。'),
          const SizedBox(height: 16),
          _HourlyCard(hours: forecast.restOfToday(now)),
          const SizedBox(height: 16),
        ],
        if (forecast != null && forecast.fromToday(now).isNotEmpty)
          _WeekCard(
            days: forecast.fromToday(now),
            todayDate: forecast.localDate(now),
          ),
      ],
    );
  }
}

/// 取得時刻を、その場所の現地時刻で表す（今日なら時刻だけ）
String _formatFetched(DateTime fetchedAt, Forecast f, DateTime now) {
  final local = f.localNow(fetchedAt);
  final hm = '${local.hour}:${local.minute.toString().padLeft(2, '0')}';
  if (Forecast.formatDate(local) == f.localDate(now)) return hm;
  return '${local.month}/${local.day} $hm';
}

const _weekdays = ['月', '火', '水', '木', '金', '土', '日'];

String _dayLabel(String date, String todayDate) {
  final d = DateTime.parse(date);
  final t = DateTime.parse(todayDate);
  final diff = DateTime.utc(
    d.year,
    d.month,
    d.day,
  ).difference(DateTime.utc(t.year, t.month, t.day)).inDays;
  if (diff == 0) return '今日';
  if (diff == 1) return '明日';
  return '${d.month}/${d.day}（${_weekdays[d.weekday - 1]}）';
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.location,
    required this.day,
    required this.loadingText,
  });

  final Location? location;
  final DailyForecast? day;
  final String? loadingText;

  @override
  Widget build(BuildContext context) {
    // 最高気温の文字は画面幅に応じて大きくし、最大148
    final width = MediaQuery.sizeOf(context).width;
    final tempSize = math.min(148.0, width * 0.36);
    final sub = AppColors.onHero.withValues(alpha: 0.7);
    final l = location;
    final capital = l == null ? null : findPrefectureCapital(l);

    final String place;
    final String area;
    if (l == null) {
      place = '場所未登録';
      area = '';
    } else if (capital != null) {
      place = l.name;
      area = '${capital.prefecture}（${capital.seatLabel}の予報）';
    } else {
      place = l.name;
      area = [l.admin1, l.country].where((s) => s.isNotEmpty).join('・');
    }

    final d = day;
    final info = d == null ? null : WeatherCodeInfo.of(d.weatherCode);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 40,
        horizontal: AppTheme.cardPadding,
      ),
      decoration: BoxDecoration(
        color: AppPalette.of(context).hero,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Column(
        children: [
          Text(
            place,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.onHero,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (area.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              area,
              textAlign: TextAlign.center,
              style: TextStyle(color: sub, fontSize: 13),
            ),
          ],
          const SizedBox(height: 8),
          if (info != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(info.icon, color: AppColors.onHero, size: 22),
                const SizedBox(width: 6),
                Text(
                  info.label,
                  style: const TextStyle(color: AppColors.onHero, fontSize: 17),
                ),
              ],
            )
          else
            Text(
              loadingText ?? '天気',
              style: TextStyle(color: sub, fontSize: 17),
            ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              d == null ? '--°' : '${d.roundedHigh}°',
              style: TextStyle(
                color: AppColors.onHero,
                fontSize: tempSize,
                fontWeight: FontWeight.w200,
                height: 1.1,
                letterSpacing: -4,
              ),
            ),
          ),
          Text('最高気温', style: TextStyle(color: sub, fontSize: 15)),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SurfaceCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.wifi_off, color: p.subText, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: p.text, fontSize: 14, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.day});
  final DailyForecast day;

  @override
  Widget build(BuildContext context) {
    final wind = day.windMaxMs;
    final precip = day.precipProbMax;
    return SurfaceCard(
      child: Row(
        children: [
          _Stat(label: '最高気温', value: '${day.roundedHigh}°'),
          _Stat(label: '最低気温', value: '${day.roundedLow}°'),
          _Stat(label: '降水確率', value: precip == null ? '--' : '$precip%'),
          _Stat(
            label: '最大風速',
            value: wind == null ? '--' : wind.toStringAsFixed(1),
            unit: wind == null ? null : 'm/s',
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.unit});
  final String label;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(color: p.subText, fontSize: 12)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                text: value,
                style: TextStyle(
                  color: p.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  if (unit != null)
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(
                        color: p.subText,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FetchedRow extends StatelessWidget {
  const _FetchedRow({
    required this.text,
    required this.loading,
    required this.onRefresh,
  });

  final String? text;
  final bool loading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Row(
      children: [
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text ?? 'まだ取得していません',
            style: TextStyle(color: p.subText, fontSize: 13),
          ),
        ),
        if (loading)
          const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('更新'),
          ),
      ],
    );
  }
}

class _HourlyCard extends StatelessWidget {
  const _HourlyCard({required this.hours});
  final List<HourlyTemp> hours;

  @override
  Widget build(BuildContext context) {
    if (hours.isEmpty) return const SizedBox.shrink();
    final p = AppPalette.of(context);
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('今日の気温の移り変わり', style: TextStyle(color: p.subText, fontSize: 13)),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: hours.length,
              separatorBuilder: (_, _) => const SizedBox(width: 18),
              itemBuilder: (_, i) {
                final h = hours[i];
                return Column(
                  children: [
                    Text(
                      i == 0 ? '今' : '${h.hour}時',
                      style: TextStyle(color: p.subText, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${roundTemp(h.tempC)}°',
                      style: TextStyle(
                        color: p.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.days, required this.todayDate});
  final List<DailyForecast> days;
  final String todayDate;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('週間予報', style: TextStyle(color: p.subText, fontSize: 13)),
          const SizedBox(height: 8),
          for (final d in days)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 84,
                    child: Text(
                      _dayLabel(d.date, todayDate),
                      style: TextStyle(
                        color: p.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    WeatherCodeInfo.of(d.weatherCode).icon,
                    color: p.text,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      d.precipProbMax == null ? '' : '${d.precipProbMax}%',
                      style: TextStyle(color: p.subText, fontSize: 13),
                    ),
                  ),
                  Text(
                    '${d.roundedHigh}°',
                    style: TextStyle(
                      color: p.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${d.roundedLow}°',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: p.subText, fontSize: 17),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
