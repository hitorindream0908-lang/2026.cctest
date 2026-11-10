import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/location.dart';
import '../state/app_state.dart';
import '../state/weather_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/tab_page.dart';
import 'city_search_screen.dart';
import 'current_location_flow.dart';
import 'prefecture_picker_screen.dart';

/// 場所タブ。登録済みの一覧（タップで表示対象を切り替え）、自宅の指定、追加。
class PlacesScreen extends StatelessWidget {
  const PlacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = AppPalette.of(context);
    final locations = state.locations;

    return TabPage(
      title: '場所',
      children: [
        if (locations.isEmpty)
          const PlaceholderCard(message: 'まだ場所が登録されていません。下の方法で追加してください。')
        else
          _Section(
            children: [
              for (final l in locations)
                _LocationRow(
                  location: l,
                  selected: l.id == state.settings.selectedLocationId,
                  home: l.id == state.settings.homeLocationId,
                ),
            ],
          ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text('場所を追加', style: Theme.of(context).textTheme.titleLarge),
        ),
        _Section(
          children: [
            _AddRow(
              icon: Icons.near_me_outlined,
              title: '現在地',
              note: '端末の位置情報から登録します',
              onTap: () => _report(context, addCurrentLocation(context)),
            ),
            _AddRow(
              icon: Icons.search,
              title: '都市名で検索',
              note: '日本語でもローマ字でも探せます',
              onTap: () => _openAndReport(context, const CitySearchScreen()),
            ),
            _AddRow(
              icon: Icons.map_outlined,
              title: '都道府県から選ぶ',
              note: '県庁所在地の天気を表示します',
              onTap: () =>
                  _openAndReport(context, const PrefecturePickerScreen()),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '場所をタップすると、今日タブに表示する場所が切り替わります。',
            style: TextStyle(color: p.subText, fontSize: 13),
          ),
        ),
      ],
    );
  }

  /// 追加用の画面を開き、閉じたときに結果の一文を下に出す
  Future<void> _openAndReport(BuildContext context, Widget screen) => _report(
    context,
    Navigator.of(context)
        .push<String>(MaterialPageRoute(builder: (_) => screen)),
  );

  Future<void> _report(BuildContext context, Future<String?> action) async {
    final message = await action;
    if (message != null && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

/// 面の中に行を並べる。区切り線は使わず、行間の余白で区切る。
class _Section extends StatelessWidget {
  const _Section({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.of(context).surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(children: children),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.location,
    required this.selected,
    required this.home,
  });

  final Location location;
  final bool selected;
  final bool home;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final state = context.read<AppState>();
    final area = location.areaLabel;

    return InkWell(
      onTap: () => state.select(location.id!),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppTheme.cardPadding, 10, 8, 10),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: selected
                  ? Icon(Icons.check, color: p.text, size: 22)
                  : null,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          location.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: p.text,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (home) ...[
                        const SizedBox(width: 8),
                        const _HomeBadge(),
                      ],
                    ],
                  ),
                  if (area.isNotEmpty)
                    Text(
                      area,
                      style: TextStyle(color: p.subText, fontSize: 13),
                    ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz, color: p.subText),
              tooltip: 'その他の操作',
              onSelected: (v) async {
                if (v == 'home') {
                  await state.setHome(location.id!);
                } else if (v == 'delete') {
                  final ok = await _confirmDelete(context);
                  if (ok) {
                    if (!context.mounted) return;
                    context.read<WeatherController>().forget(location.id!);
                    await state.deleteLocation(location.id!);
                  }
                }
              },
              itemBuilder: (_) => [
                if (!home)
                  const PopupMenuItem(value: 'home', child: Text('自宅にする')),
                const PopupMenuItem(value: 'delete', child: Text('削除')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${location.name}を削除しますか？'),
        content: const Text('登録した場所の一覧から外します。服装の記録は消えません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _HomeBadge extends StatelessWidget {
  const _HomeBadge();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: p.text,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '自宅',
        style: TextStyle(
          color: p.background,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AddRow extends StatelessWidget {
  const _AddRow({
    required this.icon,
    required this.title,
    required this.note,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String note;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.cardPadding,
            vertical: 12,
          ),
          child: Row(
            children: [
              Icon(icon, color: p.text),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: p.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      note,
                      style: TextStyle(color: p.subText, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (enabled) Icon(Icons.chevron_right, color: p.subText),
            ],
          ),
        ),
      ),
    );
  }
}
