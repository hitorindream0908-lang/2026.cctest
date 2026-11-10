import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_place_search.dart';
import 'support/memory_repository.dart';
import 'support/test_app.dart';

Future<void> openSearch(WidgetTester tester) async {
  await tester.tap(find.text('場所').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('都市名で検索'));
  await tester.pumpAndSettle();
}

Future<void> doSearch(WidgetTester tester, String q) async {
  await tester.enterText(find.byType(TextField), q);
  await tester.tap(find.widgetWithText(FilledButton, '検索'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('「東京」と日本語で検索して追加でき、今日タブに出る', (tester) async {
    final repo = MemoryRepository();
    final search = FakePlaceSearch();
    final state = await pumpTestApp(tester, repo: repo, placeSearch: search);

    await openSearch(tester);
    await doSearch(tester, '東京');
    expect(find.text('東京都'), findsOneWidget);
    expect(find.text('地名データ © OpenStreetMap contributors'), findsOneWidget);

    await tester.tap(find.text('東京都'));
    await tester.pumpAndSettle();

    expect(find.text('東京都を追加しました'), findsOneWidget);
    expect(search.timezoneCalls, 1); // Nominatimの結果はタイムゾーンを調べる
    expect(repo.rows.single.timezone, 'Asia/Tokyo');
    expect(state.selectedLocation!.name, '東京都');

    await tester.tap(find.text('今日').last);
    await tester.pumpAndSettle();
    expect(find.text('東京都'), findsOneWidget);
    expect(find.text('日本'), findsOneWidget); // 名前と同じ広域名は重ねて出さない
    expect(find.text('18°'), findsWidgets); // 天気も出る
  });

  testWidgets('海外の都市はその土地のタイムゾーンで登録する', (tester) async {
    final repo = MemoryRepository();
    final search = FakePlaceSearch();
    await pumpTestApp(tester, repo: repo, placeSearch: search);

    await openSearch(tester);
    await doSearch(tester, 'パリ');
    await tester.tap(find.text('パリ').last); // 入力欄ではなく結果の行
    await tester.pumpAndSettle();
    expect(repo.rows.single.timezone, 'Europe/Paris');

    // Open-Meteoの結果はタイムゾーンを持っているので、調べ直さない
    await openSearch(tester);
    await doSearch(tester, 'London');
    await tester.tap(find.text('ロンドン'));
    await tester.pumpAndSettle();
    expect(repo.rows.last.timezone, 'Europe/London');
    expect(search.timezoneCalls, 1);
  });

  testWidgets('登録済みの場所は「追加済み」と出て、重複登録されない', (tester) async {
    final repo = MemoryRepository();
    await pumpTestApp(tester, repo: repo);

    await openSearch(tester);
    await doSearch(tester, '東京');
    await tester.tap(find.text('東京都'));
    await tester.pumpAndSettle();

    await openSearch(tester);
    await doSearch(tester, '東京');
    expect(find.text('追加済み'), findsOneWidget);
    await tester.tap(find.text('東京都'));
    await tester.pumpAndSettle();
    expect(find.text('東京都は追加済みのため、表示をこの場所に切り替えました'), findsOneWidget);
    expect(repo.rows, hasLength(1));
  });

  testWidgets('見つからないとき、通信できないときは、その旨を出す', (tester) async {
    final search = FakePlaceSearch();
    await pumpTestApp(tester, placeSearch: search);
    await openSearch(tester);

    await doSearch(tester, 'ほげほげ');
    expect(find.textContaining('「ほげほげ」に当てはまる場所が見つかりませんでした'), findsOneWidget);

    search.fail = true;
    await doSearch(tester, '東京');
    expect(find.text('通信できないため、検索できませんでした'), findsOneWidget);
  });
}
