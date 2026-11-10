import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_weather/data/device_locator.dart';

import 'support/fake_locator.dart';
import 'support/fake_place_search.dart';
import 'support/memory_repository.dart';
import 'support/test_app.dart';

void main() {
  testWidgets('許可の前に使い道を説明し、許可されたら現在地を登録する', (tester) async {
    final repo = MemoryRepository();
    final locator = FakeLocator(initial: LocatorStatus.denied);
    final search = FakePlaceSearch();
    await pumpTestApp(
      tester,
      repo: repo,
      locator: locator,
      placeSearch: search,
    );

    await tester.tap(find.text('現在地を使う'));
    await tester.pumpAndSettle();
    // OSのダイアログより先に説明が出て、まだ許可は求めていない
    expect(find.text('位置情報の利用について'), findsOneWidget);
    expect(locator.requests, 0);

    await tester.tap(find.text('続ける'));
    await tester.pumpAndSettle();

    expect(locator.requests, 1);
    expect(find.text('現在地（京都市）を追加しました'), findsOneWidget);
    expect(repo.rows.single.name, '京都市');
    expect(repo.rows.single.admin1, '京都府');
    expect(repo.rows.single.timezone, 'Asia/Tokyo');
    expect(repo.rows.single.lat, 35.0116);
    // 今日タブに切り替わっている
    expect(find.text('記録'), findsWidgets);
  });

  testWidgets('説明で「今はやめる」を選ぶと、許可を求めない', (tester) async {
    final locator = FakeLocator(initial: LocatorStatus.denied);
    await pumpTestApp(tester, locator: locator);
    await tester.tap(find.text('現在地を使う'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('今はやめる'));
    await tester.pumpAndSettle();
    expect(locator.requests, 0);
    expect(find.text('現在地を使う'), findsOneWidget);
  });

  testWidgets('許可されなかったら、もう一度の試し方と都市名検索を案内する', (tester) async {
    final locator = FakeLocator(
      initial: LocatorStatus.denied,
      answer: LocatorStatus.denied,
    );
    await pumpTestApp(tester, locator: locator);
    await tester.tap(find.text('現在地を使う'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('続ける'));
    await tester.pumpAndSettle();

    expect(find.text('位置情報が許可されませんでした'), findsOneWidget);
    // 案内シート側のボタン（後ろの初回設定にも同じ文言がある）
    await tester.tap(find.widgetWithText(FilledButton, '都市名で検索する').last);
    await tester.pumpAndSettle();
    expect(find.text('都市名で検索'), findsOneWidget); // 検索画面が開く
  });

  testWidgets('設定で拒否されているときは、設定アプリへの案内を出す', (tester) async {
    final locator = FakeLocator(initial: LocatorStatus.deniedForever);
    await pumpTestApp(tester, locator: locator);
    await tester.tap(find.text('現在地を使う'));
    await tester.pumpAndSettle();

    expect(locator.requests, 0); // もうダイアログでは聞けない
    expect(find.text('位置情報が許可されていません'), findsOneWidget);
    expect(find.textContaining('このAppの使用中のみ許可'), findsOneWidget);
    await tester.tap(find.text('設定を開く'));
    await tester.pumpAndSettle();
    expect(locator.appSettingsOpened, 1);
  });

  testWidgets('位置情報サービスがオフのときは、その案内を出す', (tester) async {
    final locator = FakeLocator(initial: LocatorStatus.serviceDisabled);
    await pumpTestApp(tester, locator: locator);
    await tester.tap(find.text('現在地を使う'));
    await tester.pumpAndSettle();
    expect(find.text('位置情報サービスがオフです'), findsOneWidget);
    await tester.tap(find.text('設定を開く'));
    await tester.pumpAndSettle();
    expect(locator.locationSettingsOpened, 1);
  });

  testWidgets('現在地が取れないときは、その旨を出す', (tester) async {
    final locator = FakeLocator()..position = null;
    await pumpTestApp(tester, locator: locator);
    await tester.tap(find.text('現在地を使う'));
    await tester.pumpAndSettle();
    expect(find.textContaining('現在地を取得できませんでした'), findsOneWidget);
    expect(find.text('現在地を使う'), findsOneWidget); // 初回設定のまま
  });

  testWidgets('場所タブからも現在地を追加できる', (tester) async {
    final repo = MemoryRepository();
    await seedTokyo(repo);
    await pumpTestApp(tester, repo: repo);
    await tester.pumpAndSettle();
    await tester.tap(find.text('場所').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('現在地'));
    await tester.pumpAndSettle();
    expect(find.text('現在地（京都市）を追加しました'), findsOneWidget);
    expect(repo.rows.map((l) => l.name), ['新宿区', '京都市']);
  });
}
