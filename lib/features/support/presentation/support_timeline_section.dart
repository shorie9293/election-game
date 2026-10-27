import 'package:flutter/material.dart';
import 'package:takamagahara_ui/takamagahara_ui.dart' hide AppKeys;

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/domain/models/support_snapshot.dart';
import 'package:election_game/domain/models/support_timeline.dart';
import 'package:election_game/domain/repositories/support_timeline_repository.dart';
import 'package:election_game/domain/services/support_timeline_service.dart';

/// 世論（支持率）の推移を表示・記録するセクション。
///
/// 初期表示で [repository] から記録を読み込み、末尾 [maxRows] 件を昇順のまま描く。
/// 時刻は [now] で注入可能（未注入なら DateTime.now()）。
/// 視覚化は依存パッケージを増やさず Container の幅割合で描く。
class SupportTimelineSection extends StatefulWidget {
  /// 記録の永続化先
  final SupportTimelineRepository repository;

  /// 記録対象のシミュレーション結果
  final SupportSimulation simulation;

  /// 現在時刻の供給元（試練での固定用）
  final DateTime Function()? now;

  /// 描画する最大行数
  final int maxRows;

  const SupportTimelineSection({
    super.key,
    required this.repository,
    required this.simulation,
    this.now,
    this.maxRows = 20,
  });

  @override
  State<SupportTimelineSection> createState() => _SupportTimelineSectionState();
}

class _SupportTimelineSectionState extends State<SupportTimelineSection> {
  /// 読み込んだ全記録（昇順）
  List<SupportTimelineEntry> _stored = const <SupportTimelineEntry>[];

  /// 初回読み込み中か
  bool _loading = true;

  /// 記録処理中か（二重タップ防止）
  bool _recording = false;

  DateTime _now() => widget.now?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final loaded = await widget.repository.load();
    if (!mounted) return;
    setState(() {
      _stored = loaded;
      _loading = false;
    });
  }

  Future<void> _onRecord() async {
    if (_recording) return;
    final entry = SupportTimelineService.buildEntry(
      simulation: widget.simulation,
      now: _now(),
    );
    if (entry == null) return;

    setState(() => _recording = true);
    try {
      await widget.repository.add(entry);
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('世論を記録しました')),
      );
    } finally {
      if (mounted) setState(() => _recording = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = SupportTimelineService.recent(_stored, max: widget.maxRows);

    return Container(
      decoration: BoxDecoration(
        color: RetroPalette.panelBg,
        border: Border.all(color: RetroPalette.panelBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '世論の推移',
                  key: AppKeys.supportTimelineTitle,
                  style: TextStyle(
                    color: RetroPalette.panelBorder,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SemanticHelper.interactive(
                testId: 'btn_support_record_opinion',
                label: '世論を記録',
                hint: '現在の支持率を推移に記録します',
                child: TextButton(
                  key: AppKeys.supportTimelineRecordButton,
                  onPressed: _recording ? null : _onRecord,
                  child: const Text(
                    '世論を記録',
                    style: TextStyle(color: RetroPalette.gold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            SupportTimelineService.trendLabel(_stored),
            key: AppKeys.supportTimelineTrendLabel,
            style: const TextStyle(
              color: RetroPalette.textNormal,
              fontSize: 12,
            ),
          ),
          Text(
            '${rows.length}件の記録',
            key: AppKeys.supportTimelineCount,
            style: const TextStyle(
              color: RetroPalette.voteAbstain,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty && !_loading)
            const Text(
              'まだ世論の記録がありません',
              key: AppKeys.supportTimelineEmpty,
              style: TextStyle(
                color: RetroPalette.textNormal,
                fontSize: 12,
              ),
            )
          else
            for (final entry in rows)
              _TimelineRow(
                entry: entry,
                delta: SupportTimelineService.deltaAt(_stored, entry.id),
              ),
        ],
      ),
    );
  }
}

/// 記録1件分の行: 候補者名・支持率バー・差分・首位交代バッジ。
class _TimelineRow extends StatelessWidget {
  final SupportTimelineEntry entry;
  final SupportTimelineDelta? delta;

  const _TimelineRow({required this.entry, required this.delta});

  @override
  Widget build(BuildContext context) {
    final delta = this.delta;
    final rate = entry.leaderSupportRate.clamp(0.0, 1.0);

    return Container(
      key: AppKeys.supportTimelineRow(entry.id),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: RetroPalette.bgDark,
        border: Border.all(color: RetroPalette.panelBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.leaderCandidateName,
                  style: const TextStyle(
                    color: RetroPalette.textAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                entry.leaderShareLabel,
                style: const TextStyle(color: RetroPalette.gold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 支持率バー: 幅割合のみで表現（追加パッケージなし）
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth * rate;
              return Container(
                height: 6,
                color: RetroPalette.panelBg,
                alignment: Alignment.centerLeft,
                child: Container(
                    width: width, height: 6, color: RetroPalette.gold),
              );
            },
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (delta != null)
                Text(
                  delta.deltaLabel,
                  style: TextStyle(
                    color: delta.shareDelta >= 0
                        ? RetroPalette.success
                        : RetroPalette.danger,
                    fontSize: 12,
                  ),
                ),
              if (delta != null && delta.leaderChanged) ...[
                const SizedBox(width: 8),
                Container(
                  key: AppKeys.supportTimelineLeaderChanged(entry.id),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: RetroPalette.warning,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '首位交代',
                    style: TextStyle(
                      color: RetroPalette.bgDark,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
