import 'package:flutter/material.dart';

import '../widgets/tab_page.dart';

/// 設定タブ（段階1では空の画面）。
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabPage(
      title: '設定',
      children: [PlaceholderCard(message: '通知時刻とプランの設定は、段階4と段階5で作ります。')],
    );
  }
}
