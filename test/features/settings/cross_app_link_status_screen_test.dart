import 'package:election_game/core/infrastructure/cross_app_link_status.dart';
import 'package:election_game/core/infrastructure/cross_app_link_status_store.dart';
import 'package:election_game/features/settings/presentation/cross_app_link_status_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 「連携状況（現世間の受け渡し）」画面の試練。
///
/// 空状態でも「未記録」を出して沈黙しないこと、
/// 失敗は理由まで出すこと、再読込で最新化されることを撃つ。
void main() {
  late InMemoryCrossAppLinkStatusStore store;

  CrossAppLinkStatusRecorder recorderWith(CrossAppLinkSnapshot snapshot) {
    store = InMemoryCrossAppLinkStatusStore(snapshot);
    return CrossAppLinkStatusRecorder(
      store: store,
      now: () => DateTime(2026, 11, 11, 9, 0),
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    CrossAppLinkStatusRecorder recorder,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: CrossAppLinkStatusScreen(recorder: recorder)),
    );
    await tester.pumpAndSettle();
  }

  String textOf(WidgetTester tester, Key key, String text) {
    expect(
      find.descendant(of: find.byKey(key), matching: find.text(text)),
      findsWidgets,
      reason: '$key に「$text」が無い',
    );
    return text;
  }

  group('CrossAppLinkStatusScreen 空状態', () {
    testWidgets('未記録を3行ぶん出し、プレースホルダに留まらない', (tester) async {
      await pumpScreen(tester, recorderWith(CrossAppLinkSnapshot.empty));

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('連携状況'), findsOneWidget);
      textOf(tester, CrossAppLinkStatusScreen.folderKey, '未設定（連携は停止中）');
      textOf(tester, CrossAppLinkStatusScreen.sentKey, '未記録');
      textOf(tester, CrossAppLinkStatusScreen.receivedKey, '未記録');
    });

    testWidgets('ラベル「最終送信」「最終受信」が出る', (tester) async {
      await pumpScreen(tester, recorderWith(CrossAppLinkSnapshot.empty));

      expect(find.text('最終送信'), findsOneWidget);
      expect(find.text('最終受信'), findsOneWidget);
      expect(find.text('共有フォルダ'), findsOneWidget);
    });
  });

  group('CrossAppLinkStatusScreen 記録あり', () {
    testWidgets('成功した送信の 成否・時刻・件数・ファイル名 を出す', (tester) async {
      await pumpScreen(
        tester,
        recorderWith(
          CrossAppLinkSnapshot(
            sharedFolderReady: true,
            lastSent: CrossAppTransferRecord(
              at: DateTime(2026, 11, 11, 9, 12),
              ok: true,
              count: 3,
              fileName: 'election_reward_events.jsonl',
            ),
          ),
        ),
      );

      textOf(tester, CrossAppLinkStatusScreen.folderKey, '設定済み');
      textOf(
        tester,
        CrossAppLinkStatusScreen.sentKey,
        '成功・2026/11/11 09:12・3件・election_reward_events.jsonl',
      );
      textOf(tester, CrossAppLinkStatusScreen.receivedKey, '未記録');
    });

    testWidgets('受信は件数付きで出る（送信とは別行）', (tester) async {
      await pumpScreen(
        tester,
        recorderWith(
          CrossAppLinkSnapshot(
            lastReceived: CrossAppTransferRecord(
              at: DateTime(2026, 11, 10, 21, 30),
              ok: true,
              count: 12,
              fileName: 'tsundoku_reward_events.jsonl',
            ),
          ),
        ),
      );

      textOf(
        tester,
        CrossAppLinkStatusScreen.receivedKey,
        '成功・2026/11/10 21:30・12件・tsundoku_reward_events.jsonl',
      );
      textOf(tester, CrossAppLinkStatusScreen.sentKey, '未記録');
    });

    testWidgets('失敗は「失敗」と理由を出す（無音にしない）', (tester) async {
      await pumpScreen(
        tester,
        recorderWith(
          CrossAppLinkSnapshot(
            lastSent: CrossAppTransferRecord(
              at: DateTime(2026, 11, 11, 9, 12),
              ok: false,
              count: 0,
              fileName: 'election_reward_events.jsonl',
              error: 'SharedStorageException(write, a.jsonl): disk full',
            ),
          ),
        ),
      );

      textOf(
        tester,
        CrossAppLinkStatusScreen.sentKey,
        '失敗・2026/11/11 09:12・0件・election_reward_events.jsonl',
      );
      expect(
        find.descendant(
          of: find.byKey(CrossAppLinkStatusScreen.sentKey),
          matching: find.textContaining('disk full'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('成功時にはエラー色の理由文を出さない', (tester) async {
      await pumpScreen(
        tester,
        recorderWith(
          CrossAppLinkSnapshot(
            lastSent: CrossAppTransferRecord(
              at: DateTime(2026, 11, 11, 9, 12),
              ok: true,
              count: 1,
              fileName: 'a.jsonl',
            ),
          ),
        ),
      );

      expect(find.textContaining('disk'), findsNothing);
      // ラベルと値の2つだけ（理由文の行が増えない）。
      expect(
        find.descendant(
          of: find.byKey(CrossAppLinkStatusScreen.sentKey),
          matching: find.byType(Text),
        ),
        findsNWidgets(2),
      );
    });
  });

  group('CrossAppLinkStatusScreen 再読込', () {
    testWidgets('refresh キーで最新の記録を取り直す', (tester) async {
      final recorder = recorderWith(CrossAppLinkSnapshot.empty);
      await pumpScreen(tester, recorder);
      textOf(tester, CrossAppLinkStatusScreen.sentKey, '未記録');

      // 画面を開いたまま別経路で記録が進む（実機の送受信に相当）。
      await recorder.recordSent(fileName: 'election_reward_events.jsonl');
      await recorder.recordReceived(
          count: 2, fileName: 'election_reward_events.jsonl');

      await tester.tap(find.byKey(CrossAppLinkStatusScreen.refreshKey));
      await tester.pumpAndSettle();

      textOf(
        tester,
        CrossAppLinkStatusScreen.sentKey,
        '成功・2026/11/11 09:00・1件・election_reward_events.jsonl',
      );
      textOf(
        tester,
        CrossAppLinkStatusScreen.receivedKey,
        '成功・2026/11/11 09:00・2件・election_reward_events.jsonl',
      );
    });

    testWidgets('再読込は保存先の最新値を読む（キャッシュを出さない）', (tester) async {
      final recorder = recorderWith(CrossAppLinkSnapshot.empty);
      await pumpScreen(tester, recorder);

      await store.save(
        CrossAppLinkSnapshot(
          sharedFolderReady: true,
          lastReceived: CrossAppTransferRecord(
            at: DateTime(2026, 11, 9, 8, 5),
            ok: true,
            count: 7,
            fileName: 'x.jsonl',
          ),
        ),
      );

      await tester.tap(find.byKey(CrossAppLinkStatusScreen.refreshKey));
      await tester.pumpAndSettle();

      textOf(tester, CrossAppLinkStatusScreen.folderKey, '設定済み');
      textOf(
        tester,
        CrossAppLinkStatusScreen.receivedKey,
        '成功・2026/11/09 08:05・7件・x.jsonl',
      );
    });
  });
}
