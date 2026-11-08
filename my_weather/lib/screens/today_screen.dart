import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/tab_page.dart';

/// 今日タブ。段階1では、主役になる黒い面の見た目だけを置く。
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabPage(
      title: '今日',
      children: [
        _HeroPlaceholder(),
        SizedBox(height: 16),
        PlaceholderCard(message: '天気と服装の提案は、段階2と段階3で表示します。'),
      ],
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder();

  @override
  Widget build(BuildContext context) {
    // 最高気温の文字は画面幅に応じて大きくし、最大148
    final width = MediaQuery.sizeOf(context).width;
    final tempSize = math.min(148.0, width * 0.36);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 40,
        horizontal: AppTheme.cardPadding,
      ),
      decoration: BoxDecoration(
        color: AppColors.hero,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Column(
        children: [
          const Text(
            '場所未登録',
            style: TextStyle(
              color: AppColors.onHero,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '天気',
            style: TextStyle(
              color: AppColors.onHero.withValues(alpha: 0.7),
              fontSize: 17,
            ),
          ),
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
          Text(
            '最高気温',
            style: TextStyle(
              color: AppColors.onHero.withValues(alpha: 0.7),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
