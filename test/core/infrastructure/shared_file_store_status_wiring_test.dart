import 'dart:io';

import 'package:election_game/core/infrastructure/cross_app_link_status.dart';
import 'package:election_game/core/infrastructure/cross_app_link_status_store.dart';
import 'package:election_game/core/infrastructure/shared_file_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// 共有ファイルの実读写が「連携状況」へ記録されることの試練。
///
/// 記録は本処理を止めないため `unawaited` で走る。ここでは
/// 記録が実際に届くまで待ってから検証する（待たずに assert すると
/// 実装が正しくても赤くなる＝試練の意味が無い）。
void main() {
  late Directory tempDir;
  late InMemoryCrossAppLinkStatusStore statusStore;
  late CrossAppLinkStatusRecorder recorder;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('election_link_status_');
    statusStore = InMemoryCrossAppLinkStatusStore();
    recorder = CrossAppLinkStatusRecorder(
      store: statusStore,
      now: () => DateTime(2026, 11, 11, 9, 0),
    );
    CrossAppLinkStatusRecorder.reset(recorder);
  });

  tearDown(() {
    CrossAppLinkStatusRecorder.reset();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<void> waitFor(
    bool Function(CrossAppLinkSnapshot snapshot) condition,
    String reason,
  ) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!condition(recorder.cached)) {
      if (DateTime.now().isAfter(deadline)) {
        fail('記録が届かなかった: $reason / 現在=${recorder.cached.encode()}');
      }
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
  }

  group('FileSharedFileStore → 連携状況', () {
    test('writeString は送信1件として記録される', () async {
      final store = FileSharedFileStore(tempDir);

      await store.writeString(SharedCrossAppFiles.electionRewardEvents, '{}');
      await waitFor((s) => s.lastSent != null, 'writeString');

      final sent = recorder.cached.lastSent!;
      expect(sent.ok, isTrue);
      expect(sent.count, 1);
      expect(sent.fileName, SharedCrossAppFiles.electionRewardEvents);
      expect(sent.at, DateTime(2026, 11, 11, 9, 0));
      expect(recorder.cached.lastReceived, isNull);
    });

    test('appendLine は送信1件として記録される', () async {
      final store = FileSharedFileStore(tempDir);

      await store.appendLine(
          SharedCrossAppFiles.electionRewardEvents, '{"a":1}');
      await waitFor((s) => s.lastSent != null, 'appendLine');

      expect(recorder.cached.lastSent!.ok, isTrue);
      expect(recorder.cached.lastSent!.count, 1);
      expect(
        recorder.cached.lastSent!.fileName,
        SharedCrossAppFiles.electionRewardEvents,
      );
    });

    test('readString は受信として行数ぶんの件数で記録される', () async {
      final store = FileSharedFileStore(tempDir);
      await store.writeString('a.jsonl', '1行目\n2行目\n3行目\n');
      await waitFor((s) => s.lastSent != null, '準備の writeString');

      final content = await store.readString('a.jsonl');
      await waitFor((s) => s.lastReceived != null, 'readString');

      expect(content, '1行目\n2行目\n3行目\n');
      final received = recorder.cached.lastReceived!;
      expect(received.ok, isTrue);
      expect(received.count, 3);
      expect(received.fileName, 'a.jsonl');
    });

    test('存在しないファイルの readString は記録しない', () async {
      final store = FileSharedFileStore(tempDir);

      final content = await store.readString('missing.jsonl');
      // 記録が「無いこと」を確かめるため、同期的に数フレーム待つ。
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(content, isNull);
      expect(recorder.cached.lastReceived, isNull);
      expect(recorder.cached.lastSent, isNull);
    });

    test('ensureDirectory はフォルダ状態を記録する', () async {
      final store = FileSharedFileStore(tempDir);

      expect(await store.ensureDirectory(), isTrue);
      await waitFor((s) => s.sharedFolderReady, 'ensureDirectory(true)');
    });

    test('書込失敗は送信失敗（ok=false・理由つき）で記録され、例外は元の型', () async {
      final blocker = File('${tempDir.path}/blocked')
        ..writeAsStringSync('このパスはファイル');
      final store = FileSharedFileStore(Directory(blocker.path));

      await expectLater(
        store.writeString('a.jsonl', '{}'),
        throwsA(isA<SharedStorageException>()),
      );
      await waitFor((s) => s.lastSent != null, 'writeString 失敗');

      final sent = recorder.cached.lastSent!;
      expect(sent.ok, isFalse);
      expect(sent.count, 0);
      expect(sent.fileName, 'a.jsonl');
      expect(sent.error, isNotNull);
      expect(sent.error!.isNotEmpty, isTrue);
    });

    test('appendLine 失敗も送信失敗として記録される', () async {
      final blocker = File('${tempDir.path}/blocked2')
        ..writeAsStringSync('このパスはファイル');
      final store = FileSharedFileStore(Directory(blocker.path));

      await expectLater(
        store.appendLine('a.jsonl', '{}'),
        throwsA(isA<SharedStorageException>()),
      );
      await waitFor((s) => s.lastSent != null, 'appendLine 失敗');

      expect(recorder.cached.lastSent!.ok, isFalse);
      expect(recorder.cached.lastSent!.fileName, 'a.jsonl');
    });

    test('delete / exists / listFiles は送受信を記録しない', () async {
      final store = FileSharedFileStore(tempDir);
      await store.writeString('exists.jsonl', 'x\n');
      await waitFor((s) => s.lastSent != null, '準備の writeString');
      final sentAt = recorder.cached.lastSent!.at;
      final saveCountBefore = statusStore.saveCount;

      await store.exists('exists.jsonl');
      await store.listFiles();
      await store.delete('exists.jsonl');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(statusStore.saveCount, saveCountBefore);
      expect(recorder.cached.lastSent!.at, sentAt);
      expect(recorder.cached.lastReceived, isNull);
    });
  });
}
