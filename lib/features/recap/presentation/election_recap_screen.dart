import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_archive.dart';
import 'package:election_game/domain/models/election_recap.dart';
import 'package:election_game/domain/models/turnout_snapshot.dart';
import 'package:election_game/domain/repositories/election_archive_repository.dart';
import 'package:election_game/domain/services/election_archive_service.dart';
import 'package:election_game/domain/services/election_recap_service.dart';

/// 選挙結果の振り返りカード（共有用テキスト）画面。
///
/// アーカイブエントリをドロップダウンで切り替え、整形テキストを表示し、
/// クリップボードへコピーできる。copyHandler を注入すれば Clipboard を置き換えられる。
class ElectionRecapScreen extends StatefulWidget {
  /// 表示するアーカイブエントリ（必須）
  final List<ElectionArchiveEntry> entries;

  /// 生選挙の読込先リポジトリ（未指定ならentriesのみで描画）
  final ElectionArchiveRepository? repository;

  /// リポジトリ経由で読む代わりに直接渡す生選挙リスト
  final List<Election>? rawElections;

  /// 選挙IDごとの投票率スナップショット
  final Map<String, TurnoutSnapshot> turnoutsByElectionId;

  /// コピー動作の注入（未指定時は Clipboard.setData）
  final void Function(String text)? copyHandler;

  const ElectionRecapScreen({
    super.key,
    required this.entries,
    this.repository,
    this.rawElections,
    this.turnoutsByElectionId = const {},
    this.copyHandler,
  });

  @override
  State<ElectionRecapScreen> createState() => _ElectionRecapScreenState();
}

class _ElectionRecapScreenState extends State<ElectionRecapScreen> {
  /// repository / rawElections から読み込んだエントリ（nullならwidget.entriesを使う）
  List<ElectionArchiveEntry>? _loadedEntries;

  String? _selectedId;

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
    return entries.first;
  }

  Future<void> _copy(ElectionRecap recap) async {
    final handler = widget.copyHandler;
    if (handler != null) {
      handler(recap.text);
    } else {
      await Clipboard.setData(ClipboardData(text: recap.text));
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        key: AppKeys.recapSnackBar,
        content: Text('コピーしました'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = _selectedEntry;
    return Scaffold(
      backgroundColor: RetroPalette.bgDark,
      appBar: AppBar(
        title: const Text('選挙の振り返り', key: AppKeys.recapTitle),
      ),
      body: entry == null
          ? const _EmptyState()
          : _RecapBody(
              entries: _entries,
              selected: entry,
              turnoutsByElectionId: widget.turnoutsByElectionId,
              onSelected: (id) => setState(() => _selectedId = id),
              onCopy: _copy,
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
            '振り返る選挙がありません',
            key: AppKeys.recapEmptyState,
            style: TextStyle(color: RetroPalette.textNormal),
          ),
        ],
      ),
    );
  }
}

/// 振り返り本体（セレクタ・カード・コピーボタン）。
class _RecapBody extends StatelessWidget {
  final List<ElectionArchiveEntry> entries;
  final ElectionArchiveEntry selected;
  final Map<String, TurnoutSnapshot> turnoutsByElectionId;
  final ValueChanged<String> onSelected;
  final Future<void> Function(ElectionRecap recap) onCopy;

  const _RecapBody({
    required this.entries,
    required this.selected,
    required this.turnoutsByElectionId,
    required this.onSelected,
    required this.onCopy,
  });

  ElectionRecap get recap => ElectionRecapService.build(
        selected,
        turnout: turnoutsByElectionId[selected.electionId],
      );

  String _itemLabel(ElectionArchiveEntry e) {
    final entry = ElectionRecapService.build(e);
    return '${e.title}（${entry.dateLabel}）';
  }

  @override
  Widget build(BuildContext context) {
    final r = recap;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButton<String>(
            key: AppKeys.recapSelector,
            isExpanded: true,
            value: selected.electionId,
            items: [
              for (final e in entries)
                DropdownMenuItem<String>(
                  value: e.electionId,
                  child: Text(_itemLabel(e)),
                ),
            ],
            onChanged: (id) {
              if (id != null) onSelected(id);
            },
          ),
          const SizedBox(height: 16),
          Container(
            key: AppKeys.recapCard,
            decoration: BoxDecoration(
              color: RetroPalette.panelBg,
              border: Border.all(color: RetroPalette.panelBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              r.text,
              key: AppKeys.recapText,
              style: const TextStyle(color: RetroPalette.textNormal),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: AppKeys.recapCopyButton,
            onPressed: () => onCopy(r),
            icon: const Icon(Icons.copy),
            label: const Text('クリップボードにコピー'),
          ),
        ],
      ),
    );
  }
}
