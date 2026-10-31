import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/crash/crash_log_entry.dart';
import 'package:election_game/core/crash/crash_log_repository.dart';
import 'package:election_game/core/crash/crash_log_screen.dart';
import 'package:election_game/core/testing/app_keys.dart';

CrashLogEntry _entry(int minute, {String? message}) => CrashLogEntry(
      timestamp: DateTime(2026, 11, 1, 3, minute),
      kind: CrashLogKind.framework,
      message: message ?? 'エラー$minute',
      stackTop: '#0 frame$minute',
    );

void main() {
  group('CrashLogScreen', () {
    testWidgets('記録が無ければ空状態を出す', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CrashLogScreen(
            repository: InMemoryCrashLogRepository(),
            now: () => DateTime(2026, 11, 1, 12),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.crashLogScreen), findsOneWidget);
      expect(find.byKey(AppKeys.crashLogEmptyState), findsOneWidget);
      expect(find.text('記録された不具合はありません'), findsOneWidget);
      expect(find.byKey(AppKeys.crashLogSummary), findsNothing);
      expect(find.byKey(AppKeys.crashLogCopyButton), findsNothing);
    });

    testWidgets('記録があればサマリーと一覧を出す', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CrashLogScreen(
            repository: InMemoryCrashLogRepository(
              initial: [_entry(5), _entry(9, message: '最新のエラー')],
            ),
            now: () => DateTime(2026, 11, 1, 12),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('前回の異常終了 2件（最終 03:09）'),
        findsOneWidget,
      );
      expect(find.text('最新のエラー'), findsOneWidget);
      expect(find.text('エラー5'), findsOneWidget);
      expect(find.byKey(AppKeys.crashLogCopyButton), findsOneWidget);
    });

    testWidgets('クリップボードへコピーで全件の文言が渡る', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: CrashLogScreen(
            repository: InMemoryCrashLogRepository(
              initial: [_entry(5), _entry(9)],
            ),
            now: () => DateTime(2026, 11, 1, 12),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(AppKeys.crashLogCopyButton));
      await tester.pumpAndSettle();

      expect(copied, isNotNull);
      expect(copied, contains('エラー5'));
      expect(copied, contains('エラー9'));
      expect(copied, contains('[framework]'));
      expect(find.text('クリップボードへコピーしました'), findsOneWidget);
    });

    testWidgets('AppBar は「不具合の報告」', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CrashLogScreen(repository: InMemoryCrashLogRepository()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('不具合の報告'),
        ),
        findsOneWidget,
      );
    });
  });

  group('CrashReportTile', () {
    testWidgets('記録0件なら件数を付けない', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CrashReportTile(
              repository: InMemoryCrashLogRepository(),
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.settingsHubCrashLogTile), findsOneWidget);
      expect(find.text('不具合の報告'), findsOneWidget);
    });

    testWidgets('記録があれば「(N)」を付ける', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CrashReportTile(
              repository: InMemoryCrashLogRepository(
                initial: [_entry(1), _entry(2), _entry(3)],
              ),
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('不具合の報告 (3)'), findsOneWidget);
    });

    testWidgets('タップで遷移が呼ばれる', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CrashReportTile(
              repository: InMemoryCrashLogRepository(),
              onTap: () => taps++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(AppKeys.settingsHubCrashLogTile));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });
  });
}
