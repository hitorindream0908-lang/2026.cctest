import 'package:my_weather/data/place_search.dart';

/// 偽の地名検索。「東京」「パリ」などに決まった結果を返す
class FakePlaceSearch implements PlaceSearchApi {
  final List<String> queries = [];
  int timezoneCalls = 0;
  bool fail = false;

  static const tokyo = PlaceSearchResult(
    name: '東京都',
    admin1: '東京都',
    country: '日本',
    lat: 35.6769,
    lon: 139.7639,
    source: PlaceSearchSource.nominatim,
  );
  static const paris = PlaceSearchResult(
    name: 'パリ',
    admin1: 'イル＝ド＝フランス地域圏',
    country: 'フランス',
    lat: 48.8535,
    lon: 2.3484,
    source: PlaceSearchSource.nominatim,
  );
  static const london = PlaceSearchResult(
    name: 'ロンドン',
    admin1: 'イングランド',
    country: 'イギリス',
    lat: 51.5085,
    lon: -0.1257,
    timezone: 'Europe/London',
    source: PlaceSearchSource.openMeteo,
  );

  @override
  Future<PlaceSearchOutcome> search(String query) async {
    queries.add(query);
    if (fail) throw PlaceSearchException('通信できないため、検索できませんでした');
    return switch (query) {
      '東京' => const PlaceSearchOutcome([tokyo], usedNominatim: true),
      'パリ' => const PlaceSearchOutcome([paris], usedNominatim: true),
      'London' => const PlaceSearchOutcome([london], usedNominatim: false),
      _ => PlaceSearchOutcome(const [], usedNominatim: needsNominatim(query)),
    };
  }

  int reverseCalls = 0;

  @override
  Future<PlaceSearchResult> reverse(double lat, double lon) async {
    reverseCalls++;
    return PlaceSearchResult(
      name: '京都市',
      admin1: '京都府',
      country: '日本',
      lat: lat,
      lon: lon,
      source: PlaceSearchSource.nominatim,
    );
  }

  @override
  Future<String> resolveTimezone(double lat, double lon) async {
    timezoneCalls++;
    return lon < 100 ? 'Europe/Paris' : 'Asia/Tokyo';
  }
}
