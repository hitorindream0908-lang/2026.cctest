import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_repository.dart';
import 'support/test_app.dart';

Future<void> openPicker(WidgetTester tester) =>
    openAddScreen(tester, onboardingLabel: '都道府県から選ぶ', placesLabel: '都道府県から選ぶ');

Future<void> tapPrefecture(WidgetTester tester, String name) async {
  final target = await scrollToPrefecture(tester, name);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<Finder> scrollToPrefecture(WidgetTester tester, String name) async {
  final target = find.text(name);
  await tester.scrollUntilVisible(
    target,
    200,
    scrollable: find.byType(Scrollable).last,
  );
  // リストの先読みで画面外に作られている行もあるので、画面内まで寄せる
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  return target;
}

void main() {
  testWidgets('都道府県を選ぶと県庁所在地が登録され、今日タブに出る', (tester) async {
    final repo = MemoryRepository();
    await pumpTestApp(tester, repo: repo);

    await openPicker(tester);
    expect(find.text('北海道・東北'), findsOneWidget);
    await tapPrefecture(tester, '岩手県');

    // 初回設定が終わって今日タブになり、追加した旨が出る
    expect(find.text('盛岡市（岩手県）を追加しました'), findsOneWidget);
    expect(find.text('盛岡市'), findsOneWidget);
    expect(find.text('岩手県（県庁所在地の予報）'), findsOneWidget);

    await tester.tap(find.text('場所').last);
    await tester.pumpAndSettle();
    expect(find.text('自宅'), findsOneWidget); // 最初の1件は自宅
    expect(repo.rows.single.name, '盛岡市');
    expect(repo.rows.single.timezone, 'Asia/Tokyo');
  });

  testWidgets('登録済みの都道府県は「追加済み」と出て、重複登録されない', (tester) async {
    final repo = MemoryRepository();
    final state = await pumpTestApp(tester, repo: repo);

    await openPicker(tester);
    await tapPrefecture(tester, '東京都');
    await openPicker(tester);
    await tapPrefecture(tester, '大阪府');
    expect(state.selectedLocation!.name, '大阪市');

    await openPicker(tester);
    await scrollToPrefecture(tester, '東京都');
    // 東京都の行に「追加済み」
    final tokyoRow = find
        .ancestor(of: find.text('東京都'), matching: find.byType(Row))
        .first;
    expect(
      find.descendant(of: tokyoRow, matching: find.text('追加済み')),
      findsOneWidget,
    );
    await tapPrefecture(tester, '東京都');

    expect(find.text('新宿区は追加済みのため、表示をこの場所に切り替えました'), findsOneWidget);
    expect(repo.rows.length, 2);
    expect(state.selectedLocation!.name, '新宿区');
  });
}
