import 'package:flutter/material.dart';

import '../widgets/tab_page.dart';

/// 場所タブ（段階1では空の画面）。
class PlacesScreen extends StatelessWidget {
  const PlacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabPage(
      title: '場所',
      children: [PlaceholderCard(message: '場所の登録と切り替えは、段階2で作ります。')],
    );
  }
}
