import '../models/location.dart';

/// 都道府県と、その県庁所在地（SPEC.md「場所と都道府県」）。
/// 座標は都道府県庁舎のおおよその位置。
class PrefectureCapital {
  const PrefectureCapital(this.prefecture, this.capital, this.lat, this.lon);

  /// 都道府県名（例: 北海道）
  final String prefecture;

  /// 県庁所在地（例: 札幌市）
  final String capital;
  final double lat;
  final double lon;

  static const country = '日本';
  static const timezone = 'Asia/Tokyo';

  /// 「県庁所在地」「都庁所在地」などの呼び方
  String get seatLabel {
    final suffix = prefecture.substring(prefecture.length - 1);
    return '$suffix庁所在地';
  }

  Location toLocation(DateTime now) => Location(
    name: capital,
    admin1: prefecture,
    country: country,
    lat: lat,
    lon: lon,
    timezone: timezone,
    createdAt: now,
  );

  bool matches(Location l) =>
      l.country == country && l.admin1 == prefecture && l.name == capital;
}

class PrefectureRegion {
  const PrefectureRegion(this.name, this.prefectures);
  final String name;
  final List<PrefectureCapital> prefectures;
}

const prefectureRegions = <PrefectureRegion>[
  PrefectureRegion('北海道・東北', [
    PrefectureCapital('北海道', '札幌市', 43.0642, 141.3469),
    PrefectureCapital('青森県', '青森市', 40.8244, 140.7400),
    PrefectureCapital('岩手県', '盛岡市', 39.7036, 141.1527),
    PrefectureCapital('宮城県', '仙台市', 38.2688, 140.8721),
    PrefectureCapital('秋田県', '秋田市', 39.7186, 140.1024),
    PrefectureCapital('山形県', '山形市', 38.2404, 140.3633),
    PrefectureCapital('福島県', '福島市', 37.7500, 140.4678),
  ]),
  PrefectureRegion('関東', [
    PrefectureCapital('茨城県', '水戸市', 36.3418, 140.4468),
    PrefectureCapital('栃木県', '宇都宮市', 36.5657, 139.8836),
    PrefectureCapital('群馬県', '前橋市', 36.3907, 139.0604),
    PrefectureCapital('埼玉県', 'さいたま市', 35.8569, 139.6489),
    PrefectureCapital('千葉県', '千葉市', 35.6047, 140.1233),
    PrefectureCapital('東京都', '新宿区', 35.6895, 139.6917),
    PrefectureCapital('神奈川県', '横浜市', 35.4478, 139.6425),
  ]),
  PrefectureRegion('中部', [
    PrefectureCapital('新潟県', '新潟市', 37.9026, 139.0236),
    PrefectureCapital('富山県', '富山市', 36.6953, 137.2113),
    PrefectureCapital('石川県', '金沢市', 36.5947, 136.6256),
    PrefectureCapital('福井県', '福井市', 36.0652, 136.2216),
    PrefectureCapital('山梨県', '甲府市', 35.6642, 138.5684),
    PrefectureCapital('長野県', '長野市', 36.6513, 138.1810),
    PrefectureCapital('岐阜県', '岐阜市', 35.3912, 136.7223),
    PrefectureCapital('静岡県', '静岡市', 34.9769, 138.3831),
    PrefectureCapital('愛知県', '名古屋市', 35.1802, 136.9066),
  ]),
  PrefectureRegion('近畿', [
    PrefectureCapital('三重県', '津市', 34.7303, 136.5086),
    PrefectureCapital('滋賀県', '大津市', 35.0045, 135.8686),
    PrefectureCapital('京都府', '京都市', 35.0214, 135.7556),
    PrefectureCapital('大阪府', '大阪市', 34.6863, 135.5200),
    PrefectureCapital('兵庫県', '神戸市', 34.6913, 135.1830),
    PrefectureCapital('奈良県', '奈良市', 34.6853, 135.8327),
    PrefectureCapital('和歌山県', '和歌山市', 34.2260, 135.1675),
  ]),
  PrefectureRegion('中国', [
    PrefectureCapital('鳥取県', '鳥取市', 35.5039, 134.2377),
    PrefectureCapital('島根県', '松江市', 35.4723, 133.0505),
    PrefectureCapital('岡山県', '岡山市', 34.6618, 133.9344),
    PrefectureCapital('広島県', '広島市', 34.3966, 132.4596),
    PrefectureCapital('山口県', '山口市', 34.1859, 131.4714),
  ]),
  PrefectureRegion('四国', [
    PrefectureCapital('徳島県', '徳島市', 34.0657, 134.5593),
    PrefectureCapital('香川県', '高松市', 34.3401, 134.0434),
    PrefectureCapital('愛媛県', '松山市', 33.8416, 132.7657),
    PrefectureCapital('高知県', '高知市', 33.5597, 133.5311),
  ]),
  PrefectureRegion('九州・沖縄', [
    PrefectureCapital('福岡県', '福岡市', 33.6064, 130.4181),
    PrefectureCapital('佐賀県', '佐賀市', 33.2494, 130.2988),
    PrefectureCapital('長崎県', '長崎市', 32.7448, 129.8737),
    PrefectureCapital('熊本県', '熊本市', 32.7898, 130.7417),
    PrefectureCapital('大分県', '大分市', 33.2382, 131.6126),
    PrefectureCapital('宮崎県', '宮崎市', 31.9111, 131.4239),
    PrefectureCapital('鹿児島県', '鹿児島市', 31.5602, 130.5581),
    PrefectureCapital('沖縄県', '那覇市', 26.2124, 127.6809),
  ]),
];

/// 場所が都道府県ピッカーで登録した県庁所在地なら、その情報を返す
PrefectureCapital? findPrefectureCapital(Location l) {
  for (final r in prefectureRegions) {
    for (final p in r.prefectures) {
      if (p.matches(l)) return p;
    }
  }
  return null;
}
