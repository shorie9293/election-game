import 'dart:io';

import 'package:election_game/core/infrastructure/shared_file_store.dart';
import 'package:election_game/features/crossapp/data/election_reward_event_exporter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// フェイクの共有ストア。追記された行をそのまま保持する。
class _FakeSharedFileStore implements ISharedFileStore {
  final List<String> lines = <String>[];
  final List<String> written = <String>[];
  bool failOnAppend = false;

  @override
  Future<bool> ensureDirectory() async => true;

  @override
  Future<bool> chooseDirectory() async => true;

  @override
  Future<void> writeString(String fileName, String content) async {
    written.add('$fileName:$content');
  }

  @override
  Future<void> appendLine(String fileName, String line) async {
    if (failOnAppend) {
      throw const SharedStorageException(
          'append', 'election_reward_events.jsonl', 'boom');
    }
    lines.add('$fileName:$line');
  }

  @override
  Future<String?> readString(String fileName) async => null;

  @override
  Future<bool> delete(String fileName) async => false;

  @override
  Future<bool> exists(String fileName) async => false;

  @override
  Future<List<String>> listFiles() async => const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FileSharedFileStore', () {
    late Directory tempDir;
    late FileSharedFileStore store;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('shared_file_store');
      store = FileSharedFileStore(Directory('${tempDir.path}/shared'));
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('ensureDirectory は保存先ディレクトリを作る', () async {
      expect(Directory('${tempDir.path}/shared').existsSync(), isFalse);
      expect(await store.ensureDirectory(), isTrue);
      expect(Directory('${tempDir.path}/shared').existsSync(), isTrue);
    });

    test('writeString → readString で内容が往復する', () async {
      await store.writeString('a.json', '{"x":1}');
      expect(await store.readString('a.json'), '{"x":1}');
    });

    test('appendLine は改行終端で追記する', () async {
      await store.appendLine('events.jsonl', '{"n":1}');
      await store.appendLine('events.jsonl', '{"n":2}');
      expect(
        await store.readString('events.jsonl'),
        '{"n":1}\n{"n":2}\n',
      );
    });

    test('readString は存在しないファイルで null', () async {
      expect(await store.readString('missing.json'), isNull);
    });

    test('delete は存在時 true・不在時 false', () async {
      await store.writeString('a.json', 'x');
      expect(await store.delete('a.json'), isTrue);
      expect(await store.delete('a.json'), isFalse);
    });

    test('exists と listFiles が実ファイルを反映する', () async {
      await store.writeString('a.json', 'x');
      await store.writeString('b.jsonl', 'y');
      expect(await store.exists('a.json'), isTrue);
      expect(await store.exists('missing.json'), isFalse);
      expect(
        (await store.listFiles()).toSet(),
        {'a.json', 'b.jsonl'},
      );
    });

    test('書込失敗は無音にせず SharedStorageException を投げる', () async {
      final blocker = File('${tempDir.path}/blocker');
      await blocker.writeAsString('not a directory');
      final broken = FileSharedFileStore(Directory('${blocker.path}/sub'));

      await expectLater(
        broken.writeString('a.json', 'x'),
        throwsA(
          isA<SharedStorageException>()
              .having((e) => e.operation, 'operation', 'write')
              .having((e) => e.fileName, 'fileName', 'a.json'),
        ),
      );
      await expectLater(
        broken.appendLine('a.jsonl', 'x'),
        throwsA(
          isA<SharedStorageException>()
              .having((e) => e.operation, 'operation', 'append'),
        ),
      );
    });
  });

  group('AndroidSharedFileStore', () {
    const channel = MethodChannel(comShorieElectionSharedChannel);
    late List<MethodCall> calls;
    Object? Function(MethodCall call)? responder;

    setUp(() {
      calls = <MethodCall>[];
      responder = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return responder?.call(call);
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('appendLine は MethodChannel へ name/line を渡す', () async {
      responder = (call) => call.method == 'ensureDirectory' ? true : null;
      final store = AndroidSharedFileStore();

      await store.appendLine('election_reward_events.jsonl', '{"x":1}');

      final append = calls.lastWhere((c) => c.method == 'appendLine');
      expect(append.arguments, {
        'name': 'election_reward_events.jsonl',
        'line': '{"x":1}',
      });
    });

    test('ensureDirectory が false なら appendLine は例外にする', () async {
      responder = (call) => call.method == 'ensureDirectory' ? false : null;
      final store = AndroidSharedFileStore();

      await expectLater(
        store.appendLine('election_reward_events.jsonl', 'x'),
        throwsA(
          isA<SharedStorageException>()
              .having((e) => e.operation, 'operation', 'append'),
        ),
      );
      expect(calls.where((c) => c.method == 'appendLine'), isEmpty);
    });

    test('PlatformException は SharedStorageException へ包む', () async {
      responder = (call) {
        if (call.method == 'ensureDirectory') return true;
        throw PlatformException(code: 'append_failed', message: 'boom');
      };
      final store = AndroidSharedFileStore();

      await expectLater(
        store.appendLine('election_reward_events.jsonl', 'x'),
        throwsA(
          isA<SharedStorageException>()
              .having((e) => e.operation, 'operation', 'appendLine'),
        ),
      );
    });
  });

  group('FileElectionRewardEventExporter（共有ストア経由）', () {
    test('filePath が null なら契約ファイルへ追記する', () async {
      final fake = _FakeSharedFileStore();
      final exporter = FileElectionRewardEventExporter(
        store: fake,
        userId: 'abcd1234',
        clock: () => DateTime.utc(2026, 5, 6),
        eventIdGenerator: () => 'event-1',
      );

      await exporter.exportQuizCompleted(
        correctCount: 4,
        total: 5,
        passed: true,
      );

      expect(fake.lines, hasLength(1));
      expect(
        fake.lines.single,
        startsWith('election_reward_events.jsonl:'),
      );
      expect(fake.lines.single, contains('"event_type":"quiz_completed"'));
    });

    test('userId が空なら共有ストアへも書かない', () async {
      final fake = _FakeSharedFileStore();
      final exporter = FileElectionRewardEventExporter(store: fake);

      await exporter.exportElectionCompleted(
        wins: 1,
        won: true,
        voteShare: 50,
        scale: '天照村',
        electionId: 'e',
      );

      expect(fake.lines, isEmpty);
      expect(fake.written, isEmpty);
    });

    test('共有ストアの失敗は無音にせず上位へ伝え warn を1行残す', () async {
      final logs = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };
      addTearDown(() => debugPrint = original);

      final fake = _FakeSharedFileStore()..failOnAppend = true;
      final exporter = FileElectionRewardEventExporter(
        store: fake,
        userId: 'abcd1234',
      );

      await expectLater(
        exporter.exportElectionCompleted(
          wins: 1,
          won: true,
          voteShare: 50,
          scale: '天照村',
          electionId: 'e',
        ),
        throwsA(isA<SharedStorageException>()),
      );
      expect(logs.where((l) => l.startsWith('[WARN]')), hasLength(1));
    });
  });

  group('SharedFileStore', () {
    tearDown(SharedFileStore.reset);

    test('configure 前は未設定・configure 後は設定済み', () {
      SharedFileStore.reset();
      expect(SharedFileStore.isConfigured, isFalse);
      SharedFileStore.configure(FileSharedFileStore(Directory.systemTemp));
      expect(SharedFileStore.isConfigured, isTrue);
      expect(SharedFileStore.instance, isA<FileSharedFileStore>());
    });

    test('configureFallback は未設定時のみ実体を差し替える', () {
      SharedFileStore.reset();
      final fallback = FileSharedFileStore(
          Directory('${Directory.systemTemp.path}/fallback'));
      SharedFileStore.configureFallback(fallback);
      expect(SharedFileStore.instance, same(fallback));

      final explicit = FileSharedFileStore(
          Directory('${Directory.systemTemp.path}/explicit'));
      SharedFileStore.configure(explicit);
      SharedFileStore.configureFallback(fallback);
      expect(SharedFileStore.instance, same(explicit));
    });
  });
}

/// Android 側ブリッジのチャネル名（Dart 実装と一致すること）。
const String comShorieElectionSharedChannel =
    'com.shorie.election/shared_storage';
