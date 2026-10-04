import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/election_archive.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/services/election_recap_service.dart';
import 'package:election_game/features/recap/presentation/election_recap_screen.dart';

void main() {
  final archiveEntries = [
    ElectionArchiveEntry(
      electionId: 'e1',
      title: '第1回村長選挙',
      scale: ElectionScale.village,
      winnerId: 'w1',
      winnerName: '天照太郎',
      winnerVotes: 60,
      totalVotes: 100,
      runnerUpVotes: 40,
      occurredAt: DateTime(2026, 1, 2),
    ),
    ElectionArchiveEntry(
      electionId: 'e2',
      title: '第2回村長選挙',
      scale: ElectionScale.village,
      winnerId: 'w2',
      winnerName: '天照次郎',
      winnerVotes: 45,
      totalVotes: 100,
      runnerUpVotes: 55,
      occurredAt: DateTime(2026, 2, 3),
    ),
  ];

  String recapText(ElectionArchiveEntry entry) =>
      ElectionRecapService.build(entry).text;

  Future<void> pumpRecap(
    WidgetTester tester, {
    List<ElectionArchiveEntry>? entries,
    void Function(String text)? copyHandler,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ElectionRecapScreen(
          entries: entries ?? archiveEntries,
          copyHandler: copyHandler,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ElectionRecapScreen', () {
    testWidgets('エントリ0件なら空状態を表示する', (tester) async {
      await pumpRecap(tester, entries: const []);

      expect(find.byKey(AppKeys.recapEmptyState), findsOneWidget);
      expect(find.text('振り返る選挙がありません'), findsOneWidget);
    });

    testWidgets('タイトルと先頭エントリのrecap.textが表示される', (tester) async {
      await pumpRecap(tester);

      expect(find.byKey(AppKeys.recapTitle), findsOneWidget);
      expect(find.text('選挙の振り返り'), findsOneWidget);
      expect(find.byKey(AppKeys.recapCard), findsOneWidget);
      expect(find.byKey(AppKeys.recapText), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(AppKeys.recapCard),
          matching: find.text(recapText(archiveEntries.first)),
        ),
        findsOneWidget,
      );
    });

    testWidgets('copyHandlerがrecap.textと一致する文字列で呼ばれる', (tester) async {
      final recorded = <String>[];
      await pumpRecap(
        tester,
        copyHandler: recorded.add,
      );

      await tester.tap(find.byKey(AppKeys.recapCopyButton));
      await tester.pumpAndSettle();

      expect(recorded, [recapText(archiveEntries.first)]);
    });

    testWidgets('copyHandler未指定ならClipboardにコピーされる', (tester) async {
      final clipboards = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            final args = call.arguments as Map?;
            clipboards.add(args?['text'] as String);
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
      await pumpRecap(tester);

      await tester.tap(find.byKey(AppKeys.recapCopyButton));
      await tester.pumpAndSettle();

      expect(clipboards, isNotEmpty);
      expect(clipboards.first, recapText(archiveEntries.first));
    });

    testWidgets('コピー後にSnackBarが出る', (tester) async {
      await pumpRecap(tester, copyHandler: (_) {});

      await tester.tap(find.byKey(AppKeys.recapCopyButton));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.recapSnackBar), findsOneWidget);
      expect(find.text('コピーしました'), findsOneWidget);
    });

    testWidgets('セレクタで別エントリに切り替えるとテキストが変わる', (tester) async {
      await pumpRecap(tester);

      await tester.tap(find.byKey(AppKeys.recapSelector));
      await tester.pumpAndSettle();

      final secondRecapText = recapText(archiveEntries.last);
      expect(secondRecapText, isNot(recapText(archiveEntries.first)));
      await tester.tap(find.textContaining('第2回村長選挙').last);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(AppKeys.recapCard),
          matching: find.text(secondRecapText),
        ),
        findsOneWidget,
      );
      // 切り替え後のrecapモデルも正しい
      final recap = ElectionRecapService.build(archiveEntries.last);
      expect(recap.title, '第2回村長選挙');
    });
  });
}
