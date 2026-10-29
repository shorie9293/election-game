import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/play_activity_heatmap.dart';
import 'package:election_game/domain/repositories/election_archive_repository.dart';
import 'package:election_game/domain/services/play_activity_heatmap_service.dart';
import 'package:election_game/features/lifecycle/presentation/day_rollover_providers.dart';

/// 選挙プレイの活動ヒートマップ画面。
///
/// 選挙を実施した日付を GitHub 風のセルグリッドで可視化する。
/// 試練では [electionsOverride] と [now] を注入して repository 読込を回避できる。
///
/// どちらも未注入の本番経路では [playActivityHeatmapProvider] を watch する。
/// 同 Provider は「今日」依存（currentStreak）なので、日付跨ぎの前面復帰時に
/// ルートの `AppLifecycleRefresher` が invalidate して再計算させる。
class PlayActivityHeatmapScreen extends ConsumerStatefulWidget {
  /// 試練用：null なら repository から読み込む。
  final List<Election>? electionsOverride;

  /// 選挙アーカイブの一次情報源（試練では差し替え可能）。
  final ElectionArchiveRepository repository;

  /// 試練用：null なら DateTime.now()。
  final DateTime? now;

  const PlayActivityHeatmapScreen({
    super.key,
    this.electionsOverride,
    this.repository = const SharedPreferencesElectionArchiveRepository(),
    this.now,
  });

  @override
  ConsumerState<PlayActivityHeatmapScreen> createState() =>
      _PlayActivityHeatmapScreenState();
}

class _PlayActivityHeatmapScreenState
    extends ConsumerState<PlayActivityHeatmapScreen> {
  List<Election>? _elections;
  bool _loading = true;
  bool _providerAvailable = false;
  bool _resolvedSource = false;

  /// 試練用の注入が無く、ProviderScope 配下の本番経路なら Provider を watch する。
  bool get _viaProvider =>
      widget.electionsOverride == null &&
      widget.now == null &&
      _providerAvailable;

  @override
  void initState() {
    super.initState();
    final override = widget.electionsOverride;
    if (override != null) {
      _elections = List<Election>.of(override);
      _loading = false;
    }
    // 注入が無い場合は didChangeDependencies で ProviderScope の有無を
    // 見てから読み込み経路（Provider / repository）を決める。
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resolvedSource) return;
    _resolvedSource = true;
    if (widget.electionsOverride != null) return;

    _providerAvailable = _hasProviderScope;
    if (_viaProvider) {
      // Provider（FutureProvider）が読み込みを担う。
      _loading = false;
    } else {
      // ProviderScope 外（ウィジェット単体試練など）は従来どおり repository。
      _loadElections();
    }
  }

  /// 祖先に [ProviderScope] があるか。
  ///
  /// ProviderScope を持たない単体マウント（試練）でも画面が壊れないよう、
  /// 無い場合は repository 経路へフォールバックする。
  bool get _hasProviderScope {
    try {
      ProviderScope.containerOf(context, listen: false);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadElections() async {
    try {
      final elections = await widget.repository.load();
      if (!mounted) return;
      setState(() {
        _elections = elections;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _elections = const [];
        _loading = false;
      });
    }
  }

  /// level(0..4) → ヒートマップセルの濃淡色。
  Color _levelColor(int level) {
    switch (level) {
      case 0:
        return RetroPalette.panelBg;
      case 1:
        return RetroPalette.panelBorder;
      case 2:
        return RetroPalette.voteAbstain;
      case 3:
        return RetroPalette.textAccent;
      case 4:
      default:
        return RetroPalette.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_viaProvider) {
      // 本番経路: 日付跨ぎで invalidate される Provider を watch する。
      final async = ref.watch(playActivityHeatmapProvider);
      return async.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        // 読込失敗は空表示（従来の repository 失敗時と同じ振る舞い）。
        error: (_, __) => _buildHeatmap(
          PlayActivityHeatmapService.build(const [], now: DateTime.now()),
        ),
        data: _buildHeatmap,
      );
    }

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final elections = _elections ?? const <Election>[];
    final hm = PlayActivityHeatmapService.build(
      elections,
      now: widget.now ?? DateTime.now(),
    );

    return _buildHeatmap(hm);
  }

  Widget _buildHeatmap(PlayActivityHeatmap hm) {
    return Scaffold(
      backgroundColor: RetroPalette.bgDark,
      appBar: AppBar(title: const Text('選挙プレイの歩み')),
      body: hm.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  key: AppKeys.playHeatmapEmpty,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.calendar_month,
                      color: RetroPalette.voteAbstain,
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'まだ記録がありません。\n選挙を重ねるとここに記録されます。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: RetroPalette.textNormal,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryCard(hm: hm),
                  const SizedBox(height: 16),
                  _HeatmapGrid(hm: hm, levelColor: _levelColor),
                  const SizedBox(height: 12),
                  _Legend(levelColor: _levelColor),
                ],
              ),
            ),
    );
  }
}

/// 総選挙回数・活動日数・最長連続・最多日を表示するサマリーカード。
class _SummaryCard extends StatelessWidget {
  final PlayActivityHeatmap hm;

  const _SummaryCard({required this.hm});

  String _busiestLabel() {
    final day = hm.busiestDay;
    if (day == null) return '—';
    final key = PlayActivityHeatmapService.dateKey(day.date);
    return '$key（${day.count}回）';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: AppKeys.playHeatmapSummary,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RetroPalette.panelBg,
        border: Border.all(color: RetroPalette.panelBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '活動サマリー',
            style: TextStyle(
              color: RetroPalette.gold,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '総選挙回数: ${hm.totalElections}回',
            style: const TextStyle(color: RetroPalette.textNormal),
          ),
          Text(
            '活動日数: ${hm.activeDays}日',
            style: const TextStyle(color: RetroPalette.textNormal),
          ),
          Text(
            '最長連続: ${hm.longestStreak}日',
            style: const TextStyle(color: RetroPalette.textNormal),
          ),
          Text(
            '最多日: ${_busiestLabel()}',
            style: const TextStyle(color: RetroPalette.textNormal),
          ),
        ],
      ),
    );
  }
}

/// ヒートマップグリッド（列=週、行=曜日・日曜始まり）。
class _HeatmapGrid extends StatelessWidget {
  final PlayActivityHeatmap hm;
  final Color Function(int level) levelColor;

  const _HeatmapGrid({required this.hm, required this.levelColor});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        key: AppKeys.playHeatmapGrid,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final week in hm.weeks)
            Column(
              children: [
                for (final day in week.days)
                  _Cell(
                    day: day,
                    color: levelColor(
                      PlayActivityHeatmapService.levelOf(
                          day.count, hm.maxCount),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// 1日分のセル。Tooltip で日付と回数を提示する。
class _Cell extends StatelessWidget {
  final PlayActivityDay day;
  final Color color;

  const _Cell({required this.day, required this.color});

  @override
  Widget build(BuildContext context) {
    final key = PlayActivityHeatmapService.dateKey(day.date);
    return Tooltip(
      message: '$key: ${day.count}回',
      child: Container(
        key: AppKeys.playHeatmapCell(key),
        width: 18,
        height: 18,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: RetroPalette.panelBorder.withValues(alpha: 0.5),
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(3),
        ),
        alignment: Alignment.center,
        child: day.count > 0
            ? Text(
                '${day.count}',
                style: const TextStyle(
                  color: RetroPalette.bgDark,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }
}

/// 5段階の濃淡凡例。
class _Legend extends StatelessWidget {
  final Color Function(int level) levelColor;

  const _Legend({required this.levelColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      key: AppKeys.playHeatmapLegend,
      children: [
        const Text(
          '少',
          style: TextStyle(color: RetroPalette.textNormal, fontSize: 12),
        ),
        const SizedBox(width: 4),
        for (var level = 0; level <= 4; level++) ...[
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: levelColor(level),
              border: Border.all(
                color: RetroPalette.panelBorder.withValues(alpha: 0.5),
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
        const SizedBox(width: 4),
        const Text(
          '多',
          style: TextStyle(color: RetroPalette.textNormal, fontSize: 12),
        ),
      ],
    );
  }
}
