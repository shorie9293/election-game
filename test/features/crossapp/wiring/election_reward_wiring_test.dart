import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/features/crossapp/data/crossapp_link_code_repository.dart';
import 'package:election_game/features/crossapp/data/election_reward_event_exporter.dart';
import 'package:election_game/screens/game_screen.dart';
import 'package:election_game/services/bgm_service.dart';
import 'package:election_game/services/sfx_service.dart';

/// 選挙確定経路（投票 / 棄権）から報酬イベントが書き出されることの試練。
void main() {
  late Directory tempDir;
  late String filePath;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'election_game_tutorial_completed': true,
    });
    tempDir = await Directory.systemTemp.createTemp('election_wiring');
    filePath = '${tempDir.path}/election_reward_events.jsonl';
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  List<Map<String, dynamic>> readEvents() {
    final file = File(filePath);
    if (!file.existsSync()) return const [];
    return file
        .readAsLinesSync()
        .where((line) => line.trim().isNotEmpty)
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
  }

  /// 実ファイルI/Oは fake async の外で走るため、pump と runAsync を交互に回して
  /// 書き出しの完了を待つ（pump が継続を流し、runAsync が実I/Oを進める）。
  Future<List<Map<String, dynamic>>> waitForEvents(
    WidgetTester tester, {
    int expected = 1,
  }) async {
    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 10));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      final current = readEvents();
      if (current.length >= expected) return current;
    }
    return readEvents();
  }

  /// 書き出しが起きないことを確かめるための待機（実I/Oに猶予を与える）。
  Future<void> settleIo(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 10));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
    }
  }

  /// キャラメイク → 選挙告示 → 討論 → 投票確定 までを進める。
  Future<void> playThroughElection(
    WidgetTester tester, {
    required bool abstain,
  }) async {
    await tester.pumpAndSettle();

    // 1. キャラメイク
    await tester.enterText(find.byKey(AppKeys.citizenNameInput), 'タロウ');
    await tester.tap(find.byKey(AppKeys.citizenCreateButton));
    await tester.pumpAndSettle();

    // 2. ホーム → 選挙へ
    await tester.scrollUntilVisible(
      find.byKey(AppKeys.homeElectionButton),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(AppKeys.homeElectionButton));
    await tester.pumpAndSettle();

    // 3. 告示 → 討論
    await tester.tap(find.byKey(AppKeys.electionProceedButton));
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byKey(AppKeys.debateReactionSilent));
      await tester.pumpAndSettle();
    }
    await tester.tap(
      find
          .descendant(
            of: find.byKey(AppKeys.debateRatingStars('candidate_1')),
            matching: find.byIcon(Icons.star_border),
          )
          .at(2),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .descendant(
            of: find.byKey(AppKeys.debateRatingStars('candidate_2')),
            matching: find.byIcon(Icons.star_border),
          )
          .at(2),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AppKeys.debateRatingSubmit));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AppKeys.debateToVoteButton));
    await tester.pumpAndSettle();

    // 4. 投票（または棄権）を確定
    if (abstain) {
      await tester.tap(find.byKey(AppKeys.voteAbstainButton));
    } else {
      await tester.tap(find.text('山田太郎').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.voteConfirmButton));
    }
    await tester.pumpAndSettle();
    expect(find.byKey(AppKeys.resultTitle), findsOneWidget);
  }

  testWidgets('投票確定で election_completed が1行だけ書き出される', (tester) async {
    final exporter = FileElectionRewardEventExporter(
      filePath: filePath,
      userId: 'abcd1234',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          rewardEventExporter: exporter,
          bgmService: MockBgmService(),
          sfxService: MockSfxService(),
        ),
      ),
    );
    await playThroughElection(tester, abstain: false);

    final events = await waitForEvents(tester);
    expect(events, hasLength(1));

    final event = events.single;
    expect(event['event_type'], 'election_completed');
    expect(event['user_id'], 'abcd1234');
    expect(event['event_id'], isA<String>());
    expect((event['event_id'] as String).isNotEmpty, isTrue);
    expect(event['timestamp'], isA<String>());
    expect(DateTime.parse(event['timestamp'] as String).isUtc, isTrue);

    final metadata = event['metadata'] as Map<String, dynamic>;
    expect(metadata.keys.toSet(), {
      'wins',
      'won',
      'vote_share',
      'scale',
      'election_id',
    });
    expect(metadata['won'], isA<bool>());
    expect(metadata['wins'], isA<int>());
    // 初回選挙なので累計当選回数は当選なら1・落選なら0
    expect(metadata['wins'], (metadata['won'] as bool) ? 1 : 0);
    expect(metadata['vote_share'], isA<int>());
    expect(metadata['vote_share'] as int, inInclusiveRange(0, 100));
    expect(metadata['scale'], isA<String>());
    expect((metadata['election_id'] as String).isNotEmpty, isTrue);
  });

  testWidgets('棄権でも election_completed が1行書き出され won=false', (tester) async {
    final exporter = FileElectionRewardEventExporter(
      filePath: filePath,
      userId: 'abcd1234',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          rewardEventExporter: exporter,
          bgmService: MockBgmService(),
          sfxService: MockSfxService(),
        ),
      ),
    );
    await playThroughElection(tester, abstain: true);

    final events = await waitForEvents(tester);
    expect(events, hasLength(1));
    final metadata = events.single['metadata'] as Map<String, dynamic>;
    expect(metadata['won'], isFalse);
    expect(metadata['wins'], 0);
  });

  testWidgets('連携コードがあればその先頭8文字が user_id になる', (tester) async {
    // userId 未設定のエクスポータ + 連携コードのリポジトリ（=本番経路）
    final exporter = FileElectionRewardEventExporter(filePath: filePath);

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          rewardEventExporter: exporter,
          linkCodeRepository: InMemoryCrossAppLinkCodeRepository(
            'wxyz9876-1234-5678-90ab-cdef12345678',
          ),
          bgmService: MockBgmService(),
          sfxService: MockSfxService(),
        ),
      ),
    );
    await playThroughElection(tester, abstain: false);

    final events = await waitForEvents(tester);
    expect(events, hasLength(1));
    expect(events.single['user_id'], 'wxyz9876');
  });

  testWidgets('未連携なら書き出さない（ファイルも作らない）', (tester) async {
    final exporter = FileElectionRewardEventExporter(filePath: filePath);

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          rewardEventExporter: exporter,
          linkCodeRepository: InMemoryCrossAppLinkCodeRepository(),
          bgmService: MockBgmService(),
          sfxService: MockSfxService(),
        ),
      ),
    );
    await playThroughElection(tester, abstain: false);

    await settleIo(tester);
    expect(File(filePath).existsSync(), isFalse);
  });
}
