import 'package:flutter/material.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/play_activity_heatmap.dart';
import 'package:election_game/domain/repositories/election_archive_repository.dart';
import 'package:election_game/domain/services/play_activity_heatmap_service.dart';

/// 選挙プレイの活動ヒートマップ画面。
///
/// 選挙を実施した日付を GitHub 風のセルグリッドで可視化する。
/// 試練では [electionsOverride] と [now] を注入して repository 読込を回避できる。
class PlayActivityHeatmapScreen extends StatefulWidget {
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
  State<PlayActivityHeatmapScreen> createState() =>
      _PlayActivityHeatmapScreenState();
}

class _PlayActivityHeatmapScreenState extends State<PlayActivityHeatmapScreen> {
  List<Election>? _elections;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final override = widget.electionsOverride;
    if (override != null) {
      _elections = List<Election>.of(override);
      _loading = false;
    } else {
      _loadElections();
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
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final elections = _elections ?? const <Election>[];
    final hm = PlayActivityHeatmapService.build(
      elections,
      now: widget.now ?? DateTime.now(),
    );

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
                      PlayActivityHeatmapService.levelOf(day.count, hm.maxCount),
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
