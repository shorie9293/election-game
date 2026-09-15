import 'package:flutter/material.dart';
import 'package:takamagahara_ui/takamagahara_ui.dart' hide AppKeys;

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_archive.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/repositories/election_archive_repository.dart';
import 'package:election_game/domain/services/election_archive_service.dart';

/// 選挙アーカイブ（過去選挙の結果と政策影響の俯瞰）画面。
///
/// エントリは必須で、repository 経由の生選挙リストからでも読み込める。
/// fl_chart 等の新規依存は使わず、LinearProgressIndicator / Container の
/// 幅割合で簡易バー表示する。
class ElectionArchiveScreen extends StatefulWidget {
  /// 表示するアーカイブエントリ（必須）
  final List<ElectionArchiveEntry> entries;

  /// 生選挙の読込・追加先リポジトリ（未指定ならentriesのみで描画）
  final ElectionArchiveRepository? repository;

  /// リポジトリ経由で読む代わりに直接渡す生選挙リスト
  final List<Election>? rawElections;

  const ElectionArchiveScreen({
    super.key,
    required this.entries,
    this.repository,
    this.rawElections,
  });

  @override
  State<ElectionArchiveScreen> createState() => _ElectionArchiveScreenState();
}

class _ElectionArchiveScreenState extends State<ElectionArchiveScreen> {
  ElectionScale? _filter;

  /// repository / rawElections から読み込んだエントリ（nullならwidget.entriesを使う）
  List<ElectionArchiveEntry>? _loadedEntries;

  @override
  void initState() {
    super.initState();
    _loadFromSource();
  }

  Future<void> _loadFromSource() async {
    List<Election>? elections = widget.rawElections;
    if (elections == null && widget.repository != null) {
      try {
        elections = await widget.repository!.load();
      } catch (_) {
        elections = null;
      }
    }
    if (elections == null || !mounted) return;
    final built = ElectionArchiveService.build(elections);
    if (!mounted) return;
    setState(() => _loadedEntries = built);
  }

  /// 実表示に使うエントリ。
  ///
  /// rawElections / repository から読めた場合はそれを優先する。
  /// ホーム画面は GameState を知らないため、repository の直接読込を
  /// 選んだ（GameStateへの依存を広げず、アーカイブ画面単体で完結する）。
  List<ElectionArchiveEntry> get _entries =>
      _loadedEntries ?? widget.entries;

  List<ElectionArchiveEntry> get _filteredEntries {
    final filter = _filter;
    if (filter == null) return _entries;
    return ElectionArchiveService.filterByScale(_entries, filter);
  }

  @override
  Widget build(BuildContext context) {
    final summary = ElectionArchiveService.summarize(_entries);
    final trend = ElectionArchiveService.winnerShareTrend(_entries);
    final reached = ElectionArchiveService.reachedScales(_entries);

    return Scaffold(
      backgroundColor: RetroPalette.bgDark,
      appBar: AppBar(
        title: const Text('選挙アーカイブ', key: AppKeys.archiveTitle),
      ),
      body: _entries.isEmpty
          ? const _EmptyState()
          : _ArchiveBody(
              entries: _entries,
              summary: summary,
              trend: trend,
              reached: reached,
              filtered: _filteredEntries,
              filter: _filter,
              onFilterSelected: (scale) => setState(() => _filter = scale),
            ),
    );
  }
}

/// 0件時の空状態。
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.history, color: RetroPalette.textNormal, size: 48),
          SizedBox(height: 12),
          Text(
            'まだ選挙の記録がありません',
            key: AppKeys.archiveEmptyState,
            style: TextStyle(color: RetroPalette.textNormal),
          ),
        ],
      ),
    );
  }
}

/// アーカイブ本体（サマリー・スケール進行・推移・一覧・絞り込み）。
class _ArchiveBody extends StatelessWidget {
  final List<ElectionArchiveEntry> entries;
  final ElectionArchiveSummary summary;
  final List<double> trend;
  final List<ElectionScale> reached;
  final List<ElectionArchiveEntry> filtered;
  final ElectionScale? filter;
  final ValueChanged<ElectionScale?> onFilterSelected;

  const _ArchiveBody({
    required this.entries,
    required this.summary,
    required this.trend,
    required this.reached,
    required this.filtered,
    required this.filter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryCard(summary: summary),
          const SizedBox(height: 16),
          _ScaleProgression(reached: reached),
          const SizedBox(height: 16),
          _ShareTrend(trend: trend),
          const SizedBox(height: 16),
          _ScaleFilterChips(
            selected: filter,
            onSelected: onFilterSelected,
          ),
          const SizedBox(height: 16),
          _ArchiveList(entries: filtered),
        ],
      ),
    );
  }
}

/// サマリーカード: 総選挙数・平均当選得票率・最大差・最小差・当選者別当選回数。
class _SummaryCard extends StatelessWidget {
  final ElectionArchiveSummary summary;

  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final winCounts = summary.winnerWinCounts.entries
        .map((e) => '${e.key}×${e.value}')
        .join('・');
    return SemanticHelper.interactive(
      testId: 'btn_archive_summary_card',
      label: '選挙アーカイブサマリー',
      child: Container(
        key: AppKeys.archiveSummaryCard,
        decoration: BoxDecoration(
          color: RetroPalette.panelBg,
          border: Border.all(color: RetroPalette.panelBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'サマリー',
              style: TextStyle(
                color: RetroPalette.panelBorder,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '総選挙数: ${summary.totalCount}回',
              style: const TextStyle(color: RetroPalette.textNormal),
            ),
            Text(
              '平均当選得票率: ${(summary.averageWinnerShare * 100).toStringAsFixed(1)}%',
              style: const TextStyle(color: RetroPalette.textNormal),
            ),
            Text(
              '最大差: ${summary.largestMarginEntry?.margin ?? 0}票',
              style: const TextStyle(color: RetroPalette.textNormal),
            ),
            Text(
              '最小差: ${summary.closestElectionEntry?.margin ?? 0}票',
              style: const TextStyle(color: RetroPalette.textNormal),
            ),
            const SizedBox(height: 8),
            Text(
              '当選者別当選回数: ${winCounts.isEmpty ? '—' : winCounts}',
              style: const TextStyle(color: RetroPalette.textAccent),
            ),
          ],
        ),
      ),
    );
  }
}

/// スケール到達状況の行（村→町→市、到達済みは強調）。
class _ScaleProgression extends StatelessWidget {
  final List<ElectionScale> reached;

  const _ScaleProgression({required this.reached});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: AppKeys.archiveScaleProgression,
      decoration: BoxDecoration(
        color: RetroPalette.panelBg,
        border: Border.all(color: RetroPalette.panelBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final scale in ElectionScale.values) ...[
            _ScaleBadge(
              scale: scale,
              reached: reached.contains(scale),
            ),
            if (scale != ElectionScale.values.last)
              const Icon(Icons.arrow_forward,
                  color: RetroPalette.textNormal, size: 18),
          ],
        ],
      ),
    );
  }
}

class _ScaleBadge extends StatelessWidget {
  final ElectionScale scale;
  final bool reached;

  const _ScaleBadge({required this.scale, required this.reached});

  @override
  Widget build(BuildContext context) {
    final label = switch (scale) {
      ElectionScale.village => '村',
      ElectionScale.town => '町',
      ElectionScale.city => '市',
    };
    return Column(
      children: [
        Icon(
          reached ? Icons.check_circle : Icons.radio_button_unchecked,
          color: reached ? RetroPalette.gold : RetroPalette.voteAbstain,
          size: 28,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: reached ? RetroPalette.gold : RetroPalette.voteAbstain,
            fontWeight: reached ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

/// 当選得票率の推移（簡易バー表示・新規依存なし）。
class _ShareTrend extends StatelessWidget {
  final List<double> trend;

  const _ShareTrend({required this.trend});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RetroPalette.panelBg,
        border: Border.all(color: RetroPalette.panelBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '当選得票率の推移',
            style: TextStyle(
              color: RetroPalette.panelBorder,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (trend.isEmpty)
            const Text(
              '—',
              style: TextStyle(color: RetroPalette.voteAbstain),
            )
          else
            ...trend.asMap().entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        '#${e.key + 1}',
                        style: const TextStyle(
                            color: RetroPalette.textNormal, fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: e.value.clamp(0.0, 1.0),
                        backgroundColor: RetroPalette.panelBg,
                        color: RetroPalette.gold,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '${(e.value * 100).toStringAsFixed(1)}%',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            color: RetroPalette.textNormal, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

/// スケール絞り込みチップ（村/町/市/すべて）。
class _ScaleFilterChips extends StatelessWidget {
  final ElectionScale? selected;
  final ValueChanged<ElectionScale?> onSelected;

  const _ScaleFilterChips({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          key: AppKeys.archiveFilterAll,
          label: const Text('すべて'),
          selected: selected == null,
          onSelected: (_) => onSelected(null),
        ),
        for (final scale in ElectionScale.values)
          ChoiceChip(
            key: AppKeys.archiveScaleFilter(scale),
            label: Text(
              switch (scale) {
                ElectionScale.village => '村',
                ElectionScale.town => '町',
                ElectionScale.city => '市',
              },
            ),
            selected: selected == scale,
            onSelected: (_) => onSelected(scale),
          ),
      ],
    );
  }
}

/// 選挙一覧。
class _ArchiveList extends StatelessWidget {
  final List<ElectionArchiveEntry> entries;

  const _ArchiveList({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: AppKeys.archiveList,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ArchiveEntryCard(entry: entry),
          ),
      ],
    );
  }
}

class _ArchiveEntryCard extends StatelessWidget {
  final ElectionArchiveEntry entry;

  const _ArchiveEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.interactive(
      testId: 'btn_archive_entry_${entry.electionId}',
      label: entry.title,
      child: Container(
        decoration: BoxDecoration(
          color: RetroPalette.panelBg,
          border: Border.all(color: RetroPalette.panelBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.title,
                    style: const TextStyle(
                      color: RetroPalette.textAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    entry.scaleLabel,
                    style: const TextStyle(
                        color: RetroPalette.bgDark, fontSize: 12),
                  ),
                  backgroundColor: RetroPalette.panelBorder,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '当選者: ${entry.winnerName}（${entry.winnerVotes}票）',
              style: const TextStyle(color: RetroPalette.textNormal),
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: entry.winnerShare.clamp(0.0, 1.0),
              backgroundColor: RetroPalette.bgDark,
              color: entry.isLandslide ? RetroPalette.gold : RetroPalette.success,
              minHeight: 8,
            ),
            const SizedBox(height: 6),
            Text(
              '得票率 ${(entry.winnerShare * 100).toStringAsFixed(1)}% ／ 差 ${entry.margin}票',
              style: const TextStyle(color: RetroPalette.textNormal, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}