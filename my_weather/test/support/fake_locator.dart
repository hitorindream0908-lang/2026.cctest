import 'package:my_weather/data/device_locator.dart';

/// 偽の現在地。許可の状態と、許可ダイアログでの答えを決めておける
class FakeLocator implements DeviceLocator {
  FakeLocator({
    this.initial = LocatorStatus.granted,
    this.answer = LocatorStatus.granted,
    this.position = (35.0116, 135.7681), // 京都
  });

  LocatorStatus initial;
  LocatorStatus answer;
  (double, double)? position;
  int requests = 0;
  int appSettingsOpened = 0;
  int locationSettingsOpened = 0;

  @override
  Future<LocatorStatus> status() async => initial;

  @override
  Future<LocatorStatus> request() async {
    requests++;
    initial = answer;
    return answer;
  }

  @override
  Future<(double, double)> current() async {
    final p = position;
    if (p == null) throw LocatorException('現在地を取得できませんでした');
    return p;
  }

  @override
  Future<void> openAppSettings() async => appSettingsOpened++;

  @override
  Future<void> openLocationSettings() async => locationSettingsOpened++;
}
