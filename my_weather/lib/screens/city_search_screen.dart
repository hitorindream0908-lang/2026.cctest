import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/place_search.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// 都市名で検索して場所を追加する画面。
/// 閉じるときに、結果を伝える一文を返す。
class CitySearchScreen extends StatefulWidget {
  const CitySearchScreen({super.key});

  @override
  State<CitySearchScreen> createState() => _CitySearchScreenState();
}

class _CitySearchScreenState extends State<CitySearchScreen> {
  final _controller = TextEditingController();
  bool _searching = false;
  bool _adding = false;
  String? _error;
  PlaceSearchOutcome? _outcome;
  String _lastQuery = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.isEmpty || _searching) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final outcome = await context.read<PlaceSearchApi>().search(q);
      if (!mounted) return;
      setState(() {
        _outcome = outcome;
        _lastQuery = q;
      });
    } on PlaceSearchException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _add(PlaceSearchResult r) async {
    if (_adding) return;
    final state = context.read<AppState>();
    final api = context.read<PlaceSearchApi>();
    setState(() {
      _adding = true;
      _error = null;
    });
    try {
      // 登録済みなら、タイムゾーンを調べずにそのまま切り替える
      final existing = state.findRegistered(
        r.toLocation(r.timezone ?? 'UTC', state.now()),
      );
      final tz =
          existing?.timezone ??
          r.timezone ??
          await api.resolveTimezone(r.lat, r.lon);
      final (result, location) = await state.addOrSelect(
        r.toLocation(tz, state.now()),
      );
      if (!mounted) return;
      Navigator.of(context).pop(
        result == AddLocationResult.added
            ? '${location.name}を追加しました'
            : '${location.name}は追加済みのため、表示をこの場所に切り替えました',
      );
    } on PlaceSearchException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = AppPalette.of(context);
    final outcome = _outcome;

    return Scaffold(
      appBar: AppBar(title: const Text('都市名で検索')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppTheme.pagePadding,
          8,
          AppTheme.pagePadding,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          Container(
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(999),
            ),
            padding: const EdgeInsets.only(left: 20, right: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: const InputDecoration(
                      hintText: '例: 東京、札幌、ソウル、パリ、London',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: _searching ? null : _search,
                  child: const Text('検索'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '日本語でも、ローマ字でも検索できます。',
              style: TextStyle(color: p.subText, fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),
          if (_searching || _adding)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _error!,
                style: TextStyle(color: p.text, fontSize: 15),
              ),
            ),
          if (outcome != null && !_searching) ...[
            if (outcome.results.isEmpty)
              Text(
                '「$_lastQuery」に当てはまる場所が見つかりませんでした。'
                '別の書き方（例: ひらがな、ローマ字、市区町村名）でもお試しください。',
                style: TextStyle(color: p.subText, fontSize: 15, height: 1.5),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    for (final r in outcome.results)
                      _ResultRow(
                        result: r,
                        registered:
                            state.findRegistered(
                              r.toLocation(r.timezone ?? 'UTC', state.now()),
                            ) !=
                            null,
                        onTap: _adding ? null : () => _add(r),
                      ),
                  ],
                ),
              ),
            if (outcome.usedNominatim) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '地名データ © OpenStreetMap contributors',
                  style: TextStyle(color: p.subText, fontSize: 12),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.result,
    required this.registered,
    required this.onTap,
  });

  final PlaceSearchResult result;
  final bool registered;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final area = [
      if (result.admin1 != result.name) result.admin1,
      result.country,
    ].where((s) => s.isNotEmpty).join('・');
    return InkWell(
      onTap: onTap,
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
                    result.name,
                    style: TextStyle(
                      color: p.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (area.isNotEmpty)
                    Text(
                      area,
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
