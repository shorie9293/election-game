import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/crash/error_boundary.dart';
import 'package:election_game/core/testing/app_keys.dart';

/// 指定回数だけ build で例外を投げる子。
class _ExplodingChild extends StatelessWidget {
  const _ExplodingChild({required this.shouldThrow});

  final bool shouldThrow;

  @override
  Widget build(BuildContext context) {
    if (shouldThrow) throw StateError('build 失敗');
    return const Text('復帰した画面');
  }
}

/// 生成回数を数える子（再構築の検証用）。
class _CountingChild extends StatefulWidget {
  const _CountingChild({required this.onCreate});

  final VoidCallback onCreate;

  @override
  State<_CountingChild> createState() => _CountingChildState();
}

class _CountingChildState extends State<_CountingChild> {
  @override
  void initState() {
    super.initState();
    widget.onCreate();
  }

  @override
  Widget build(BuildContext context) => const Text('本文');
}

void main() {
  group('ErrorBoundary', () {
    testWidgets('子の例外を捕捉し日本語の復帰UIを出す', (tester) async {
      final reported = <Object>[];

      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            onError: (details) => reported.add(details.exception),
            child: const _ExplodingChild(shouldThrow: true),
          ),
        ),
      );

      // build 中の例外はテスト基盤へ報告される。1回だけ受け取って消費する。
      expect(tester.takeException(), isA<StateError>());
      await tester.pumpAndSettle();

      expect(reported, hasLength(1));
      expect(find.byKey(AppKeys.errorBoundaryFallback), findsOneWidget);
      expect(find.text('表示中に問題が発生しました'), findsOneWidget);
      expect(find.byKey(AppKeys.errorBoundaryReloadButton), findsOneWidget);
      expect(find.text('再読み込み'), findsOneWidget);
    });

    testWidgets('再読み込みで child が再構築され元の画面に戻る', (tester) async {
      var shouldThrow = true;

      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            child: StatefulBuilder(
              builder: (context, setState) => _ExplodingChild(
                shouldThrow: shouldThrow,
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isA<StateError>());
      await tester.pumpAndSettle();
      expect(find.byKey(AppKeys.errorBoundaryFallback), findsOneWidget);

      // 例外の原因が解消された状態で再読み込みする。
      shouldThrow = false;
      await tester.tap(find.byKey(AppKeys.errorBoundaryReloadButton));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.errorBoundaryFallback), findsNothing);
      expect(find.text('復帰した画面'), findsOneWidget);
    });

    testWidgets('再読み込みで child の State が作り直される（generation が進む）', (tester) async {
      var created = 0;
      var shouldThrow = true;

      Widget buildChild() => Builder(
            builder: (context) {
              if (shouldThrow) throw StateError('build 失敗');
              return _CountingChild(onCreate: () => created++);
            },
          );

      await tester.pumpWidget(
        MaterialApp(home: ErrorBoundary(child: buildChild())),
      );
      expect(tester.takeException(), isA<StateError>());
      await tester.pumpAndSettle();
      expect(created, 0);

      shouldThrow = false;
      await tester.tap(find.byKey(AppKeys.errorBoundaryReloadButton));
      await tester.pumpAndSettle();

      expect(created, 1);
      expect(find.text('本文'), findsOneWidget);
    });

    testWidgets('例外がなければ child をそのまま表示する', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            child: const Text('平常時の本文'),
          ),
        ),
      );

      expect(find.text('平常時の本文'), findsOneWidget);
      expect(find.byKey(AppKeys.errorBoundaryFallback), findsNothing);
    });

    testWidgets('dispose で ErrorWidget.builder を元へ戻す', (tester) async {
      final before = ErrorWidget.builder;

      await tester.pumpWidget(
        MaterialApp(home: ErrorBoundary(child: const Text('本文'))),
      );
      expect(identical(ErrorWidget.builder, before), isFalse);

      await tester.pumpWidget(const MaterialApp(home: Text('差し替え後')));
      expect(identical(ErrorWidget.builder, before), isTrue);
    });

    testWidgets('Semantics にボタンとして露出する', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            child: const _ExplodingChild(shouldThrow: true),
          ),
        ),
      );
      expect(tester.takeException(), isA<StateError>());
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(RegExp('再読み込み')),
        findsWidgets,
      );
    });
  });
}
