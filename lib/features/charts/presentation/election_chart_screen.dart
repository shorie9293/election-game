import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_archive.dart';
import 'package:election_game/domain/models/election_chart.dart';
import 'package:election_game/domain/repositories/election_archive_repository.dart';
import 'package:election_game/domain/services/election_chart_service.dart';

/// 選挙結果のグラフ可視化と複数選挙の比較画面。
///
/// entries は必須。rawElections（直接注入）または repository から生選挙を
/// 読み込み、政党別シェア系列を構築する。アーカイブ画面と同じ遅延読込・
/// try/catch・mounted ガードのパターンに従う。
class ElectionChartScreen extends StatefulWidget {
  /// 表示するアーカイブエントリ（必須）
  final List<ElectionArchiveEntry> entries;

  /// 生選挙の読込先リポジトリ（未指定ならrawElectionsのみで描画）
  final ElectionArchiveRepository? repository;

  /// リポジトリ経由で読む代わりに直接渡す生選挙リスト
  final List<Election>? rawElections;

  const ElectionChartScreen({
    super.key,
    required this.entries,
    this.repository,
    this.rawElections,
  });

  @override
  State<ElectionChartScreen> createState() => _ElectionChartScreenState();
}

class _ElectionChartScreenState extends State<ElectionChartScreen> {
  List<Election>? _loadedElections;
  Set<String> _selectedIds = const <String>{};
  bool _initializedSelection = false;

  @override
  void initState() {
    super.initState();
    final raw = widget.rawElections;
    if (raw != null) {
      _loadedElections = raw;
      _ensureSelection();
    } else if (widget.repository != null) {
      _loadFromSource();
    }
  }

  Future<void> _loadFromSource() async {
    List<Election>? elections;
    try {
      elections = await widget.repository!.load();
    } catch (_) {
      elections = null;
    }
    if (!mounted || elections == null) return;
    setState(() {
      _loadedElections = elections;
      _ensureSelection();
    });
  }

  /// 初回のみ: 直近 min(6, N) 件を選択状態にする。
  void _ensureSelection() {
    if (_initializedSelection) return;
    final points = ElectionChartService.buildPoints(widget.entries);
    if (points.isEmpty) return;
    final take = points.length < 6 ? points.length : 6;
    _selectedIds = points.sublist(points.length - take).map((p) => p.electionId).toSet();
    _initializedSelection = true;
  }

  /// 実表示に使う生選挙。
  List<Election> get _rawElections => _loadedElections ?? widget.rawElections ?? const [];

  ElectionComparison get _comparison => ElectionChartService.compare(
        widget.entries,
        elections: _rawElections,
        maxSeries: 6,
      );

  void _togglePoint(String electionId) {
    setState(() {
      final next = Set<String>.of(_selectedIds);
      if (!next.remove(electionId)) next.add(electionId);
      _selectedIds = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) {
      return Scaffold(
        backgroundColor: RetroPalette.bgDark,
        appBar: AppBar(
          title: const Text('選挙グラフ分析', key: AppKeys.chartScreen),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.insights, color: RetroPalette.textNormal, size: 48),
              SizedBox(height: 12),
              Text(
                'まだ選挙の記録がありません',
                key: AppKeys.chartEmptyState,
                style: TextStyle(color: RetroPalette.textNormal),
              ),
            ],
          ),
        ),
      );
    }

    _ensureSelection();
    final comparison = _comparison;

    return Scaffold(
      backgroundColor: RetroPalette.bgDark,
      appBar: AppBar(
        title: const Text('選挙グラフ分析', key: AppKeys.chartScreen),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SummaryCard(comparison: comparison),
            const SizedBox(height: 16),
            _ShareTrend(points: comparison.points),
            const SizedBox(height: 16),
            if (comparison.series.isNotEmpty) ...[
              _PartyTrend(series: comparison.series),
              const SizedBox(height: 16),
            ],
            _ComparisonSection(
              points: comparison.points,
              selectedIds: _selectedIds,
              onToggle: _togglePoint,
            ),
          ],
        ),
      ),
    );
  }
}

/// パネルコンテナの共通デコレーション。
class _Panel extends StatelessWidget {
  final String title;
  final Widget child;

  const _Panel({required this.title, required this.child});

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
          Text(
            title,
            style: const TextStyle(
              color: RetroPalette.panelBorder,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// サマリーカード: 総選挙数・平均当選得票率・得票率変化・最高・最低。
class _SummaryCard extends StatelessWidget {
  final ElectionComparison comparison;

  const _SummaryCard({required this.comparison});

  @override
  Widget build(BuildContext context) {
    final highest = comparison.highestSharePoint;
    final lowest = comparison.lowestSharePoint;
    return _Panel(
      title: 'サマリー',
      child: Column(
        key: AppKeys.chartSummaryCard,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '総選挙数: ${comparison.totalElections}回',
            style: const TextStyle(color: RetroPalette.textNormal),
          ),
          Text(
            '平均当選得票率: ${(comparison.averageWinnerShare * 100).toStringAsFixed(1)}%',
            style: const TextStyle(color: RetroPalette.textNormal),
          ),
          Text(
            '得票率変化: ${comparison.shareChangeLabel}',
            style: const TextStyle(color: RetroPalette.textAccent),
          ),
          Text(
            '最高: ${highest == null ? '—' : '${highest.label} ${highest.sharePercentLabel}（${highest.winnerName}）'}',
            style: const TextStyle(color: RetroPalette.textNormal),
          ),
          Text(
            '最低: ${lowest == null ? '—' : '${lowest.label} ${lowest.sharePercentLabel}（${lowest.winnerName}）'}',
            style: const TextStyle(color: RetroPalette.textNormal),
          ),
        ],
      ),
    );
  }
}

const _paletteColors = [
  RetroPalette.gold,
  RetroPalette.success,
  RetroPalette.danger,
  RetroPalette.warning,
  RetroPalette.moodHealthyDebate,
  RetroPalette.moodHarmony,
];

/// 当選得票率の推移（LineChart）。
class _ShareTrend extends StatelessWidget {
  final List<ElectionChartPoint> points;

  const _ShareTrend({required this.points});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: '当選得票率の推移',
      child: SizedBox(
        key: AppKeys.chartShareTrend,
        height: 220,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: 100,
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  getTitlesWidget: (value, meta) =>
                      Text('${value.toInt()}%', style: const TextStyle(color: RetroPalette.textNormal, fontSize: 10)),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt() - 1;
                    if (index < 0 || index >= points.length) {
                      return const SizedBox.shrink();
                    }
                    return Text(points[index].label,
                        style: const TextStyle(color: RetroPalette.textNormal, fontSize: 10));
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < points.length; i++)
                    FlSpot(i.toDouble() + 1, points[i].winnerShare * 100),
                ],
                isCurved: false,
                color: RetroPalette.gold,
                barWidth: 2,
                dotData: const FlDotData(show: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 政党別シェアの推移（LineChart + 凡例）。
class _PartyTrend extends StatelessWidget {
  final List<ElectionPartySeries> series;

  const _PartyTrend({required this.series});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: '政党別シェアの推移',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            key: AppKeys.chartPartyTrend,
            height: 220,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                titlesData: const FlTitlesData(show: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  for (var i = 0; i < series.length; i++)
                    LineChartBarData(
                      spots: [
                        for (var j = 0; j < series[i].shares.length; j++)
                          FlSpot(j.toDouble() + 1, series[i].shares[j] * 100),
                      ],
                      isCurved: false,
                      color: _paletteColors[i % _paletteColors.length],
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...series.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                key: AppKeys.chartPartyRow(s.faction),
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _paletteColors[series.indexOf(s) % _paletteColors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${s.faction} ${s.latestPercentLabel}（${s.trendLabel}）',
                    style: const TextStyle(color: RetroPalette.textNormal, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 複数選挙の比較（FilterChip + BarChart）。
class _ComparisonSection extends StatelessWidget {
  final List<ElectionChartPoint> points;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  const _ComparisonSection({
    required this.points,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final selected =
        points.where((p) => selectedIds.contains(p.electionId)).toList();
    return _Panel(
      title: '複数選挙の比較',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            key: AppKeys.chartComparison,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final point in points)
                FilterChip(
                  key: AppKeys.chartPointChip(point.electionId),
                  label: Text(point.label),
                  selected: selectedIds.contains(point.electionId),
                  onSelected: (_) => onToggle(point.electionId),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (selected.isEmpty)
            const Text(
              '比較する選挙を選んでください',
              key: AppKeys.chartCompareHint,
              style: TextStyle(color: RetroPalette.textNormal),
            )
          else
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: 100,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text('${value.toInt()}%',
                            style: const TextStyle(
                                color: RetroPalette.textNormal, fontSize: 10)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= selected.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(selected[index].label,
                              style: const TextStyle(
                                  color: RetroPalette.textNormal, fontSize: 10));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    for (var i = 0; i < selected.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: selected[i].winnerShare * 100,
                            color: RetroPalette.gold,
                            width: 18,
                            borderRadius: BorderRadius.zero,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
