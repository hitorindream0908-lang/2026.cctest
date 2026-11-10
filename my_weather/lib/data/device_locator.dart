import 'package:geolocator/geolocator.dart';

/// 位置情報の利用状態
enum LocatorStatus {
  /// 端末の位置情報サービスがオフ
  serviceDisabled,

  /// まだ許可されていない（ダイアログで聞ける）
  denied,

  /// 許可されず、もうダイアログでは聞けない（設定アプリで変える）
  deniedForever,
  granted,
}

class LocatorException implements Exception {
  LocatorException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// 端末の現在地。テストでは差し替える。
abstract class DeviceLocator {
  Future<LocatorStatus> status();

  /// 許可ダイアログを出して、その結果を返す
  Future<LocatorStatus> request();

  /// 現在地の緯度・経度。取れなければ [LocatorException]
  Future<(double lat, double lon)> current();

  Future<void> openAppSettings();
  Future<void> openLocationSettings();
}

class GeolocatorDeviceLocator implements DeviceLocator {
  LocatorStatus _map(LocationPermission p) => switch (p) {
    LocationPermission.always ||
    LocationPermission.whileInUse => LocatorStatus.granted,
    LocationPermission.deniedForever => LocatorStatus.deniedForever,
    _ => LocatorStatus.denied,
  };

  @override
  Future<LocatorStatus> status() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocatorStatus.serviceDisabled;
    }
    return _map(await Geolocator.checkPermission());
  }

  @override
  Future<LocatorStatus> request() async =>
      _map(await Geolocator.requestPermission());

  @override
  Future<(double, double)> current() async {
    try {
      // 天気には市区町村ほどの精度で足りるので、低い精度で取る
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return (pos.latitude, pos.longitude);
    } catch (_) {
      // 時間切れなどのときは、直近に分かっている位置を使う
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return (last.latitude, last.longitude);
      throw LocatorException('現在地を取得できませんでした');
    }
  }

  @override
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}
