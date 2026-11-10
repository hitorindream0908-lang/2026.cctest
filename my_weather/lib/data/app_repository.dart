import '../models/app_settings.dart';
import '../models/location.dart';

/// 端末内データの読み書き。画面や状態はこの抽象だけに依存する
/// （フェーズ2でサーバー同期を足すときの差し替え口にもなる）。
abstract class AppRepository {
  Future<AppSettings> loadSettings();
  Future<void> saveSettings(AppSettings settings);

  Future<List<Location>> listLocations();

  /// 追加して、採番済みの場所を返す
  Future<Location> insertLocation(Location location);
  Future<void> deleteLocation(int id);

  /// 天気キャッシュ（場所ごとに最新1件）
  Future<WeatherCacheEntry?> loadWeatherCache(int locationId);
  Future<void> saveWeatherCache(int locationId, WeatherCacheEntry entry);
}

class WeatherCacheEntry {
  const WeatherCacheEntry({required this.json, required this.fetchedAt});

  /// 予報のJSON一式
  final String json;
  final DateTime fetchedAt;
}
