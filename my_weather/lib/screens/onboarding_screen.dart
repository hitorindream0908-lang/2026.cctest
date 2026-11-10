import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'city_search_screen.dart';
import 'current_location_flow.dart';
import 'prefecture_picker_screen.dart';

/// 初回設定。場所を1つ登録するまで、タブの代わりに表示する。
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _report(BuildContext context, Future<String?> action) async {
    final message = await action;
    if (message != null && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    Future<String?> open(Widget screen) =>
        Navigator.of(context)
            .push<String>(MaterialPageRoute(builder: (_) => screen));

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.pagePadding,
            56,
            AppTheme.pagePadding,
            32,
          ),
          children: [
            Text(
              'My Weather',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge
                  ?.copyWith(fontSize: 40),
            ),
            const SizedBox(height: 16),
            Text(
              '毎朝の天気と最高気温から、\nあなたにとって最適な服装を提案します。',
              textAlign: TextAlign.center,
              style: TextStyle(color: p.text, fontSize: 17, height: 1.6),
            ),
            const SizedBox(height: 12),
            Text(
              'まず、天気を表示する場所を1つ登録してください。',
              textAlign: TextAlign.center,
              style: TextStyle(color: p.subText, fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: () => _report(context, addCurrentLocation(context)),
              icon: const Icon(Icons.near_me_outlined),
              label: const Text('現在地を使う'),
            ),
            const SizedBox(height: 12),
            _SecondaryButton(
              icon: Icons.search,
              label: '都市名で検索する',
              onPressed: () => _report(context, open(const CitySearchScreen())),
            ),
            const SizedBox(height: 12),
            _SecondaryButton(
              icon: Icons.map_outlined,
              label: '都道府県から選ぶ',
              onPressed: () =>
                  _report(context, open(const PrefecturePickerScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

/// 白い面のピル型ボタン（青い主ボタンの次に置く選択肢）
class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: p.surface,
        foregroundColor: p.text,
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
