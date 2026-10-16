import 'package:flutter/material.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_archive.dart';
import 'package:election_game/domain/models/turnout_snapshot.dart';
import 'package:election_game/domain/repositories/election_archive_repository.dart';
import 'package:election_game/domain/services/election_archive_service.dart';
import 'package:election_game/features/share/domain/election_share_card_data.dart';
import 'package:election_game/features/share/domain/election_share_card_service.dart';
import 'package:election_game/features/share/presentation/election_share_card_capture.dart';
import 'package:election_game/features/share/presentation/election_share_card_exporter.dart';

/// 選挙結果の画像シェアカード画面。
///
/// アーカイブエントリを選び、結果（当選者・得票率・得票差・規模・投票率・実施日）を
/// 1枚のカードに描いて、テキスト／画像として共有シートへ渡す。
/// データ源・基準日・キャプチャ・共有はすべて注入可能（テスト・headless 用）。
class ElectionShareCardScreen extends StatefulWidget {
  /// 表示するアーカイブエントリ（repository/rawElections 未指定時に使う）
  final List<ElectionArchiveEntry> entries;

  /// 生選挙の読込先リポジトリ（未指定ならentriesのみで描画）
  final ElectionArchiveRepository? repository;

  /// リポジトリ経由で読む代わりに直接渡す生選挙リスト
  final List<Election>? rawElections;

  /// 選挙IDごとの投票率スナップショット
  final Map<String, TurnoutSnapshot> turnoutsByElectionId;

  /// カード生成日時の基準（テストの決定論化用。未指定なら実時計）
  final DateTime Function()? now;

  /// カード画像キャプチャ。nullなら画像共有ボタンを無効化する。
  final ElectionShareCardCapture? capture;

  /// 共有エクスポーター。nullなら share_plus 実装を使う。
  final ElectionShareCardExporter? exporter;

  const ElectionShareCardScreen({
    super.key,
    this.entries = const [],
    this.repository,
    this.rawElections,
    this.turnoutsByElectionId = const {},
    this.now,
    this.capture,
    this.exporter,
  });

  @override
  State<ElectionShareCardScreen> createState() => _ElectionShareCardScreenState();
}

class _ElectionShareCardScreenState extends State<ElectionShareCardScreen> {
  /// repository / rawElections から読み込んだエントリ（nullならwidget.entriesを使う）
  List<ElectionArchiveEntry>? _loadedEntries;

  String? _selectedId;

  /// カード画像キャプチャ用の境界キー
  final GlobalKey _previewKey = GlobalKey();

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

  /// 実表示に使うエントリ（repository 読込を優先）。
  List<ElectionArchiveEntry> get _entries => _loadedEntries ?? widget.entries;

  ElectionArchiveEntry? get _selectedEntry {
    final entries = _entries;
    if (entries.isEmpty) return null;
    final id = _selectedId;
    if (id != null) {
      for (final e in entries) {
        if (e.electionId == id) return e;
      }
    }
    return entries.last;
  }

  ElectionShareCardData? get _card {
    final entry = _selectedEntry;
    if (entry == null) return null;
    final now = widget.now ?? DateTime.now;
    return ElectionShareCardService.build(
      entry: entry,
      turnout: widget.turnoutsByElectionId[entry.electionId],
      generatedAt: now(),
    );
  }

  Future<void> _share({required bool withImage}) async {
    final card = _card;
    if (card == null) return;
    final exporter = widget.exporter ?? const SharePlusElectionShareCardExporter();
    if (!withImage) {
      await exporter.share(image: null, text: card.shareText);
      return;
    }
    final capture = widget.capture;
    if (capture == null) return;
    final bytes = await capture.capture(_previewKey);
    await exporter.share(image: bytes, text: card.shareText);
  }

  @override
  Widget build(BuildContext context) {
    final card = _card;
    final entries = _entries;
    return Scaffold(
      key: AppKeys.shareCardScreen,
      backgroundColor: RetroPalette.bgDark,
      appBar: AppBar(
        title: const Text('選挙シェアカード', key: AppKeys.shareCardTitle),
      ),
      body: card == null
          ? const _EmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (entries.length > 1)
                    DropdownButton<String>(
                      key: AppKeys.shareCardSelector,
                      isExpanded: true,
                      value: card.electionId,
                      items: [
                        for (final e in entries)
                          DropdownMenuItem<String>(
                            value: e.electionId,
                            child: Text('${e.title}（${e.scaleLabel}）'),
                          ),
                      ],
                      onChanged: (id) {
                        if (id != null) setState(() => _selectedId = id);
                      },
                    ),
                  if (entries.length > 1) const SizedBox(height: 16),
                  Center(child: _buildPreviewCard(card)),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    key: AppKeys.shareCardTextShareButton,
                    onPressed: () => _share(withImage: false),
                    icon: const Icon(Icons.ios_share),
                    label: const Text('テキストで共有'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    key: AppKeys.shareCardImageShareButton,
                    onPressed: widget.capture == null
                        ? null
                        : () => _share(withImage: true),
                    icon: const Icon(Icons.image),
                    label: const Text('画像で共有'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPreviewCard(ElectionShareCardData card) {
    return RepaintBoundary(
      key: _previewKey,
      child: Container(
        key: AppKeys.shareCardPreview,
        width: 360,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: RetroPalette.panelBg,
          border: Border.all(
            color: card.isLandslide ? RetroPalette.gold : RetroPalette.panelBorder,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.header,
              key: AppKeys.shareCardHeadline,
              style: const TextStyle(
                color: RetroPalette.gold,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            for (final line in card.lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  line,
                  style: const TextStyle(color: RetroPalette.textNormal),
                ),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                card.generatedDateLabel,
                style: const TextStyle(
                  color: RetroPalette.textAccent,
                  fontSize: 12,
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
          Icon(Icons.image_not_supported, color: RetroPalette.textNormal, size: 48),
          SizedBox(height: 12),
          Text(
            '共有できる選挙結果がありません',
            key: AppKeys.shareCardEmpty,
            style: TextStyle(color: RetroPalette.textNormal),
          ),
        ],
      ),
    );
  }
}
