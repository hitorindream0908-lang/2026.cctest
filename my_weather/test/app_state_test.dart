import 'package:flutter_test/flutter_test.dart';
import 'package:my_weather/data/prefectures.dart';
import 'package:my_weather/models/location.dart';
import 'package:my_weather/state/app_state.dart';

import 'support/memory_repository.dart';

Location loc(String name, double lat, double lon, {String admin1 = 'A'}) =>
    Location(
      name: name,
      admin1: admin1,
      country: '日本',
      lat: lat,
      lon: lon,
      timezone: 'Asia/Tokyo',
      createdAt: DateTime(2026, 11, 10),
    );

void main() {
  late MemoryRepository repo;
  late AppState state;

  setUp(() async {
    repo = MemoryRepository();
    state = AppState(repo);
    await state.load();
  });

  test('最初の1件は自宅かつ表示中になり、2件目は表示中だけ切り替わる', () async {
    final (_, a) = await state.addOrSelect(loc('札幌市', 43.06, 141.35));
    expect(state.settings.homeLocationId, a.id);
    expect(state.settings.selectedLocationId, a.id);

    final (_, b) = await state.addOrSelect(loc('那覇市', 26.21, 127.68));
    expect(state.settings.homeLocationId, a.id);
    expect(state.settings.selectedLocationId, b.id);
    // 設定は保存されている
    expect(repo.settings.selectedLocationId, b.id);
  });

  test('同名、または2km以内の場所は重複登録しない', () async {
    await state.addOrSelect(loc('札幌市', 43.06, 141.35));
    final (r1, _) = await state.addOrSelect(loc('札幌市', 43.10, 141.40));
    final (r2, _) = await state.addOrSelect(
      loc('Sapporo', 43.065, 141.355, admin1: 'Hokkaido'),
    );
    expect(r1, AddLocationResult.alreadyRegistered);
    expect(r2, AddLocationResult.alreadyRegistered);
    expect(repo.rows.length, 1);
  });

  test('自宅を消すと、残った先頭の場所が自宅になる', () async {
    final (_, a) = await state.addOrSelect(loc('札幌市', 43.06, 141.35));
    final (_, b) = await state.addOrSelect(loc('那覇市', 26.21, 127.68));
    await state.select(a.id!);
    await state.deleteLocation(a.id!);
    expect(state.settings.homeLocationId, b.id);
    expect(state.settings.selectedLocationId, b.id);

    await state.deleteLocation(b.id!);
    expect(state.settings.homeLocationId, isNull);
    expect(state.selectedLocation, isNull);
  });

  test('都道府県は7地方・47件で、名前の重複がない', () {
    expect(prefectureRegions.map((r) => r.name), [
      '北海道・東北',
      '関東',
      '中部',
      '近畿',
      '中国',
      '四国',
      '九州・沖縄',
    ]);
    final all = prefectureRegions.expand((r) => r.prefectures).toList();
    expect(all.length, 47);
    expect(all.map((p) => p.prefecture).toSet().length, 47);
    // 県庁所在地どうしは2km以上離れていて、互いに重複扱いにならない
    final now = DateTime(2026);
    for (var i = 0; i < all.length; i++) {
      for (var j = i + 1; j < all.length; j++) {
        expect(
          all[i].toLocation(now).isSamePlaceAs(all[j].toLocation(now)),
          isFalse,
          reason: '${all[i].capital} と ${all[j].capital}',
        );
      }
    }
    expect(all.firstWhere((p) => p.prefecture == '東京都').seatLabel, '都庁所在地');
  });
}
