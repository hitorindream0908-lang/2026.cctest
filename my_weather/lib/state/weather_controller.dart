import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/app_repository.dart';
import '../data/weather_api.dart';
import '../models/forecast.dart';
import '../models/location.dart';

/// 1つの場所の天気の状態
class WeatherView {
  const WeatherView({
    this.forecast,
    this.fetchedAt,
    this.loading = false,
    this.error,
  });

  final Forecast? forecast;

  /// 表示中の予報を取得した時刻
  final DateTime? fetchedAt;
  final bool loading;

  /// 直近の取得に失敗した理由（前回の天気を出しているときも入る）
  final String? error;

  WeatherView copyWith({
    Forecast? forecast,
    DateTime? fetchedAt,
    bool? loading,
    String? Function()? error,
  }) => WeatherView(
    forecast: forecast ?? this.forecast,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    loading: loading ?? this.loading,
    error: error != null ? error() : this.error,
  );
}

/// 天気の取得とキャッシュ（SPEC.md「天気の取得」「非機能の決まり」）。
///
/// - キャッシュが1時間未満なら取り直さない
/// - 取得に失敗したら、前回の天気をそのまま出し、失敗したことを伝える
class WeatherController extends ChangeNotifier {
  WeatherController(this._repo, this._api, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppRepository _repo;
  final WeatherApi _api;
  final DateTime Function() _clock;

  static const maxAge = Duration(hours: 1);

  final Map<int, WeatherView> _views = {};
  final Map<int, Future<void>> _inFlight = {};

  DateTime now() => _clock();

  WeatherView viewFor(int locationId) =>
      _views[locationId] ?? const WeatherView();

  /// 1時間以上前の取得なら古い。端末の時計が戻って取得時刻が未来に
  /// なっている場合も、念のため古いとみなす。
  bool isStale(DateTime fetchedAt) {
    final age = now().difference(fetchedAt);
    return age >= maxAge || age < const Duration(minutes: -5);
  }

  /// 必要なら取り直す。[force] は更新ボタン用で、キャッシュの新しさを問わない。
  Future<void> ensure(Location location, {bool force = false}) {
    final id = location.id!;
    // 同じ場所の取得が進行中なら、それを待つ（二重に通信しない）。
    // 後始末で remove の戻り値（この Future 自身）を返すと自分を待ち続けるので、
    // 値を返さないブロックにする。
    return _inFlight[id] ??= _ensure(location, force).whenComplete(() {
      _inFlight.remove(id);
    });
  }

  Future<void> _ensure(Location location, bool force) async {
    final id = location.id!;
    var view = viewFor(id);

    // メモリになければ端末内のキャッシュを読む
    if (view.forecast == null) {
      final cached = await _repo.loadWeatherCache(id);
      if (cached != null) {
        view = view.copyWith(
          forecast: Forecast.fromOpenMeteo(
            jsonDecode(cached.json) as Map<String, dynamic>,
          ),
          fetchedAt: cached.fetchedAt,
        );
        _set(id, view);
      }
    }

    final fresh = view.fetchedAt != null && !isStale(view.fetchedAt!);
    if (fresh && !force) return;

    _set(id, view.copyWith(loading: true));
    try {
      final json = await _api.fetchForecast(location);
      final forecast = Forecast.fromOpenMeteo(json);
      final fetchedAt = now();
      await _repo.saveWeatherCache(
        id,
        WeatherCacheEntry(json: jsonEncode(json), fetchedAt: fetchedAt),
      );
      _set(id, WeatherView(forecast: forecast, fetchedAt: fetchedAt));
    } catch (e) {
      final message = e is WeatherFetchException
          ? e.message
          : '通信できないため、天気を取得できませんでした';
      _set(id, viewFor(id).copyWith(loading: false, error: () => message));
    }
  }

  void _set(int id, WeatherView v) {
    _views[id] = v;
    notifyListeners();
  }

  /// 場所を消したときにメモリ上の状態も消す（DBのキャッシュは連動して消える）
  void forget(int locationId) {
    _views.remove(locationId);
  }
}
