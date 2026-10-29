import 'dart:async';

import 'package:flutter/material.dart';

import 'package:election_game/features/lifecycle/domain/day_rollover_detector.dart';

/// 前面復帰（resumed）時にだけ日付跨ぎを検出し、跨いでいたら [onRollover] を1回撃つ。
///
/// 設計方針:
/// - 判定は [DayRolloverDetector] に委譲し、本ウィジェットは状態遷移のみを見る。
/// - `resumed` 以外（paused/inactive/hidden/detached）では何もしない。
///   バックグラウンド復帰時の通知再スケジュール等の副作用を二重に起こさないため。
/// - [onRollover] は await せず投げっぱなし（UI をブロックしない）。例外は握って
///   debugPrint のみ。跨ぎ処理の失敗でアプリを落とさない。
/// - 再入防止フラグにより、同一の跨ぎで二重発火しない。
class AppLifecycleRefresher extends StatefulWidget {
  const AppLifecycleRefresher({
    super.key,
    required this.detector,
    required this.onRollover,
    required this.child,
    this.now,
  });

  /// 日付跨ぎ検出器（lastSeen を内部に持つ）。
  final DayRolloverDetector detector;

  /// 跨ぎ時に1回だけ撃つ処理（Provider invalidate・通知再スケジュール等）。
  final Future<void> Function() onRollover;

  /// 監視対象のサブツリー。
  final Widget child;

  /// 現在時刻の供給元（既定 `DateTime.now`、試練では固定値を注入）。
  final DateTime Function()? now;

  @override
  State<AppLifecycleRefresher> createState() => _AppLifecycleRefresherState();
}

class _AppLifecycleRefresherState extends State<AppLifecycleRefresher>
    with WidgetsBindingObserver {
  bool _running = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    final now = (widget.now ?? DateTime.now)();
    final result = widget.detector.check(now);
    if (result != DayRolloverResult.rolledOver) return;
    if (_running) return;

    _running = true;
    unawaited(_run());
  }

  Future<void> _run() async {
    try {
      await widget.onRollover();
    } catch (e) {
      // 跨ぎ再計算の失敗はアプリの継続を妨げない。
      debugPrint('[AppLifecycleRefresher] ⚠️ onRollover 失敗: $e');
    } finally {
      _running = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
