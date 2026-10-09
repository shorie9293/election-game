import 'package:flutter/material.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/domain/models/manifesto.dart';
import 'package:election_game/domain/repositories/manifesto_repository.dart';
import 'package:election_game/domain/services/manifesto_service.dart';

/// 公約実現度トラッカー画面。
///
/// 当選者の公約がどれだけ実現したかを記録単位で一覧表示する。
/// repository が注入された場合は initState で読み込む
/// （ホームは GameState を知らないため、アーカイブと同様の設計）。
class ManifestoTrackerScreen extends StatefulWidget {
  /// 外部から渡す記録（repository 未注入時に使う）。
  final List<ManifestoRecord> records;

  /// 永続化先リポジトリ（注入時は initState で読込）。
  final ManifestoRepository? repository;

  const ManifestoTrackerScreen({
    super.key,
    this.records = const [],
    this.repository,
  });

  @override
  State<ManifestoTrackerScreen> createState() => _ManifestoTrackerScreenState();
}

class _ManifestoTrackerScreenState extends State<ManifestoTrackerScreen> {
  String _query = '';
  List<ManifestoRecord>? _loadedRecords;

  @override
  void initState() {
    super.initState();
    _loadFromSource();
  }

  Future<void> _loadFromSource() async {
    if (widget.repository == null) return;
    try {
      final records = await widget.repository!.load();
      if (!mounted) return;
      setState(() => _loadedRecords = records);
    } catch (_) {
      // 読込失敗時は widget.records にフォールバック
    }
  }

  /// 実表示に使うレコード。
  List<ManifestoRecord> get _records => _loadedRecords ?? widget.records;

  List<ManifestoRecord> get _filteredRecords =>
      ManifestoService.search(_records, _query);

  @override
  Widget build(BuildContext context) {
    final records = ManifestoService.sortByDateDesc(_filteredRecords);
    final allRecords = _records;

    return Scaffold(
      backgroundColor: RetroPalette.bgDark,
      appBar: AppBar(
        title: const Text('公約実現度トラッカー', key: AppKeys.manifestoTitle),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                key: AppKeys.manifestoSearchField,
                decoration: InputDecoration(
                  hintText: '当選者名・選挙名で検索',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          key: AppKeys.manifestoSearchClear,
                          icon: const Icon(Icons.clear),
                          onPressed: () =>
                              setState(() => _query = ''),
                        ),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            if (allRecords.isNotEmpty) ...[
              _SummaryCard(records: allRecords),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${records.length}件',
                  key: AppKeys.manifestoListCount,
                  style: const TextStyle(color: RetroPalette.textAccent),
                ),
              ),
            ],
            Expanded(
              child: records.isEmpty
                  ? const _EmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: records.length,
                      itemBuilder: (context, index) => _RecordCard(
                        record: records[index],
                      ),
                    ),
            ),
          ],
        ),
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
          Icon(Icons.fact_check, color: RetroPalette.textNormal, size: 48),
          SizedBox(height: 12),
          Text(
            'まだ公約実現度の記録がありません',
            key: AppKeys.manifestoEmptyState,
            style: TextStyle(color: RetroPalette.textNormal),
          ),
        ],
      ),
    );
  }
}

/// サマリーカード: 記録件数・平均実現率・実現公約数。
class _SummaryCard extends StatelessWidget {
  final List<ManifestoRecord> records;

  const _SummaryCard({required this.records});

  @override
  Widget build(BuildContext context) {
    final averageRate = records.isEmpty
        ? 0.0
        : records.map((r) => r.realizationRate).reduce((a, b) => a + b) /
            records.length;
    return Container(
      key: AppKeys.manifestoSummary,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
            'サマリー',
            style: TextStyle(
              color: RetroPalette.panelBorder,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '記録件数: ${records.length}件',
            style: const TextStyle(color: RetroPalette.textNormal),
          ),
          Text(
            '平均実現率: ${(averageRate * 100).round()}%',
            style: const TextStyle(color: RetroPalette.textNormal),
          ),
          Text(
            '実現公約数: ${ManifestoService.fulfilledTotal(records)}',
            style: const TextStyle(color: RetroPalette.textAccent),
          ),
        ],
      ),
    );
  }
}

/// 1選挙分の記録カード。
class _RecordCard extends StatelessWidget {
  final ManifestoRecord record;

  const _RecordCard({required this.record});

  String get _dateLabel {
    final at = record.occurredAt;
    if (at == null) return '—';
    final y = at.year.toString().padLeft(4, '0');
    final m = at.month.toString().padLeft(2, '0');
    final d = at.day.toString().padLeft(2, '0');
    return '$y/$m/$d';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: AppKeys.manifestoRecordCard(record.electionId),
      margin: const EdgeInsets.only(bottom: 16),
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
            '当選者: ${record.winnerName}',
            style: const TextStyle(
              color: RetroPalette.panelBorder,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            record.title,
            style: const TextStyle(color: RetroPalette.textNormal),
          ),
          Text(
            _dateLabel,
            style: const TextStyle(color: RetroPalette.textNormal, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                record.percentLabel,
                style: const TextStyle(
                  color: RetroPalette.gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: record.realizationRate,
                  backgroundColor: RetroPalette.bgDark,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    RetroPalette.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final pledge in record.pledges)
            _PledgeRow(record: record, pledge: pledge),
        ],
      ),
    );
  }
}

/// 公約（生活パラメータkey単位）の実現度1行。
class _PledgeRow extends StatelessWidget {
  final ManifestoRecord record;
  final ManifestoPledge pledge;

  const _PledgeRow({required this.record, required this.pledge});

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: AppKeys.manifestoPledgeRow(record.electionId, pledge.lifeParamKey),
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '${pledge.label} / 約束: ${pledge.promisedDelta} / '
        '実際: ${pledge.actualDelta} / ${pledge.status.label}',
        style: const TextStyle(color: RetroPalette.textAccent, fontSize: 12),
      ),
    );
  }
}
