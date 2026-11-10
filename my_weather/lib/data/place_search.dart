import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/location.dart';

/// 地名検索の結果1件
class PlaceSearchResult {
  const PlaceSearchResult({
    required this.name,
    required this.admin1,
    required this.country,
    required this.lat,
    required this.lon,
    this.timezone,
    required this.source,
  });

  final String name;
  final String admin1;
  final String country;
  final double lat;
  final double lon;

  /// Open-Meteo Geocodingは返すが、Nominatimは返さない（登録時に解決する）
  final String? timezone;
  final PlaceSearchSource source;

  Location toLocation(String tz, DateTime now) => Location(
    name: name,
    admin1: admin1,
    country: country,
    lat: lat,
    lon: lon,
    timezone: tz,
    createdAt: now,
  );
}

enum PlaceSearchSource { nominatim, openMeteo }

/// 地名検索（SPEC.md「外部APIと技術構成の推奨 > 地名検索の制約」）。
abstract class PlaceSearchApi {
  Future<PlaceSearchOutcome> search(String query);

  /// 座標からIANAタイムゾーンを求める
  Future<String> resolveTimezone(double lat, double lon);

  /// 座標から地名（市区町村ほどの単位）を求める
  Future<PlaceSearchResult> reverse(double lat, double lon);
}

class PlaceSearchOutcome {
  const PlaceSearchOutcome(this.results, {required this.usedNominatim});
  final List<PlaceSearchResult> results;

  /// OpenStreetMapの帰属表示が必要か
  final bool usedNominatim;
}

class PlaceSearchException implements Exception {
  PlaceSearchException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// 日本語やかななど、ASCII以外の文字を含むか
bool needsNominatim(String query) => query.runes.any((r) => r > 0x7f);

/// 二段構えの地名検索。
///
/// - 日本語など（ASCII以外を含む）: OpenStreetMapのNominatim
/// - ローマ字: Open-Meteo Geocoding。0件ならNominatimでも探す
///
/// Nominatimの利用条件に従い、識別できるUser-Agentを付け、
/// 入力のたびではなく検索ボタンを押したときだけ問い合わせる。
class HttpPlaceSearch implements PlaceSearchApi {
  HttpPlaceSearch({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const userAgent = 'MyWeather/0.1 (personal weather and outfit app)';
  static const _timeout = Duration(seconds: 15);

  @override
  Future<PlaceSearchOutcome> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const PlaceSearchOutcome([], usedNominatim: false);
    if (needsNominatim(q)) {
      return PlaceSearchOutcome(await _nominatim(q), usedNominatim: true);
    }
    final om = await _openMeteo(q);
    if (om.isNotEmpty) return PlaceSearchOutcome(om, usedNominatim: false);
    return PlaceSearchOutcome(await _nominatim(q), usedNominatim: true);
  }

  Future<dynamic> _getJson(Uri uri, {Map<String, String>? headers}) async {
    final http.Response res;
    try {
      res = await _client.get(uri, headers: headers).timeout(_timeout);
    } catch (_) {
      throw PlaceSearchException('通信できないため、検索できませんでした');
    }
    if (res.statusCode != 200) {
      throw PlaceSearchException('検索に失敗しました（${res.statusCode}）');
    }
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  static Uri nominatimUri(String q) =>
      Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': q,
        'format': 'jsonv2',
        'addressdetails': '1',
        'accept-language': 'ja',
        'limit': '10',
      });

  static Uri openMeteoUri(String q) => Uri.https(
    'geocoding-api.open-meteo.com',
    '/v1/search',
    {'name': q, 'count': '10', 'language': 'ja', 'format': 'json'},
  );

  Future<List<PlaceSearchResult>> _nominatim(String q) async {
    final list = await _getJson(
      nominatimUri(q),
      headers: {'User-Agent': userAgent, 'Accept-Language': 'ja'},
    );
    return parseNominatim(list as List);
  }

  Future<List<PlaceSearchResult>> _openMeteo(String q) async {
    final json = await _getJson(openMeteoUri(q)) as Map<String, dynamic>;
    return parseOpenMeteo(json);
  }

  /// 地名として使える種類（都市、町、都道府県や州など）だけを残す
  static List<PlaceSearchResult> parseNominatim(List list) {
    final out = <PlaceSearchResult>[];
    for (final raw in list) {
      final m = raw as Map<String, dynamic>;
      final category = (m['category'] ?? m['class']) as String?;
      if (category != 'place' && category != 'boundary') continue;
      final addr = (m['address'] as Map?)?.cast<String, dynamic>() ?? const {};
      final name = (m['name'] as String?)?.trim();
      if (name == null || name.isEmpty) continue;
      out.add(
        PlaceSearchResult(
          name: name,
          admin1:
              (addr['state'] ?? addr['province'] ?? addr['region'] ?? '')
                  as String,
          country: (addr['country'] ?? '') as String,
          lat: double.parse(m['lat'].toString()),
          lon: double.parse(m['lon'].toString()),
          source: PlaceSearchSource.nominatim,
        ),
      );
    }
    return out;
  }

  static List<PlaceSearchResult> parseOpenMeteo(Map<String, dynamic> json) {
    final results = json['results'] as List? ?? const [];
    return [
      for (final raw in results)
        PlaceSearchResult(
          name: raw['name'] as String,
          admin1: (raw['admin1'] ?? '') as String,
          country: (raw['country'] ?? '') as String,
          lat: (raw['latitude'] as num).toDouble(),
          lon: (raw['longitude'] as num).toDouble(),
          timezone: raw['timezone'] as String?,
          source: PlaceSearchSource.openMeteo,
        ),
    ];
  }

  static Uri reverseUri(double lat, double lon) =>
      Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': lat.toStringAsFixed(4),
        'lon': lon.toStringAsFixed(4),
        'format': 'jsonv2',
        'addressdetails': '1',
        'accept-language': 'ja',
        'zoom': '10', // 市区町村の単位
      });

  @override
  Future<PlaceSearchResult> reverse(double lat, double lon) async {
    final json = await _getJson(
      reverseUri(lat, lon),
      headers: {'User-Agent': userAgent, 'Accept-Language': 'ja'},
    ) as Map<String, dynamic>;
    return parseReverse(json, lat, lon);
  }

  /// 逆引きの結果。地名が取れなければ「現在地」とし、座標は端末の値を使う
  static PlaceSearchResult parseReverse(
    Map<String, dynamic> json,
    double lat,
    double lon,
  ) {
    final addr = (json['address'] as Map?)?.cast<String, dynamic>() ?? const {};
    String? pick(List<String> keys) {
      for (final k in keys) {
        final v = (k == 'name' ? json['name'] : addr[k]) as String?;
        if (v != null && v.trim().isNotEmpty) return v.trim();
      }
      return null;
    }

    return PlaceSearchResult(
      name:
          pick(['name', 'city', 'town', 'village', 'municipality', 'county']) ??
          '現在地',
      admin1: pick(['state', 'province', 'region']) ?? '',
      country: pick(['country']) ?? '',
      lat: lat,
      lon: lon,
      source: PlaceSearchSource.nominatim,
    );
  }

  /// 予報APIの timezone=auto で、座標のタイムゾーンを求める
  static Uri timezoneUri(double lat, double lon) =>
      Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': lat.toStringAsFixed(4),
        'longitude': lon.toStringAsFixed(4),
        'daily': 'temperature_2m_max',
        'forecast_days': '1',
        'timezone': 'auto',
      });

  @override
  Future<String> resolveTimezone(double lat, double lon) async {
    final json = await _getJson(timezoneUri(lat, lon)) as Map<String, dynamic>;
    final tz = json['timezone'] as String?;
    if (tz == null || tz.isEmpty || tz == 'GMT') {
      throw PlaceSearchException('この場所の時間帯を確認できませんでした');
    }
    return tz;
  }
}
