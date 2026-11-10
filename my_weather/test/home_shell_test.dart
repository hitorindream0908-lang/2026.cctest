import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_weather/theme/app_colors.dart';

import 'support/memory_repository.dart';
import 'support/test_app.dart';

void main() {
  testWidgets('場所が未登録なら初回設定が出て、タブは出ない', (tester) async {
    await pumpTestApp(tester);
    expect(find.text('My Weather'), findsOneWidget);
    expect(find.text('現在地を使う'), findsOneWidget);
    expect(find.text('都市名で検索する'), findsOneWidget);
    expect(find.text('都道府県から選ぶ'), findsOneWidget);
    expect(find.text('記録'), findsNothing);
  });

  testWidgets('4つのタブがあり、タップで画面が切り替わる', (tester) async {
    final repo = MemoryRepository();
    await seedTokyo(repo);
    await pumpTestApp(tester, repo: repo);
    await tester.pumpAndSettle();

    for (final label in ['今日', '記録', '場所', '設定']) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.text('新宿区'), findsOneWidget);

    await tester.tap(find.text('記録').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('段階3で表示します'), findsOneWidget);

    await tester.tap(find.text('設定').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('段階4と段階5'), findsOneWidget);
  });

  testWidgets('最後の場所を削除すると、初回設定に戻る', (tester) async {
    final repo = MemoryRepository();
    await seedTokyo(repo);
    await pumpTestApp(tester, repo: repo);
    await tester.pumpAndSettle();

    await tester.tap(find.text('場所').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('その他の操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '削除'));
    await tester.pumpAndSettle();
    expect(find.text('現在地を使う'), findsOneWidget);
  });

  testWidgets('ダークモードでも表示できる', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final repo = MemoryRepository();
    await seedTokyo(repo);
    await pumpTestApp(tester, repo: repo);
    await tester.pumpAndSettle();
    final context = tester.element(find.text('新宿区'));
    expect(Theme.of(context).scaffoldBackgroundColor, const Color(0xFF000000));
    // 主役の面は背景の黒に溶けないよう、面の色にする
    expect(AppPalette.of(context).hero, const Color(0xFF1D1D1F));
  });
}
