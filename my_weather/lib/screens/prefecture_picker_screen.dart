import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/prefectures.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// 都道府県から選ぶ画面。47都道府県を地方ごとに並べ、
/// タップでその県庁所在地を場所として登録する（登録済みなら切り替えるだけ）。
///
/// 閉じるときに、結果を伝える一文を返す。
class PrefecturePickerScreen extends StatelessWidget {
  const PrefecturePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = AppPalette.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('都道府県から選ぶ')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppTheme.pagePadding,
          8,
          AppTheme.pagePadding,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          Text(
            '選んだ都道府県の県庁所在地（東京都は都庁のある新宿区）が場所として登録され、'
            'その地点の予報を表示します。',
            style: TextStyle(color: p.subText, fontSize: 13, height: 1.5),
          ),
          for (final region in prefectureRegions) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 28, 4, 10),
              child: Text(
                region.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  for (final pref in region.prefectures)
                    _PrefectureRow(
                      pref: pref,
                      registered:
                          state.findRegistered(pref.toLocation(state.now())) !=
                          null,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PrefectureRow extends StatelessWidget {
  const _PrefectureRow({required this.pref, required this.registered});

  final PrefectureCapital pref;
  final bool registered;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return InkWell(
      onTap: () async {
        final state = context.read<AppState>();
        final (result, location) = await state.addOrSelect(
          pref.toLocation(state.now()),
        );
        if (!context.mounted) return;
        Navigator.of(context).pop(
          result == AddLocationResult.added
              ? '${location.name}（${pref.prefecture}）を追加しました'
              : '${location.name}は追加済みのため、表示をこの場所に切り替えました',
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.cardPadding,
          vertical: 11,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pref.prefecture,
                    style: TextStyle(
                      color: p.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${pref.seatLabel}: ${pref.capital}',
                    style: TextStyle(color: p.subText, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (registered)
              Text('追加済み', style: TextStyle(color: p.subText, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
