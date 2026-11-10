import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_weather/data/place_search.dart';

/// Nominatimの応答の見本（「東京」）
const nominatimTokyo = [
  {
    'lat': '35.6768601',
    'lon': '139.7638947',
    'category': 'boundary',
    'type': 'administrative',
    'addresstype': 'province',
    'name': '東京都',
    'address': {'province': '東京都', 'country': '日本', 'country_code': 'jp'},
  },
  {
    'lat': '35.68',
    'lon': '139.76',
    'category': 'railway',
    'type': 'station',
    'name': '東京駅',
    'address': {'country': '日本'},
  },
];

/// Open-Meteo Geocodingの応答の見本（「Paris」）
const openMeteoParis = {
  'results': [
    {
      'name': 'パリ',
      'latitude': 48.85341,
      'longitude': 2.3488,
      'country': 'フランス',
      'admin1': 'イル＝ド＝フランス地域圏',
      'timezone': 'Europe/Paris',
    },
  ],
};

http.Response jsonRes(Object body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test('日本語はNominatimで検索し、識別できるUser-Agentを付ける', () async {
    final requests = <http.Request>[];
    final api = HttpPlaceSearch(
      client: MockClient((req) async {
        requests.add(req);
        return jsonRes(nominatimTokyo);
      }),
    );
    final out = await api.search(' 東京 ');

    expect(requests.single.url.host, 'nominatim.openstreetmap.org');
    expect(requests.single.url.queryParameters['q'], '東京');
    expect(requests.single.headers['User-Agent'], startsWith('MyWeather/'));
    expect(out.usedNominatim, isTrue);
    // 駅などは地名として扱わない
    expect(out.results.single.name, '東京都');
    expect(out.results.single.admin1, '東京都');
    expect(out.results.single.country, '日本');
    expect(out.results.single.timezone, isNull);
  });

  test('ローマ字はOpen-Meteo Geocodingで検索し、タイムゾーンも受け取る', () async {
    final hosts = <String>[];
    final api = HttpPlaceSearch(
      client: MockClient((req) async {
        hosts.add(req.url.host);
        return jsonRes(openMeteoParis);
      }),
    );
    final out = await api.search('Paris');
    expect(hosts, ['geocoding-api.open-meteo.com']);
    expect(out.usedNominatim, isFalse);
    expect(out.results.single.timezone, 'Europe/Paris');
    expect(out.results.single.name, 'パリ');
  });

  test('ローマ字で0件なら、Nominatimでも探す', () async {
    final hosts = <String>[];
    final api = HttpPlaceSearch(
      client: MockClient((req) async {
        hosts.add(req.url.host);
        return req.url.host.startsWith('geocoding')
            ? jsonRes({'generationtime_ms': 0.1})
            : jsonRes(nominatimTokyo);
      }),
    );
    final out = await api.search('Tokyo-to');
    expect(hosts, [
      'geocoding-api.open-meteo.com',
      'nominatim.openstreetmap.org',
    ]);
    expect(out.usedNominatim, isTrue);
    expect(out.results, hasLength(1));
  });

  test('ハングルなどASCII以外もNominatimで検索する', () {
    expect(needsNominatim('서울'), isTrue);
    expect(needsNominatim('ソウル'), isTrue);
    expect(needsNominatim('Seoul'), isFalse);
  });

  test('座標のタイムゾーンは予報APIの timezone=auto で求める', () async {
    late Uri asked;
    final api = HttpPlaceSearch(
      client: MockClient((req) async {
        asked = req.url;
        return jsonRes({'timezone': 'Asia/Seoul', 'utc_offset_seconds': 32400});
      }),
    );
    expect(await api.resolveTimezone(37.56, 126.97), 'Asia/Seoul');
    expect(asked.host, 'api.open-meteo.com');
    expect(asked.queryParameters['timezone'], 'auto');
  });

  test('通信できないときは、分かる言葉で伝える', () async {
    final api = HttpPlaceSearch(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    expect(
      () => api.search('東京'),
      throwsA(
        isA<PlaceSearchException>().having(
          (e) => e.message,
          'message',
          contains('通信できない'),
        ),
      ),
    );
  });

  test('現在地の座標から、市区町村の名前を逆引きする', () async {
    late http.Request asked;
    final api = HttpPlaceSearch(
      client: MockClient((req) async {
        asked = req;
        return jsonRes({
          'name': '名古屋市',
          'address': {'city': '名古屋市', 'province': '愛知県', 'country': '日本'},
        });
      }),
    );
    final r = await api.reverse(35.1815, 136.9066);
    expect(asked.url.path, '/reverse');
    expect(asked.headers['User-Agent'], startsWith('MyWeather/'));
    expect(r.name, '名古屋市');
    expect(r.admin1, '愛知県');
    expect(r.country, '日本');
    expect(r.lat, 35.1815); // 座標は端末の値のまま

    // 地名が取れない海上などは「現在地」
    final sea = HttpPlaceSearch.parseReverse(
      {'error': 'Unable to geocode'},
      30,
      140,
    );
    expect(sea.name, '現在地');
  });
}
