import 'package:flutter/material.dart';

import '../widgets/tab_page.dart';

/// 記録タブ（段階1では空の画面）。
class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabPage(
      title: '記録',
      children: [PlaceholderCard(message: '気温ごとの服装記録は、段階3で表示します。')],
    );
  }
}
