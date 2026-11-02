// 天浮橋計画 — election-game スモークテスト
// 単独実行: flutter test integration_test/smoke_test.dart -d <device>
//
// 本番の起動経路（main() → runZonedGuarded → bootstrap() → runApp）をそのまま通し、
// ErrorBoundary / AppLifecycleRefresher を含む実際の配線を検証する。
// pumpAndSettle は使わない（BGM 等の繰り返しアニメーションで永久に待ち続けるため）。
//
// テスト終了時はウィジェットツリーを明示破棄する。これをしないと GameScreen の
// dispose が走らず、audioplayers の FramePositionUpdater がツリー破棄後も
// 残留して "An animation is still running" で落ちる。

import 'package:election_game/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// [finder] が現れるまで、実時間予算 [timeout] の範囲で [step] 刻みに pump する。
///
/// 本番起動は非同期初期化（設定読込・通知・Hive 等）を伴うため、固定回数の pump では
/// 環境次第で足りない。pumpAndSettle は繰り返しアニメーションで終わらないので使わない。
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 60),
  Duration step = const Duration(milliseconds: 250),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (true) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) return;
    if (!DateTime.now().isBefore(deadline)) {
      expect(
        finder,
        findsWidgets,
        reason: '$finder が ${timeout.inSeconds} 秒以内に現れること',
      );
      return;
    }
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('スモーク: 本番起動経路で MaterialApp が配線される', (tester) async {
    // main() は void のため await できない。内部の runApp はゾーン内で同期的に呼ばれる。
    app.main();

    await pumpUntilFound(tester, find.byType(MaterialApp));

    expect(
      find.byType(MaterialApp),
      findsOneWidget,
      reason: 'election-game アプリが正常に起動していること',
    );

    // ツリーを明示破棄する（GameScreen.dispose → BgmService.dispose →
    // AudioPlayer.dispose で position updater を止める）。
    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  });
}
