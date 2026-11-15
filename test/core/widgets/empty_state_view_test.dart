import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/widgets/empty_state.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('EmptyStateSpec', () {
    test('見出しのみなら説明と操作は null', () {
      final spec = EmptyStateSpec(title: 'まだ記録がありません');

      expect(spec.title, 'まだ記録がありません');
      expect(spec.description, isNull);
      expect(spec.actionLabel, isNull);
      expect(spec.onAction, isNull);
    });

    test('見出しが空文字なら ArgumentError', () {
      expect(
        () => EmptyStateSpec(title: ''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('見出しが空白のみなら ArgumentError', () {
      expect(
        () => EmptyStateSpec(title: '   '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('actionLabel だけ指定すると ArgumentError', () {
      expect(
        () => EmptyStateSpec(title: '見出し', actionLabel: '始める'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('onAction だけ指定すると ArgumentError', () {
      expect(
        () => EmptyStateSpec(title: '見出し', onAction: () {}),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('actionLabel と onAction を同時に指定すると保持される', () {
      void action() {}
      final spec =
          EmptyStateSpec(title: '見出し', actionLabel: '始める', onAction: action);

      expect(spec.actionLabel, '始める');
      expect(spec.onAction, same(action));
    });
  });

  group('EmptyStateView', () {
    testWidgets('見出しのみを表示し、説明・アイコン・ボタンは描画しない', (tester) async {
      await tester.pumpWidget(
        _host(
          EmptyStateView(
            key: const ValueKey('empty_state_a'),
            spec: EmptyStateSpec(title: 'まだ記録がありません'),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('empty_state_a')), findsOneWidget);
      expect(find.text('まだ記録がありません'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.text('始める'), findsNothing);
    });

    testWidgets('説明を渡すと見出しと並べて表示する', (tester) async {
      await tester.pumpWidget(
        _host(
          EmptyStateView(
            key: const ValueKey('empty_state_b'),
            spec: EmptyStateSpec(
              title: 'まだ記録がありません',
              description: '間違えた問題がここに貯まります。',
            ),
          ),
        ),
      );

      expect(find.text('まだ記録がありません'), findsOneWidget);
      expect(find.text('間違えた問題がここに貯まります。'), findsOneWidget);
    });

    testWidgets('アイコンを渡すと指定サイズで表示する', (tester) async {
      await tester.pumpWidget(
        _host(
          EmptyStateView(
            key: const ValueKey('empty_state_c'),
            spec: EmptyStateSpec(title: '空です'),
            icon: Icons.menu_book,
            iconSize: 48,
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.menu_book);
      expect(icon.size, 48);
    });

    testWidgets('操作を渡すとボタンを描画し、タップで1回だけ呼ばれる', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _host(
          EmptyStateView(
            key: const ValueKey('empty_state_d'),
            spec: EmptyStateSpec(
              title: '空です',
              actionLabel: 'クイズを始める',
              onAction: () => calls++,
            ),
          ),
        ),
      );

      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.text('クイズを始める'), findsOneWidget);

      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();

      expect(calls, 1);
    });

    testWidgets('操作が null なら操作ラベルも描画しない', (tester) async {
      await tester.pumpWidget(
        _host(
          EmptyStateView(
            key: const ValueKey('empty_state_e'),
            spec: EmptyStateSpec(title: '空です', description: '説明'),
          ),
        ),
      );

      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
    });
  });
}
