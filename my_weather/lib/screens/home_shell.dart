import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/blur_tab_bar.dart';
import 'onboarding_screen.dart';
import 'places_screen.dart';
import 'records_screen.dart';
import 'settings_screen.dart';
import 'today_screen.dart';

/// 下部タブ4つ（今日、記録、場所、設定）の土台。
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = [
    BlurTabItem(
      icon: Icons.wb_sunny_outlined,
      activeIcon: Icons.wb_sunny,
      label: '今日',
    ),
    BlurTabItem(
      icon: Icons.checkroom_outlined,
      activeIcon: Icons.checkroom,
      label: '記録',
    ),
    BlurTabItem(
      icon: Icons.place_outlined,
      activeIcon: Icons.place,
      label: '場所',
    ),
    BlurTabItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: '設定',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // 場所を1つ登録するまでは初回設定を出す
    final hasLocation = context.select<AppState, bool>(
      (s) => s.locations.isNotEmpty,
    );
    if (!hasLocation) {
      _index = 0; // 登録が済んだら今日タブから始める
      return const OnboardingScreen();
    }

    return Scaffold(
      // 本文をタブバーの下まで描画し、タブバー越しにぼかして見せる
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: [
          const TodayScreen(),
          const RecordsScreen(),
          const PlacesScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BlurTabBar(
        items: _tabs,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
