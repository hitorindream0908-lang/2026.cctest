import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/prefectures.dart';
import '../models/location.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/tab_page.dart';

/// 今日タブ。段階2-1では、選択中の場所名を主役の面に表示する。
/// 天気は段階2-2、服装の提案は段階3で表示する。
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key, required this.onGoToPlaces});

  final VoidCallback onGoToPlaces;

  @override
  Widget build(BuildContext context) {
    final location = context.watch<AppState>().selectedLocation;
    return TabPage(
      title: '今日',
      children: [
        _Hero(location: location),
        const SizedBox(height: 16),
        if (location == null)
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
                  onPressed: onGoToPlaces,
                  child: const Text('場所を登録する'),
                ),
              ],
            ),
          )
        else
          const PlaceholderCard(message: '天気は段階2-2、服装の提案は段階3で表示します。'),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.location});

  final Location? location;

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
          const SizedBox(height: 4),
          Text('天気', style: TextStyle(color: sub, fontSize: 17)),
          Text(
            '--°',
            style: TextStyle(
              color: AppColors.onHero,
              fontSize: tempSize,
              fontWeight: FontWeight.w200,
              height: 1.1,
              letterSpacing: -4,
            ),
          ),
          Text('最高気温', style: TextStyle(color: sub, fontSize: 15)),
        ],
      ),
    );
  }
}
