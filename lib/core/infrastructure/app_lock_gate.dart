import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/core/infrastructure/app_lock_repository.dart';
import 'package:election_game/core/infrastructure/app_lock_service.dart';
import 'package:election_game/core/infrastructure/lock_attempt_policy.dart';
import 'package:election_game/core/infrastructure/lock_reload_policy.dart';
import 'package:election_game/core/testing/app_keys.dart';

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

  const AppLockGate({
    super.key,
    required this.unlockedBuilder,
    this.repository,
    this.now,
    this.graceOverride,
  });

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate>
    with WidgetsBindingObserver {
  AppLockService? _service;
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
            ],
          ),
        ),
      ),
    );
  }
}
