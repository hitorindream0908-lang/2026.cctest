import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_weather/theme/app_colors.dart';

import 'support/test_app.dart';

void main() {
  testWidgets('4つのタブがあり、タップで画面が切り替わる', (tester) async {
    await pumpTestApp(tester);

    for (final label in ['今日', '記録', '場所', '設定']) {
      expect(find.text(label), findsWidgets);
    }

    // 最初は今日タブ。場所が未登録なので登録を促す
    expect(find.text('場所未登録'), findsOneWidget);
    expect(find.text('場所を登録する'), findsOneWidget);

    await tester.tap(find.text('記録').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('段階3で表示します'), findsOneWidget);

    await tester.tap(find.text('設定').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('段階4と段階5'), findsOneWidget);
  });

  testWidgets('今日タブの「場所を登録する」で場所タブに移る', (tester) async {
    await pumpTestApp(tester);
    await tester.tap(find.text('場所を登録する'));
    await tester.pumpAndSettle();
    expect(find.text('都道府県から選ぶ'), findsOneWidget);
  });

  testWidgets('ダークモードでも表示できる', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpTestApp(tester);
    final context = tester.element(find.text('場所未登録'));
    expect(Theme.of(context).scaffoldBackgroundColor, const Color(0xFF000000));
    // 主役の面は背景の黒に溶けないよう、面の色にする
    expect(AppPalette.of(context).hero, const Color(0xFF1D1D1F));
  });
}
