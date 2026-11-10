import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// 各タブ共通のページ枠。大きな見出しと、余白の広い本文。
/// 下端はタブバーの高さぶん余白を取り、内容がタブバーに隠れないようにする。
class TabPage extends StatelessWidget {
  const TabPage({
    super.key,
    required this.title,
    required this.children,
    this.onRefresh,
  });

  final String title;
  final List<Widget> children;

  /// 指定すると、下に引っ張って更新できる
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        24,
        AppTheme.pagePadding,
        MediaQuery.paddingOf(context).bottom + 96,
      ),
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 20),
        ...children,
      ],
    );
    return SafeArea(
      bottom: false,
      child: onRefresh == null
          ? list
          : RefreshIndicator(onRefresh: onRefresh!, child: list),
    );
  }
}

/// 枠線・影なし、角丸28の白い面。
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      decoration: BoxDecoration(
        color: AppPalette.of(context).surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: child,
    );
  }
}

/// まだ実装していない画面の中身。どの段階で作るかを示す。
class PlaceholderCard extends StatelessWidget {
  const PlaceholderCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: AppPalette.of(context).subText),
      ),
    );
  }
}
