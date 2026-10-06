import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/features/backup/data/game_data_backup_repository.dart';
import 'package:election_game/features/backup/domain/game_data_backup.dart';

/// クリップボード書き込みの差し替え可能な関数型。
typedef ClipboardWriter = Future<void> Function(String text);

/// システムクリップボードへ書き込む既定実装（トップレベル関数）。
Future<void> writeToSystemClipboard(String text) async {
  await Clipboard.setData(ClipboardData(text: text));
}

/// ゲーム進行データのエクスポート/バックアップ画面。
class GameDataBackupScreen extends StatefulWidget {
  final GameDataBackupRepository repository;
  final GameDataBackupService service;
  final BackupClock now;
  final ClipboardWriter copyToClipboard;
  final String? initialImportText;

  const GameDataBackupScreen({
    super.key,
    this.repository = const SharedPreferencesGameDataBackupRepository(),
    this.service = const GameDataBackupService(),
    this.now = DateTime.now,
    this.copyToClipboard = writeToSystemClipboard,
    this.initialImportText,
  });

  @override
  State<GameDataBackupScreen> createState() => _GameDataBackupScreenState();
}

class _GameDataBackupScreenState extends State<GameDataBackupScreen> {
  Map<String, Object?> _current = const {};
  bool _loaded = false;
  String? _exportedJson;
  String? _status;
  String? _error;
  late final TextEditingController _importController;

  @override
  void initState() {
    super.initState();
    _importController = TextEditingController(
      text: widget.initialImportText,
    );
    unawaited(_load());
  }

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await widget.repository.collect();
    if (!mounted) return;
    setState(() {
      _current = data;
      _loaded = true;
    });
  }

  int _countForCategory(BackupCategory category) {
    var count = 0;
    for (final key in _current.keys) {
      if (BackupKeySpec.categoryFor(key) == category) count++;
    }
    return count;
  }

  Future<void> _export() async {
    setState(() {
      _exportedJson = widget.service.build(_current, exportedAt: widget.now());
      _status = null;
      _error = null;
    });
  }

  Future<void> _copy() async {
    final json = _exportedJson;
    if (json == null) return;
    await widget.copyToClipboard(json);
    if (!mounted) return;
    setState(() {
      _status = 'コピーしました';
      _error = null;
    });
  }

  Future<void> _restore() async {
    final result = widget.service.parse(_importController.text);
    if (result.hasError || result.backup == null) {
      setState(() {
        _error = result.error;
        _status = null;
      });
      return;
    }
    final backup = result.backup!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('データの復元'),
          content: Text(
            '${backup.entryCount}件のデータを復元します。現在のデータは上書きされます。よろしいですか？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('やめる'),
            ),
            TextButton(
              key: AppKeys.backupRestoreConfirmButton,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('復元する'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await widget.repository.restore(backup.data, clearExisting: true);
    final data = await widget.repository.collect();
    if (!mounted) return;
    setState(() {
      _current = data;
      _status = '復元しました';
      _error = null;
      _exportedJson = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: AppKeys.backupScreen,
      appBar: AppBar(
        title: const Text('データのエクスポート/バックアップ'),
      ),
      body: _loaded
          ? _buildBody(context)
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '現在のデータ: ${_current.length}件',
            key: AppKeys.backupEntryCountLabel,
          ),
          const SizedBox(height: 8),
          ...BackupCategory.values.map((category) {
            return ListTile(
              key: AppKeys.backupCategoryRow(category.name),
              title: Text(backupCategoryLabel(category)),
              trailing: Text('${_countForCategory(category)}件'),
              dense: true,
            );
          }),
          const SizedBox(height: 16),

          // エクスポート
          ElevatedButton(
            key: AppKeys.backupExportButton,
            onPressed: _export,
            child: const Text('エクスポート'),
          ),
          if (_exportedJson != null) ...[
            const SizedBox(height: 8),
            SelectableText(
              _exportedJson!,
              key: AppKeys.backupExportOutput,
            ),
          ],
          const SizedBox(height: 8),
          ElevatedButton(
            key: AppKeys.backupCopyButton,
            onPressed: _exportedJson == null ? null : _copy,
            child: const Text('コピー'),
          ),
          const SizedBox(height: 24),

          // インポート
          TextField(
            key: AppKeys.backupImportField,
            controller: _importController,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: 'バックアップJSONを貼り付け',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            key: AppKeys.backupRestoreButton,
            onPressed: _restore,
            child: const Text('復元'),
          ),
          if (_status != null)
            Text(
              _status!,
              key: AppKeys.backupStatusLabel,
            ),
          if (_error != null)
            Text(
              _error!,
              key: AppKeys.backupErrorLabel,
              style: const TextStyle(color: Colors.red),
            ),
        ],
      ),
    );
  }
}