import 'package:my_weather/data/app_repository.dart';
import 'package:my_weather/models/app_settings.dart';
import 'package:my_weather/models/location.dart';

/// テスト用の、メモリ上だけのリポジトリ
class MemoryRepository implements AppRepository {
  AppSettings settings = const AppSettings();
  final List<Location> rows = [];
  int _nextId = 1;

  @override
  Future<AppSettings> loadSettings() async => settings;

  @override
  Future<void> saveSettings(AppSettings s) async => settings = s;

  @override
  Future<List<Location>> listLocations() async => List.of(rows);

  @override
  Future<Location> insertLocation(Location l) async {
    final saved = l.copyWith(id: _nextId++);
    rows.add(saved);
    return saved;
  }

  @override
  Future<void> deleteLocation(int id) async =>
      rows.removeWhere((l) => l.id == id);
}
