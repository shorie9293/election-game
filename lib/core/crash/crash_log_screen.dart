import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:takamagahara_ui/takamagahara_ui.dart' hide AppKeys;

import 'package:election_game/core/crash/crash_log_entry.dart';
import 'package:election_game/core/crash/crash_log_repository.dart';
import 'package:election_game/core/crash/crash_log_service.dart';
import 'package:election_game/core/testing/app_keys.dart';

/// 端末内クラッシュログの閲覧画面。
///
/// 送信はしない。記録を読み、利用者が自分の判断でコピーして報告できる。
class CrashLogScreen extends StatefulWidget {
  const CrashLogScreen({super.key, this.repository, this.now});

  /// 読み込み元（未指定なら端末保存の実装）。
  final CrashLogRepository? repository;

  /// 現在時刻の供給（要約の日付判定用・試験で差し替え可能）。
  final DateTime Function()? now;

  @override
  State<CrashLogScreen> createState() => _CrashLogScreenState();
}

class _CrashLogScreenState extends State<CrashLogScreen> {
  late final CrashLogRepository _repository =
      widget.repository ?? FileCrashLogRepository();
  late DateTime _now = (widget.now ?? DateTime.now)();
  List<CrashLogEntry> _entries = const <CrashLogEntry>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await _repository.loadAll();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _now = (widget.now ?? DateTime.now)();
      _loading = false;
    });
  }

  String _buildReport() {
    final buffer = StringBuffer()
      ..writeln('選挙体験RPG — 端末内クラッシュログ（${_entries.length}件）');
    for (var i = 0; i < _entries.length; i++) {
      final entry = _entries[i];
      buffer
        ..writeln('---- ${i + 1}. ${entry.timestamp.toIso8601String()} '
            '[${entry.kind.value}] ----')
        ..writeln(entry.message);
      if (entry.stackTop.isNotEmpty) {
        buffer.writeln(entry.stackTop);
      }
    }
    return buffer.toString();
  }

  Future<void> _copy() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await Clipboard.setData(ClipboardData(text: _buildReport()));
      messenger?.showSnackBar(
        const SnackBar(content: Text('クリップボードへコピーしました')),
      );
    } catch (_) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('コピーできませんでした')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: AppKeys.crashLogScreen,
      appBar: AppBar(title: const Text('不具合の報告')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_entries.isEmpty) {
      return Center(
        child: Semantics(
          container: true,
          label: '記録された不具合はありません',
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.verified_outlined, size: 48),
                SizedBox(height: 16),
                Text(
                  '記録された不具合はありません',
                  key: AppKeys.crashLogEmptyState,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'アプリが異常終了したり表示に失敗したりすると、'
                  'その記録がこの端末内に残ります。',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final summary = summarize(_entries, now: _now);
    final rows = recent(_entries, limit: 50);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (summary != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Semantics(
              container: true,
              label: summary,
              child: Text(
                summary,
                key: AppKeys.crashLogSummary,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) => _row(rows[index]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SemanticHelper.interactive(
            testId: 'btn_crash_log_copy',
            label: 'クリップボードへコピー',
            child: FilledButton.icon(
              key: AppKeys.crashLogCopyButton,
              onPressed: _copy,
              icon: const Icon(Icons.copy_all_outlined),
              label: const Text('クリップボードへコピー'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(CrashLogEntry entry) {
    final at = entry.timestamp;
    final time = '${at.year}/${at.month}/${at.day} '
        '${at.hour.toString().padLeft(2, '0')}:'
        '${at.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  time,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Text(
                _kindLabel(entry.kind),
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(entry.message, style: const TextStyle(fontSize: 13)),
          if (entry.stackTop.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              entry.stackTop,
              style: const TextStyle(fontSize: 11),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String _kindLabel(CrashLogKind kind) => switch (kind) {
        CrashLogKind.framework => '画面',
        CrashLogKind.platform => 'システム',
        CrashLogKind.uncaught => '未捕捉',
        CrashLogKind.unknown => 'その他',
      };
}

/// 設定ハブ先頭に置く「不具合の報告」導線。
///
/// 記録が1件以上あるときだけ件数を添える（`不具合の報告 (2)`）。
class CrashReportTile extends StatefulWidget {
  const CrashReportTile({
    super.key,
    required this.onTap,
    this.repository,
  });

  /// タップ時の遷移。
  final VoidCallback onTap;

  /// 件数の読み込み元（未指定なら端末保存の実装）。
  final CrashLogRepository? repository;

  @override
  State<CrashReportTile> createState() => _CrashReportTileState();
}

class _CrashReportTileState extends State<CrashReportTile> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    try {
      final entries =
          await (widget.repository ?? FileCrashLogRepository()).loadAll();
      if (!mounted) return;
      setState(() => _count = entries.length);
    } catch (_) {
      // 表示できないだけ。導線自体は活かす。
    }
  }

  String get _title => _count > 0 ? '不具合の報告 ($_count)' : '不具合の報告';

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.interactive(
      testId: 'btn_settings_hub_crash_log',
      label: _title,
      child: ListTile(
        key: AppKeys.settingsHubCrashLogTile,
        leading: const Icon(Icons.bug_report_outlined),
        title: Text(_title),
        subtitle: const Text('端末に記録された不具合の確認とコピー'),
        trailing: const Icon(Icons.chevron_right),
        onTap: widget.onTap,
      ),
    );
  }
}
