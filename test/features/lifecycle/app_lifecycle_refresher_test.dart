import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/features/lifecycle/domain/day_rollover_detector.dart';
import 'package:election_game/features/lifecycle/presentation/app_lifecycle_refresher.dart';

/// 前面復帰時の日付跨ぎ再計算ウィジェットの試練。
///
/// [WidgetsBinding.handleAppLifecycleStateChanged] は同一状態の連続通知を
/// 無視しうるため、常に inactive → paused → resumed の遷移を挟んで撃つ。
void main() {
  late DateTime now;
  late int onRolloverCalls;

  Widget buildApp({
    required DayRolloverDetector detector,
    Future<void> Function()? onRollover,
  }) {
    return MaterialApp(
      home: AppLifecycleRefresher(
        detector: detector,
        onRollover: onRollover ??
            () async {
              onRolloverCalls++;
            },
        now: () => now,
        child: const Scaffold(
            body: Text('child', textDirection: TextDirection.ltr)),
      ),
    );
  }

  /// inactive → paused → resumed を通してから resume を撃つ。
  Future<void> resumeFromPaused(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
  }

  setUp(() {
    now = DateTime(2026, 10, 14, 0, 5);
    onRolloverCalls = 0;
  });

  testWidgets('日付跨ぎ後の resumed で onRollover が1回だけ呼ばれる', (tester) async {
    final detector =
        DayRolloverDetector(lastSeen: DateTime(2026, 10, 13, 23, 50));

    await tester.pumpWidget(buildApp(detector: detector));
    await resumeFromPaused(tester);

    expect(onRolloverCalls, 1);
    expect(detector.lastSeen, now);
  });

  testWidgets('paused への遷移だけでは onRollover を呼ばない', (tester) async {
    final detector =
        DayRolloverDetector(lastSeen: DateTime(2026, 10, 13, 23, 50));

    await tester.pumpWidget(buildApp(detector: detector));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(onRolloverCalls, 0);
  });

  testWidgets('同日の resumed では onRollover を呼ばない', (tester) async {
    final detector =
        DayRolloverDetector(lastSeen: DateTime(2026, 10, 14, 0, 1));

    await tester.pumpWidget(buildApp(detector: detector));
    await resumeFromPaused(tester);

    expect(onRolloverCalls, 0);
  });

  testWidgets('onRollover が例外を投げてもウィジェットは生存する', (tester) async {
    final detector =
        DayRolloverDetector(lastSeen: DateTime(2026, 10, 13, 23, 50));
    var calls = 0;

    await tester.pumpWidget(buildApp(
      detector: detector,
      onRollover: () async {
        calls++;
        throw StateError('boom');
      },
    ));
    await resumeFromPaused(tester);

    expect(calls, 1);
    expect(tester.takeException(), isNull);
    expect(find.text('child'), findsOneWidget);
  });

  testWidgets('同じ跨ぎで再入しても二重発火しない', (tester) async {
    final detector =
        DayRolloverDetector(lastSeen: DateTime(2026, 10, 13, 23, 50));

    await tester.pumpWidget(buildApp(detector: detector));
    await resumeFromPaused(tester);
    await resumeFromPaused(tester);

    expect(onRolloverCalls, 1);
  });
}
