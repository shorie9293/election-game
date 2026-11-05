import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/core/infrastructure/app_lock_repository.dart';
import 'package:election_game/core/infrastructure/app_lock_service.dart';
import 'package:election_game/core/infrastructure/lock_attempt_policy.dart';
import 'package:election_game/core/infrastructure/lock_recovery_policy.dart';
import 'package:election_game/core/infrastructure/lock_recovery_service.dart';
import 'package:election_game/core/infrastructure/lock_reload_policy.dart';
import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/features/auto_backup/data/auto_backup_store.dart';
import 'package:election_game/features/backup/data/game_data_backup_repository.dart';
import 'package:election_game/features/backup/domain/game_data_backup.dart';

/// アプリロック有効時に全UIを隠すゲートWidget。
/// repository は注入可能（試練用）。デフォルトは実 SharedPreferences。
/// 読込例外・生成失敗は握りつぶして素通り（fail-open）。
class AppLockGate extends StatefulWidget {
  final WidgetBuilder unlockedBuilder;
  final AppLockRepository? repository;

  /// 時刻注入（試練用）。既定は [DateTime.now]。
  final DateTime Function()? now;

  /// 再施錠猶予の上書き（試練用）。既定は設定値（service.relockGrace）。
  final Duration? graceOverride;

  /// パスコード忘却時の回復役（試練用）。未注入なら本番実装を組み立てる。
  final LockRecoveryService? recoveryService;

  const AppLockGate({
    super.key,
    required this.unlockedBuilder,
    this.repository,
    this.now,
    this.graceOverride,
    this.recoveryService,
  });

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  AppLockService? _service;
  LockRecoveryService? _recovery;
  bool _initialized = false;
  bool _locked = false;
  bool _obscure = true;
  final _codeController = TextEditingController();
  String? _error;

  /// 背景化した時刻（復帰時再施錠の猶予判定に使う）。
  DateTime? _backgroundedAt;
  Duration _grace = Duration.zero;

  DateTime _now() => (widget.now ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    try {
      final repo = widget.repository ??
          SharedPreferencesAppLockRepository(
            await SharedPreferences.getInstance(),
          );
      final service = AppLockService(repo, now: _now);
      if (!mounted) return;
      setState(() {
        _service = service;
        _recovery = widget.recoveryService ?? _buildProductionRecovery(service);
        _locked = service.isLocked;
        _grace = widget.graceOverride ?? service.relockGrace;
        _initialized = true;
      });
    } catch (_) {
      // fail-open: 読込に失敗してもアプリは素通りで起動する
      if (!mounted) return;
      setState(() {
        _service = null;
        _locked = false;
        _initialized = true;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _codeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        // 最初の背景化時刻だけを保持する（inactive→paused の連続で上書きしない）。
        _backgroundedAt ??= _now();
      case AppLifecycleState.resumed:
        _handleResumed();
      case AppLifecycleState.detached:
        break;
    }
  }

  void _handleResumed() {
    final service = _service;
    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;
    if (!mounted || service == null) return;
    if (!service.isLocked) return;
    if (!LockReloadPolicy.shouldRelock(backgroundedAt, _now(), _grace)) {
      return;
    }
    setState(() {
      _locked = true;
      _error = null;
      _codeController.clear();
    });
  }

  Future<void> _submit() async {
    final service = _service;
    if (service == null) return;
    if (service.isLockedOut) {
      return;
    }
    final ok = await service.unlock(passcode: _codeController.text);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _locked = false;
        _error = null;
      });
    } else {
      setState(() => _error = 'パスコードが正しくありません');
    }
    _codeController.clear();
  }

  /// 本番の回復役。既存のバックアップ書き出し・全データ消去を再利用する
  /// （新しい破壊経路は作らない）。
  LockRecoveryService _buildProductionRecovery(AppLockService service) {
    return LockRecoveryService(
      service,
      backupExporter: () async {
        const repository = SharedPreferencesGameDataBackupRepository();
        final data = await repository.collect();
        final json = const GameDataBackupService().build(data);
        final fileName =
            'recovery_backup_${_now().millisecondsSinceEpoch}.json';
        await FileAutoBackupStore().write(fileName, json);
      },
      dataEraser: () =>
          const SharedPreferencesGameDataBackupRepository().clear(),
    );
  }

  Future<void> _openRecovery() async {
    final recovery = _recovery;
    if (recovery == null) return;
    final result = await showDialog<LockRecoveryResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _LockRecoveryDialog(service: recovery),
    );
    if (!mounted || result == null || !result.accepted) return;
    setState(() {
      _locked = false;
      _error = null;
      _codeController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_recoveryMessage(result))),
    );
  }

  String _recoveryMessage(LockRecoveryResult result) {
    final buffer = StringBuffer('ロックを解除しました');
    buffer.write(
      result.dataWiped ? '。データを初期化しました' : '。データの初期化に失敗しました',
    );
    if (result.backupFailed) {
      buffer.write('（バックアップの書き出しに失敗）');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_locked) {
      return widget.unlockedBuilder(context);
    }
    final service = _service;
    final lockedOut = service?.isLockedOut ?? false;
    final remaining = lockedOut ? service!.lockoutRemainingSeconds : 0;
    return Scaffold(
      key: AppKeys.appLockGateScreen,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 48),
              const SizedBox(height: 16),
              const Text('election-game はロックされています'),
              const SizedBox(height: 24),
              TextField(
                key: AppKeys.appLockGateField,
                controller: _codeController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 4,
                obscureText: _obscure,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'パスコード',
                  errorText: _error,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
              if (lockedOut) ...[
                const SizedBox(height: 8),
                Text(
                  LockAttemptPolicy.lockoutLabel(remaining),
                  key: AppKeys.appLockLockoutLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                key: AppKeys.appLockGateUnlockButton,
                onPressed: lockedOut ? null : _submit,
                child: const Text('解除する'),
              ),
              const SizedBox(height: 8),
              TextButton(
                key: AppKeys.appLockForgotButton,
                onPressed: _openRecovery,
                child: const Text('パスコードをお忘れですか？'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 二段確認ダイアログ。実行すると結果を持って閉じる。
class _LockRecoveryDialog extends StatefulWidget {
  final LockRecoveryService service;

  const _LockRecoveryDialog({required this.service});

  @override
  State<_LockRecoveryDialog> createState() => _LockRecoveryDialogState();
}

class _LockRecoveryDialogState extends State<_LockRecoveryDialog> {
  final _confirmController = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    if (_busy) return;
    if (!LockRecoveryPolicy.isConfirmationValid(_confirmController.text)) {
      setState(
          () => _error = '「${LockRecoveryPolicy.confirmationPhrase}」と入力してください');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.service.recover(
      confirmation: _confirmController.text,
    );
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('パスコードを忘れた場合'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LockRecoveryPolicy.warningMessage,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 16),
            Text(
              '続行するには「${LockRecoveryPolicy.confirmationPhrase}」と入力してください。',
            ),
            const SizedBox(height: 8),
            TextField(
              key: AppKeys.appLockRecoveryConfirmField,
              controller: _confirmController,
              enabled: !_busy,
              decoration: InputDecoration(errorText: _error),
              onSubmitted: (_) => _run(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('やめる'),
        ),
        FilledButton(
          key: AppKeys.appLockRecoveryConfirmButton,
          onPressed: _busy ? null : _run,
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('初期化して解除する'),
        ),
      ],
    );
  }
}
