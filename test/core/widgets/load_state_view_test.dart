import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/widgets/load_state_view.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('LoadErrorView', () {
    testWidgets('メッセージを表示し再試行ボタンを持つ', (tester) async {
      await tester.pumpWidget(
        _host(LoadErrorView(message: '読み込みに失敗しました', onRetry: () {})),
      );

      expect(find.byKey(const ValueKey('load_error_view')), findsOneWidget);
      expect(find.text('読み込みに失敗しました'), findsOneWidget);
      expect(find.byKey(const ValueKey('load_retry_button')), findsOneWidget);
      // 空状態ウィジェットは同時に出ない
      expect(find.byKey(const ValueKey('load_empty_view')), findsNothing);
    });

    testWidgets('onRetry が null なら再試行ボタンを出さない', (tester) async {
      await tester.pumpWidget(
        _host(const LoadErrorView(message: '復元できません')),
      );

      expect(find.byKey(const ValueKey('load_error_view')), findsOneWidget);
      expect(find.byKey(const ValueKey('load_retry_button')), findsNothing);
      expect(find.text('再試行'), findsNothing);
    });

    testWidgets('再試行ボタンのタップでコールバックが1回呼ばれる', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _host(LoadErrorView(message: '失敗', onRetry: () => calls++)),
      );

      await tester.tap(find.byKey(const ValueKey('load_retry_button')));
      await tester.pumpAndSettle();

      expect(calls, 1);
    });
  });

  group('LoadEmptyView', () {
    testWidgets('メッセージを表示し再試行ボタンを持たない', (tester) async {
      await tester.pumpWidget(
        _host(const LoadEmptyView(message: 'データがありません')),
      );

      expect(find.byKey(const ValueKey('load_empty_view')), findsOneWidget);
      expect(find.text('データがありません'), findsOneWidget);
      expect(find.byKey(const ValueKey('load_retry_button')), findsNothing);
      expect(find.byKey(const ValueKey('load_error_view')), findsNothing);
    });

    testWidgets('エラー文言と空文言は別物として表示される', (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            children: [
              LoadErrorView(message: '読み込みに失敗しました'),
              LoadEmptyView(message: 'データがありません'),
            ],
          ),
        ),
      );

      expect(find.text('読み込みに失敗しました'), findsOneWidget);
      expect(find.text('データがありません'), findsOneWidget);
      expect(find.byKey(const ValueKey('load_error_view')), findsOneWidget);
      expect(find.byKey(const ValueKey('load_empty_view')), findsOneWidget);
    });
  });
}
