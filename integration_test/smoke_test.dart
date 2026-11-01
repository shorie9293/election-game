// 天浮橋計画 — election-game スモークテスト
// 単独実行: flutter test integration_test/smoke_test.dart -d <device>
//
// CI では実資格情報を渡さないため、アプリの起動配線（Binding → ProviderScope →
// MaterialApp の生成）だけを検証する。pumpAndSettle は使わない
// （繰り返しアニメーションがあると永久に待ち続けるため）。

import 'package:election_game/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('スモーク: アプリ起動と MaterialApp の配線', (tester) async {
    // 本番（main.dart の runApp）と同じく ProviderScope の内側で起動する。
    await tester.pumpWidget(
      ProviderScope(child: app.ElectionGameApp()),
    );

    // 固定回数の pump で起動直後の非同期初期化（設定読込・時刻タップ等）を進める。
    await tester.pump(const Duration(seconds: 1));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(
      find.byType(MaterialApp),
      findsOneWidget,
      reason: 'election-game アプリが正常に起動していること',
    );
  });
}
