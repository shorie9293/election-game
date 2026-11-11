import 'package:election_game/core/infrastructure/cross_app_link_status.dart';
import 'package:election_game/core/infrastructure/cross_app_link_status_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// 記録口の契約を撃つ試練。
///
/// 契約は3つ:
/// - どのメソッドも **throw しない**（記録の失敗で本処理を止めない）
/// - 書込は直列化される（同時送信で取りこぼさない）
/// - 初回記録の前に保存済み状態を読む（前回起動分を消さない）
void main() {
  late InMemoryCrossAppLinkStatusStore store;
  late CrossAppLinkStatusRecorder recorder;
  final fixed = DateTime(2026, 11, 11, 9, 0);

  setUp(() {
    store = InMemoryCrossAppLinkStatusStore();
    recorder = CrossAppLinkStatusRecorder(store: store, now: () => fixed);
  });

  group('CrossAppLinkStatusRecorder の記録', () {
    test('recordSent は 成否true・件数・ファイル名・時刻を残す', () async {
      await recorder.recordSent(fileName: 'election_reward_events.jsonl');

      final sent = recorder.cached.lastSent;
      expect(sent, isNotNull);
      expect(sent!.ok, isTrue);
      expect(sent.count, 1);
      expect(sent.fileName, 'election_reward_events.jsonl');
      expect(sent.at, fixed);
      expect(sent.error, isNull);
      expect(store.saveCount, 1);
    });

    test('recordSent の件数指定が反映される', () async {
      await recorder.recordSent(count: 4, fileName: 'a.jsonl');

      expect(recorder.cached.lastSent!.count, 4);
    });

    test('recordSendFailure は 成否false・理由・件数0 を残す', () async {
      await recorder.recordSendFailure(
        StateError('disk full'),
        fileName: 'a.jsonl',
      );

      final sent = recorder.cached.lastSent;
      expect(sent!.ok, isFalse);
      expect(sent.count, 0);
      expect(sent.error, contains('disk full'));
      expect(sent.fileName, 'a.jsonl');
    });

    test('recordReceived / recordReceiveFailure は受信側だけを更新する', () async {
      await recorder.recordReceived(count: 3, fileName: 'b.jsonl');
      expect(recorder.cached.lastReceived!.ok, isTrue);
      expect(recorder.cached.lastReceived!.count, 3);
      expect(recorder.cached.lastSent, isNull);

      await recorder.recordReceiveFailure(
        const FormatException('broken'),
        fileName: 'b.jsonl',
      );
      expect(recorder.cached.lastReceived!.ok, isFalse);
      expect(recorder.cached.lastReceived!.error, contains('broken'));
      expect(recorder.cached.lastSent, isNull);
    });

    test('送信と受信は互いを上書きしない', () async {
      await recorder.recordSent(count: 2, fileName: 'sent.jsonl');
      await recorder.recordReceived(count: 5, fileName: 'received.jsonl');

      expect(recorder.cached.lastSent!.fileName, 'sent.jsonl');
      expect(recorder.cached.lastSent!.count, 2);
      expect(recorder.cached.lastReceived!.fileName, 'received.jsonl');
      expect(recorder.cached.lastReceived!.count, 5);
    });

    test('recordFolderReady は共有フォルダの可否だけを変える', () async {
      await recorder.recordFolderReady(true);
      expect(recorder.cached.sharedFolderReady, isTrue);

      await recorder.recordFolderReady(false);
      expect(recorder.cached.sharedFolderReady, isFalse);
      expect(recorder.cached.lastSent, isNull);
    });
  });

  group('CrossAppLinkStatusRecorder の耐性', () {
    test('保存が throw しても呼び出し側へ漏れない', () async {
      store.throwOnSave = true;

      await expectLater(
        recorder.recordSent(fileName: 'a.jsonl'),
        completes,
      );
      await expectLater(
        recorder.recordSendFailure(StateError('x'), fileName: 'a.jsonl'),
        completes,
      );
      await expectLater(recorder.recordReceived(), completes);
      await expectLater(recorder.recordFolderReady(true), completes);

      // 保存は失敗してもメモリ側の状態は進む（画面が古い値を出さない）。
      expect(recorder.cached.lastSent!.fileName, 'a.jsonl');
      expect(recorder.cached.sharedFolderReady, isTrue);
    });

    test('load が throw しても空で立ち上がり、記録は続く', () async {
      final throwing = CrossAppLinkStatusRecorder(
        store: _ThrowingLoadStore(),
        now: () => fixed,
      );

      await expectLater(throwing.load(), completes);
      expect(throwing.cached.lastSent, isNull);

      await expectLater(throwing.recordSent(count: 1), completes);
      expect(throwing.cached.lastSent!.count, 1);
    });

    test('並行10件を投げても取りこぼさず、最後の記録が勝つ', () async {
      final futures = <Future<void>>[];
      for (var i = 1; i <= 10; i++) {
        futures.add(recorder.recordReceived(count: i, fileName: 'n$i.jsonl'));
      }
      await Future.wait(futures);

      expect(store.saveCount, 10);
      expect(recorder.cached.lastReceived!.count, 10);
      expect(recorder.cached.lastReceived!.fileName, 'n10.jsonl');
    });

    test('load 前の記録でも、前回保存した受信記録を消さない', () async {
      final previous = CrossAppLinkSnapshot(
        lastReceived: CrossAppTransferRecord(
          at: DateTime(2026, 11, 10, 21, 30),
          ok: true,
          count: 2,
          fileName: 'previous.jsonl',
        ),
        sharedFolderReady: true,
      );
      final fresh = CrossAppLinkStatusRecorder(
        store: InMemoryCrossAppLinkStatusStore(previous),
        now: () => fixed,
      );

      await fresh.recordSent(fileName: 'new.jsonl');

      expect(fresh.cached.lastReceived!.fileName, 'previous.jsonl');
      expect(fresh.cached.lastReceived!.count, 2);
      expect(fresh.cached.sharedFolderReady, isTrue);
      expect(fresh.cached.lastSent!.fileName, 'new.jsonl');
    });

    test('reset で instance を差し替えられる（試練の前提）', () {
      final injected = CrossAppLinkStatusRecorder(store: store);
      final before = CrossAppLinkStatusRecorder.instance;

      CrossAppLinkStatusRecorder.reset(injected);
      expect(CrossAppLinkStatusRecorder.instance, same(injected));

      CrossAppLinkStatusRecorder.reset(before);
      expect(CrossAppLinkStatusRecorder.instance, same(before));
    });
  });
}

/// load が必ず失敗する保存先。
class _ThrowingLoadStore implements ICrossAppLinkStatusStore {
  @override
  Future<CrossAppLinkSnapshot> load() async => throw StateError('load failed');

  @override
  Future<void> save(CrossAppLinkSnapshot snapshot) async {}
}
