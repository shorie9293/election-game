import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/features/crossapp/data/election_reward_event_exporter.dart';

void main() {
  late Directory tempDir;
  late String filePath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('election_reward_export');
    filePath = '${tempDir.path}/nested/dir/election_reward_events.jsonl';
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  List<Map<String, dynamic>> readLines() {
    final file = File(filePath);
    if (!file.existsSync()) return const [];
    return file
        .readAsLinesSync()
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
  }

  test('既定の出力先は凍結契約 v1 のパス', () {
    final exporter = FileElectionRewardEventExporter(userId: 'abcd1234');
    expect(
      exporter.filePath,
      '/data/local/tmp/takamagahara_shared/election_reward_events.jsonl',
    );
  });

  test('userId は setter/getter で差し替えられる（既定は空）', () {
    final exporter = FileElectionRewardEventExporter(filePath: filePath);
    expect(exporter.userId, '');
    exporter.userId = 'abcd1234';
    expect(exporter.userId, 'abcd1234');
  });

  test('election_completed を実バイトで1行書き出す', () async {
    final exporter = FileElectionRewardEventExporter(
      filePath: filePath,
      userId: 'abcd1234',
      clock: () => DateTime.utc(2026, 5, 6, 7, 8, 9),
      eventIdGenerator: () => 'event-1',
    );

    await exporter.exportElectionCompleted(
      wins: 3,
      won: true,
      voteShare: 61,
      scale: '天照町',
      electionId: 'election_9',
    );

    // 親ディレクトリは recursive に作られる
    expect(File(filePath).existsSync(), isTrue);
    final lines = readLines();
    expect(lines, hasLength(1));
    expect(lines.single, {
      'event_id': 'event-1',
      'event_type': 'election_completed',
      'user_id': 'abcd1234',
      'timestamp': '2026-05-06T07:08:09.000Z',
      'metadata': {
        'wins': 3,
        'won': true,
        'vote_share': 61,
        'scale': '天照町',
        'election_id': 'election_9',
      },
    });
  });

  test('quiz_completed を実バイトで1行書き出す', () async {
    final exporter = FileElectionRewardEventExporter(
      filePath: filePath,
      userId: 'abcd1234',
      clock: () => DateTime.utc(2026, 5, 6),
      eventIdGenerator: () => 'event-q',
    );

    await exporter.exportQuizCompleted(
      correctCount: 4,
      total: 5,
      passed: true,
    );

    final lines = readLines();
    expect(lines, hasLength(1));
    expect(lines.single['event_type'], 'quiz_completed');
    expect(lines.single['metadata'], {
      'correct_count': 4,
      'total': 5,
      'passed': true,
    });
  });

  test('追記専用：2回書き出すと2行になる（1イベント1行）', () async {
    final exporter = FileElectionRewardEventExporter(
      filePath: filePath,
      userId: 'abcd1234',
    );

    await exporter.exportQuizCompleted(
        correctCount: 1, total: 2, passed: false);
    await exporter.exportQuizCompleted(correctCount: 2, total: 2, passed: true);

    final raw = File(filePath).readAsStringSync();
    expect('\n'.allMatches(raw).length, 2);
    expect(readLines(), hasLength(2));
  });

  test('userId が空なら書き出さない（ファイルも作らない）', () async {
    final exporter = FileElectionRewardEventExporter(filePath: filePath);

    await exporter.exportElectionCompleted(
      wins: 1,
      won: false,
      voteShare: 0,
      scale: '天照村',
      electionId: 'e',
    );
    await exporter.exportQuizCompleted(
        correctCount: 0, total: 1, passed: false);

    expect(File(filePath).existsSync(), isFalse);
  });

  test('userId が空白のみでも書き出さない', () async {
    final exporter = FileElectionRewardEventExporter(
      filePath: filePath,
      userId: '   ',
    );

    await exporter.exportQuizCompleted(correctCount: 1, total: 1, passed: true);

    expect(File(filePath).existsSync(), isFalse);
  });

  test('書き込み失敗でも例外を投げない（best-effort）', () async {
    // 親ディレクトリの位置に通常ファイルを置き、create を失敗させる
    final blocker = File('${tempDir.path}/blocker');
    blocker.writeAsStringSync('not a directory');
    final exporter = FileElectionRewardEventExporter(
      filePath: '${blocker.path}/election_reward_events.jsonl',
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
      completes,
    );
    await expectLater(
      exporter.exportQuizCompleted(correctCount: 1, total: 1, passed: true),
      completes,
    );
  });
}
