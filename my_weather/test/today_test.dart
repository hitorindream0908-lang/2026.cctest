import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_weather.dart';
import 'support/memory_repository.dart';
import 'support/test_app.dart';

void main() {
  testWidgets('今日の天気で、最高・最低気温、降水確率、最大風速、取得時刻が見える', (tester) async {
    final repo = MemoryRepository();
    await seedTokyo(repo);
    await pumpTestApp(tester, repo: repo);
    await tester.pumpAndSettle();

    expect(find.text('新宿区'), findsOneWidget);
    expect(find.text('晴れ'), findsOneWidget);
    expect(find.text('18°'), findsWidgets); // 特大表示と一覧
    expect(find.text('最低気温'), findsOneWidget);
    expect(find.text('10°'), findsWidgets); // 9.6 → 10
    expect(find.text('10%'), findsWidgets);
    expect(find.text('4.2 m/s'), findsOneWidget);
    expect(find.text('10:00 取得'), findsOneWidget);

    // 週間予報
    await tester.scrollUntilVisible(
      find.text('週間予報'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('明日'), findsOneWidget);
    expect(find.text('11/12（木）'), findsOneWidget);
  });

  testWidgets('通信できないときは、前回の天気と取得時刻を出す', (tester) async {
    final repo = MemoryRepository();
    await seedTokyo(repo);
    final api = FakeWeatherApi();
    var now = testNow;
    await pumpTestApp(tester, repo: repo, api: api, clock: () => now);
    await tester.pumpAndSettle();
    expect(api.calls, 1);

    // 2時間後、通信できない状態で更新
    now = now.add(const Duration(hours: 2));
    api.fail = true;
    // 画面の中央まで寄せる（下端だとタブバーの下に隠れて押せない）
    Scrollable.ensureVisible(tester.element(find.text('更新')), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(find.text('更新'));
    await tester.pumpAndSettle();

    expect(find.text('18°'), findsWidgets);
    expect(find.textContaining('10:00に取得した天気を表示しています'), findsOneWidget);
  });

  testWidgets('最初の取得に失敗したら、その旨を出す', (tester) async {
    final repo = MemoryRepository();
    await seedTokyo(repo);
    await pumpTestApp(tester, repo: repo, api: FakeWeatherApi()..fail = true);
    await tester.pumpAndSettle();
    expect(find.text('天気を取得できませんでした'), findsOneWidget);
    expect(find.text('--°'), findsOneWidget);
  });
}
