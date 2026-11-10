import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/device_locator.dart';
import '../data/place_search.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'city_search_screen.dart';

/// 現在地を場所として追加する一連の流れ。
///
/// 1. 位置情報サービスと許可の状態を確かめる
/// 2. まだ許可されていなければ、OSの許可ダイアログの前に使い道を説明する
/// 3. 許可されなかったときは、理由に応じた案内（許可のしかたと、都市名で探す方法）を出す
/// 4. 現在地の座標から地名とタイムゾーンを調べて登録する
///
/// 結果を伝える一文を返す（何もしなかったときはnull）。
Future<String?> addCurrentLocation(BuildContext context) async {
  final locator = context.read<DeviceLocator>();

  var status = await locator.status();
  if (!context.mounted) return null;

  if (status == LocatorStatus.denied) {
    final ok = await _explainBeforeAsking(context);
    if (!ok || !context.mounted) return null;
    status = await locator.request();
    if (!context.mounted) return null;
  }

  if (status != LocatorStatus.granted) {
    return _showGuidance(context, status);
  }

  return _locateAndAdd(context);
}

Future<String?> _locateAndAdd(BuildContext context) async {
  final locator = context.read<DeviceLocator>();
  final search = context.read<PlaceSearchApi>();
  final state = context.read<AppState>();
  final navigator = Navigator.of(context);

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _Progress(),
  );
  String message;
  try {
    final (lat, lon) = await locator.current();
    final place = await search.reverse(lat, lon);
    final tz = await search.resolveTimezone(lat, lon);
    final (result, location) = await state.addOrSelect(
      place.toLocation(tz, state.now()),
    );
    message = result == AddLocationResult.added
        ? '現在地（${location.name}）を追加しました'
        : '現在地は登録済みの${location.name}のため、表示をこの場所に切り替えました';
  } on LocatorException catch (e) {
    message = '${e.message}。少し待ってからもう一度試すか、都市名で検索してください';
  } on PlaceSearchException catch (e) {
    message = '${e.message}。通信できる場所でもう一度お試しください';
  } finally {
    navigator.pop(); // 進行中の表示を閉じる
  }
  return message;
}

class _Progress extends StatelessWidget {
  const _Progress();

  @override
  Widget build(BuildContext context) {
    return const PopScope(
      canPop: false,
      child: Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('現在地を調べています…'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// OSの許可ダイアログを出す前に、位置情報の使い道を説明する
Future<bool> _explainBeforeAsking(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _Sheet(
      icon: Icons.near_me_outlined,
      title: '位置情報の利用について',
      body:
          '現在地の天気を表示するために、端末の位置情報を使います。\n\n'
          '・使うのは、場所の登録と天気の取得のときだけです\n'
          '・地名と天気を調べるために、おおよその座標を天気サービス（Open-Meteo）と'
          '地名サービス（OpenStreetMap）に送ります\n'
          '・このあと表示される確認で「アプリの使用中は許可」を選んでください',
      primaryLabel: '続ける',
      onPrimary: () => Navigator.pop(ctx, true),
      secondaryLabel: '今はやめる',
      onSecondary: () => Navigator.pop(ctx, false),
    ),
  );
  return result ?? false;
}

/// 許可が得られないときの案内。理由ごとに、許可のしかたと代わりの方法を示す。
Future<String?> _showGuidance(
  BuildContext context,
  LocatorStatus status,
) async {
  final locator = context.read<DeviceLocator>();
  final (title, body, settingsLabel, openSettings) = switch (status) {
    LocatorStatus.serviceDisabled => (
      '位置情報サービスがオフです',
      '端末の位置情報サービスがオフになっているため、現在地を取得できません。\n\n'
          'iPhoneの「設定」→「プライバシーとセキュリティ」→「位置情報サービス」をオンにしてから、'
          'もう一度お試しください。\n\n'
          '位置情報を使わずに、都市名で検索して登録することもできます。',
      '設定を開く',
      locator.openLocationSettings,
    ),
    LocatorStatus.deniedForever => (
      '位置情報が許可されていません',
      'My Weatherに位置情報の利用が許可されていないため、現在地を取得できません。\n\n'
          '「設定を開く」から「位置情報」を「このAppの使用中のみ許可」に変えると、'
          '現在地を使えるようになります。\n\n'
          '位置情報を使わずに、都市名で検索して登録することもできます。',
      '設定を開く',
      locator.openAppSettings,
    ),
    _ => (
      '位置情報が許可されませんでした',
      '現在地を使うには、位置情報の利用を許可してください。'
          'もう一度「現在地」を押すと、確認が表示されます。\n\n'
          '位置情報を使わずに、都市名で検索して登録することもできます。',
      null,
      null,
    ),
  };

  final choice = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _Sheet(
      icon: Icons.location_off_outlined,
      title: title,
      body: body,
      primaryLabel: settingsLabel ?? '都市名で検索する',
      onPrimary: () =>
          Navigator.pop(ctx, settingsLabel != null ? 'settings' : 'search'),
      secondaryLabel: settingsLabel != null ? '都市名で検索する' : '閉じる',
      onSecondary: () =>
          Navigator.pop(ctx, settingsLabel != null ? 'search' : null),
    ),
  );
  if (!context.mounted) return null;
  if (choice == 'settings') {
    await openSettings?.call();
    return null;
  }
  if (choice == 'search') {
    return Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const CitySearchScreen()));
  }
  return null;
}

class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.icon,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.cardPadding,
          28,
          AppTheme.cardPadding,
          16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(icon, size: 36, color: p.text),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              body,
              style: TextStyle(color: p.text, fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onPrimary, child: Text(primaryLabel)),
            const SizedBox(height: 4),
            TextButton(onPressed: onSecondary, child: Text(secondaryLabel)),
          ],
        ),
      ),
    );
  }
}
