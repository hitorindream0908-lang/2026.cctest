import 'package:flutter/foundation.dart';

import '../data/app_repository.dart';
import '../models/app_settings.dart';
import '../models/location.dart';

enum AddLocationResult { added, alreadyRegistered }

/// アプリ全体の状態。画面はこれを見て描画し、操作はここを通してDBへ保存する。
class AppState extends ChangeNotifier {
  AppState(this._repo, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppRepository _repo;
  final DateTime Function() _clock;

  AppSettings _settings = const AppSettings();
  List<Location> _locations = const [];

  AppSettings get settings => _settings;
  List<Location> get locations => List.unmodifiable(_locations);
  DateTime now() => _clock();

  Location? get selectedLocation => _byId(_settings.selectedLocationId);
  Location? get homeLocation => _byId(_settings.homeLocationId);

  Location? _byId(int? id) {
    if (id == null) return null;
    for (final l in _locations) {
      if (l.id == id) return l;
    }
    return null;
  }

  Future<void> load() async {
    _settings = await _repo.loadSettings();
    _locations = await _repo.listLocations();
    await _repairReferences();
    notifyListeners();
  }

  /// 登録済みの同じ場所があれば返す
  Location? findRegistered(Location candidate) {
    for (final l in _locations) {
      if (l.isSamePlaceAs(candidate)) return l;
    }
    return null;
  }

  /// 場所を追加して表示対象にする。登録済みなら追加せず、その場所に切り替える。
  /// 最初の1件は自宅にもする。
  Future<(AddLocationResult, Location)> addOrSelect(Location candidate) async {
    final existing = findRegistered(candidate);
    if (existing != null) {
      await select(existing.id!);
      return (AddLocationResult.alreadyRegistered, existing);
    }
    final saved = await _repo.insertLocation(candidate);
    _locations = [..._locations, saved];
    _settings = _settings.copyWith(
      selectedLocationId: () => saved.id,
      homeLocationId: _settings.homeLocationId == null ? () => saved.id : null,
    );
    await _repo.saveSettings(_settings);
    notifyListeners();
    return (AddLocationResult.added, saved);
  }

  Future<void> select(int id) async {
    _settings = _settings.copyWith(selectedLocationId: () => id);
    await _repo.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setHome(int id) async {
    _settings = _settings.copyWith(homeLocationId: () => id);
    await _repo.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> deleteLocation(int id) async {
    await _repo.deleteLocation(id);
    _locations = _locations.where((l) => l.id != id).toList();
    await _repairReferences();
    notifyListeners();
  }

  /// 自宅や表示中の場所が消えていたら付け直す（自宅 → 先頭の場所の順）。
  Future<void> _repairReferences() async {
    var s = _settings;
    if (_byId(s.homeLocationId) == null) {
      final first = _locations.isEmpty ? null : _locations.first.id;
      s = s.copyWith(homeLocationId: () => first);
    }
    if (_byId(s.selectedLocationId) == null) {
      final fallback = _byId(s.homeLocationId)?.id;
      s = s.copyWith(selectedLocationId: () => fallback);
    }
    if (s.homeLocationId != _settings.homeLocationId ||
        s.selectedLocationId != _settings.selectedLocationId) {
      _settings = s;
      await _repo.saveSettings(_settings);
    }
  }
}
