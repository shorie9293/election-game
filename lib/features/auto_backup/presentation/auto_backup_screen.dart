import 'dart:async';

import 'package:flutter/material.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/features/auto_backup/data/auto_backup_status_store.dart';
import 'package:election_game/features/auto_backup/data/auto_backup_store.dart';
import 'package:election_game/features/auto_backup/domain/auto_backup_policy.dart';
import 'package:election_game/features/auto_backup/domain/auto_backup_presenter.dart';
import 'package:election_game/features/auto_backup/domain/auto_backup_restorer.dart';
import 'package:election_game/features/auto_backup/domain/auto_backup_sharer.dart';
import 'package:election_game/features/auto_backup/domain/auto_backup_status.dart';

/// 自動バックアップの閲覧・復元・共有画面。
///
/// - 表示は list → read → [AutoBackupPresenter.buildRows] のみ。
/// - 復元・共有は実装（restorer / sharer）を注入した時だけ導線を出す。
/// - すべての例外は握り、結果は SnackBar で伝える。
class AutoBackupScreen extends StatefulWidget {
  /// 自動バックアップの保存先。
  final AutoBackupStore store;

  /// 保持世代数の表示に使う方針。
  final AutoBackupPolicy policy;

  /// 復元役（null なら復元導線を出さない）。
  final AutoBackupRestorer? restorer;

  /// 共有役（null なら共有導線を出さない）。
  final AutoBackupSharer? sharer;

  /// 「今すぐバックアップ」の実行役（null ならボタンを出さない）。
  final Future<void> Function()? onBackupNow;

  /// 自動バックアップの状態の読み出し元（null なら状態表示を出さない）。
  final AutoBackupStatusStore? statusStore;

  /// 現在時刻（ローカル暦）。
  final DateTime Function()? now;

  const AutoBackupScreen({
    super.key,
    required this.store,
    this.policy = const AutoBackupPolicy(),
    this.restorer,
    this.sharer,
    this.onBackupNow,
    this.statusStore,
    this.now,
  });

  @override
  State<AutoBackupScreen> createState() => _AutoBackupScreenState();
}

class _AutoBackupScreenState extends State<AutoBackupScreen> {
  List<AutoBackupRow> _rows = const <AutoBackupRow>[];
  Map<String, String?> _contents = const <String, String?>{};
  AutoBackupStatus? _status;
  bool _loaded = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    AutoBackupStatus? status;
    final statusStore = widget.statusStore;
    if (statusStore != null) {
      try {
        status = await statusStore.load();
      } catch (_) {
        status = null;
      }
    }
    try {
      final entries = await widget.store.list();
      final contents = <String, String?>{};
      for (final entry in entries) {
        if (!AutoBackupPolicy.isAutoBackupFile(entry.fileName)) continue;
        try {
          contents[entry.fileName] = await widget.store.read(entry.fileName);
        } catch (_) {
          contents[entry.fileName] = null;
        }
      }
      final presenter = AutoBackupPresenter(keep: widget.policy.keep);
      final rows = presenter.buildRows(entries: entries, contents: contents);
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _contents = contents;
        _status = status;
        _loaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rows = const <AutoBackupRow>[];
        _contents = const <String, String?>{};
        _status = status;
        _loaded = true;
      });
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmRestore(AutoBackupRow row) async {
    final restorer = widget.restorer;
    if (restorer == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('復元の確認'),
          content: Text(
            '${row.dateLabel} のバックアップを復元します。'
            '現在のデータは復元前の自動バックアップとして退避されます。',
          ),
          actions: [
            TextButton(
              key: AppKeys.autoBackupRestoreCancelButton,
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('やめる'),
            ),
            TextButton(
              key: AppKeys.autoBackupRestoreConfirmButton,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('復元する'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    try {
      final result = await restorer.restore(row.entry.fileName);
      _snack(result.message);
      if (result.ok) await _load();
    } catch (e) {
      _snack('復元できませんでした: $e');
    }
  }

  Future<void> _share(AutoBackupRow row) async {
    final sharer = widget.sharer;
    if (sharer == null) return;
    final json = _contents[row.entry.fileName];
    if (json == null) {
      _snack('共有できる内容がありません');
      return;
    }
    try {
      await sharer.share(row.entry.fileName, json);
      _snack('共有しました');
    } catch (_) {
      _snack('共有できませんでした');
    }
  }

  Future<void> _backupNow() async {
    final callback = widget.onBackupNow;
    if (callback == null) return;
    setState(() => _busy = true);
    try {
      await callback();
      _snack('バックアップしました');
      await _load();
    } catch (_) {
      _snack('バックアップできませんでした');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// 失敗の警告バナー（未実行と毎回失敗を同じ見た目にしない）。
  Widget _failureBanner(AutoBackupStatus status) {
    final attemptedAt = status.lastAttemptAt;
    final when = attemptedAt == null
        ? ''
        : '（最終試行 ${AutoBackupPresenter.formatDate(attemptedAt)}）';
    final reason = status.lastError;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        key: AppKeys.autoBackupFailureBanner,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '自動バックアップに失敗しています$when',
              style: TextStyle(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (reason != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  reason,
                  style: TextStyle(color: colorScheme.onErrorContainer),
                ),
              ),
            if (widget.onBackupNow != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: AppKeys.autoBackupRetryButton,
                  onPressed: _busy ? null : _backupNow,
                  child: const Text('今すぐ実行'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: AppKeys.autoBackupScreen,
      appBar: AppBar(title: const Text('自動バックアップ')),
      body: _loaded
          ? _buildBody(context)
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildBody(BuildContext context) {
    final presenter = AutoBackupPresenter(keep: widget.policy.keep);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            presenter.retentionLabel(_rows.length),
            key: AppKeys.autoBackupRetentionLabel,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        if (_status?.lastSuccessAt != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              '最終成功 '
              '${AutoBackupPresenter.formatDate(_status!.lastSuccessAt!)}',
              key: AppKeys.autoBackupLastSuccessLabel,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (_status?.hasFailed == true) _failureBanner(_status!),
        if (widget.onBackupNow != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: FilledButton.icon(
              key: AppKeys.autoBackupBackupNowButton,
              onPressed: _busy ? null : _backupNow,
              icon: const Icon(Icons.backup_outlined),
              label: const Text('今すぐバックアップ'),
            ),
          ),
        if (_rows.isEmpty && _status?.hasAttempted != true)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'バックアップはまだありません',
              key: AppKeys.autoBackupEmptyLabel,
              textAlign: TextAlign.center,
            ),
          )
        else
          ..._rows.map(_buildRow),
      ],
    );
  }

  Widget _buildRow(AutoBackupRow row) {
    final canRestore = widget.restorer != null && row.restorable;
    final canShare = widget.sharer != null;
    return ListTile(
      key: AppKeys.autoBackupRow(row.entry.fileName),
      title: Text(row.displayLabel),
      subtitle: Text(row.entry.fileName),
      trailing: (canRestore || canShare)
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (canRestore)
                  IconButton(
                    key: AppKeys.autoBackupRestoreButton(row.entry.fileName),
                    tooltip: '復元',
                    icon: const Icon(Icons.restore),
                    onPressed: () => _confirmRestore(row),
                  ),
                if (canShare)
                  IconButton(
                    key: AppKeys.autoBackupShareButton(row.entry.fileName),
                    tooltip: '共有',
                    icon: const Icon(Icons.share),
                    onPressed: () => _share(row),
                  ),
              ],
            )
          : null,
    );
  }
}
