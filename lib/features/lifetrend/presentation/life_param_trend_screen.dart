import 'package:flutter/material.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/domain/models/life_param_snapshot.dart';
import 'package:election_game/domain/models/life_param_trend.dart';
import 'package:election_game/domain/repositories/life_param_snapshot_repository.dart';
import 'package:election_game/domain/services/life_param_trend_service.dart';

/// 生活パラメータの推移画面（選挙ごとの記録を可視化）。
///
/// 試練では [snapshotsOverride] を注入して repository 読込を回避できる。
class LifeParamTrendScreen extends StatefulWidget {
  /// 試練用：null なら repository から読み込む。
  final List<LifeParamSnapshot>? snapshotsOverride;

  /// スナップショットの永続化先（試練では差し替え可能）。
  final LifeParamSnapshotRepository repository;

  const LifeParamTrendScreen({
    super.key,
    this.snapshotsOverride,
    this.repository = const SharedPreferencesLifeParamSnapshotRepository(),
  });

  @override
  State<LifeParamTrendScreen> createState() => _LifeParamTrendScreenState();
}

class _LifeParamTrendScreenState extends State<LifeParamTrendScreen> {
  List<LifeParamSnapshot>? _snapshots;
  bool _loading = true;
  String? _selectedKey;

  @override
  void initState() {
    super.initState();
    final override = widget.snapshotsOverride;
    if (override != null) {
      _snapshots = List<LifeParamSnapshot>.of(override);
      _loading = false;
    } else {
      _loadSnapshots();
    }
  }

  Future<void> _loadSnapshots() async {
    try {
      final snapshots = await widget.repository.load();
      if (!mounted) return;
      setState(() {
        _snapshots = snapshots;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _snapshots = const [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshots = _snapshots ?? const <LifeParamSnapshot>[];
    final seriesList = LifeParamTrendService.buildAll(snapshots);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (seriesList.isEmpty) {
      return Scaffold(
        backgroundColor: RetroPalette.bgDark,
        appBar: AppBar(title: const Text('生活パラメータの推移')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              key: AppKeys.lifeParamTrendEmpty,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.show_chart, color: RetroPalette.voteAbstain, size: 48),
                SizedBox(height: 12),
                Text(
                  'まだ記録がありません。\n選挙を終えると生活パラメータが記録されます。',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: RetroPalette.textNormal, height: 1.6),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 既定選択は最初のシリーズ
    final selectedKey =
        (_selectedKey != null && seriesList.any((s) => s.key == _selectedKey))
            ? _selectedKey!
            : seriesList.first.key;
    final selected = seriesList.firstWhere((s) => s.key == selectedKey);

    return Scaffold(
      backgroundColor: RetroPalette.bgDark,
      appBar: AppBar(title: const Text('生活パラメータの推移')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final series in seriesList)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        key: AppKeys.lifeParamTrendKeyChip(series.key),
                        label: Text(
                          series.label,
                          style: TextStyle(
                            color: series.key == selectedKey
                                ? RetroPalette.bgDark
                                : RetroPalette.textNormal,
                          ),
                        ),
                        selected: series.key == selectedKey,
                        selectedColor: RetroPalette.gold,
                        backgroundColor: RetroPalette.panelBg,
                        checkmarkColor: RetroPalette.bgDark,
                        onSelected: (_) => setState(() {
                          _selectedKey = series.key;
                        }),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SeriesCard(series: selected),
          ],
        ),
      ),
    );
  }
}

/// 選択中シリーズのサマリーカード（最新値・変化量・簡易棒グラフ）。
class _SeriesCard extends StatelessWidget {
  final LifeParamTrendSeries series;

  const _SeriesCard({required this.series});

  Color _valueColor(int value) {
    if (value >= 70) return RetroPalette.success;
    if (value >= 40) return RetroPalette.warning;
    return RetroPalette.danger;
  }

  @override
  Widget build(BuildContext context) {
    // 高さは値に比例（min == max のときは一律）
    final span = series.maxValue - series.minValue;
    const maxHeight = 120.0;
    const minHeight = 16.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RetroPalette.panelBg,
        border: Border.all(color: RetroPalette.panelBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            series.label,
            style: const TextStyle(
              color: RetroPalette.gold,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                '最新値',
                style: TextStyle(color: RetroPalette.textNormal, fontSize: 13),
              ),
              const SizedBox(width: 8),
              Text(
                '${series.latestValue}',
                key: AppKeys.lifeParamTrendLatest,
                style: TextStyle(
                  color: _valueColor(series.latestValue ?? 0),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${series.totalDeltaLabel}（${series.directionLabel}）',
                style: const TextStyle(
                  color: RetroPalette.textAccent,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: maxHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final point in series.points) ...[
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        key: AppKeys.lifeParamTrendBar(point.electionId),
                        height: span == 0
                            ? maxHeight
                            : minHeight +
                                (maxHeight - minHeight) *
                                    (point.value - series.minValue) /
                                    span,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: _valueColor(point.value),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final point in series.points)
                Expanded(
                  child: Text(
                    point.deltaLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: RetroPalette.textNormal,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}