import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:election_game/features/election/presentation/debate_screen.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/models/candidate.dart';

void main() {
  group('DebateScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('討論会画面が表示される', (tester) async {
      final election = Election.sample();
      await tester.pumpWidget(
        MaterialApp(
          home: DebateScreen(
            election: election,
            onProceedToVote: () {},
          ),
        ),
      );

      expect(find.byKey(const Key('debate_title')), findsOneWidget);
    });

    testWidgets('候補者名と発言が表示される', (tester) async {
      final candidates = Candidate.samples().take(2).toList();
      final election = Election(
        id: 'test',
        title: 'テスト選挙',
        scale: ElectionScale.village,
        candidates: candidates,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: DebateScreen(
            election: election,
            onProceedToVote: () {},
          ),
        ),
      );

      expect(find.byKey(const Key('debate_candidate_name')), findsOneWidget);
      expect(find.byKey(const Key('debate_speech_bubble')), findsOneWidget);
    });

    testWidgets('反応ボタンが4つ表示される', (tester) async {
      final candidates = Candidate.samples().take(2).toList();
      final election = Election(
        id: 'test',
        title: 'テスト選挙',
        scale: ElectionScale.village,
        candidates: candidates,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: DebateScreen(
            election: election,
            onProceedToVote: () {},
          ),
        ),
      );

      expect(find.byKey(const Key('debate_reaction_agree')), findsOneWidget);
      expect(find.byKey(const Key('debate_reaction_disagree')), findsOneWidget);
      expect(find.byKey(const Key('debate_reaction_question')), findsOneWidget);
      expect(find.byKey(const Key('debate_reaction_silent')), findsOneWidget);
    });

    testWidgets('反応ボタンタップで次の発言に進む', (tester) async {
      final candidates = Candidate.samples().take(2).toList();
      final election = Election(
        id: 'test',
        title: 'テスト選挙',
        scale: ElectionScale.village,
        candidates: candidates,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: DebateScreen(
            election: election,
            onProceedToVote: () {},
          ),
        ),
      );

      // 反応ボタンが表示されている
      expect(find.byKey(const Key('debate_reaction_agree')), findsOneWidget);

      // 同意ボタンをタップ → 次の発言へ
      await tester.tap(find.byKey(const Key('debate_reaction_agree')));
      await tester.pumpAndSettle();

      // まだ反応ボタンが表示されている（次の発言）
      expect(find.byKey(const Key('debate_reaction_agree')), findsOneWidget);
    });

    testWidgets('全発言後に評価パネルが表示される', (tester) async {
      final candidates = Candidate.samples().take(2).toList();
      final election = Election(
        id: 'test',
        title: 'テスト選挙',
        scale: ElectionScale.village,
        candidates: candidates,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: DebateScreen(
            election: election,
            onProceedToVote: () {},
          ),
        ),
      );

      // 2候補者 → 4発言。全ての反応を選択
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.byKey(const Key('debate_reaction_silent')));
        await tester.pumpAndSettle();
      }

      // 評価パネルが表示される
      expect(find.byKey(const Key('debate_rating_panel')), findsOneWidget);
      // 評価送信ボタンがある（全候補評価前は無効）
      expect(find.byKey(const Key('debate_rating_submit')), findsOneWidget);
    });

    testWidgets('評価送信後に投票へボタンが表示される', (tester) async {
      final candidates = Candidate.samples().take(2).toList();
      final election = Election(
        id: 'test',
        title: 'テスト選挙',
        scale: ElectionScale.village,
        candidates: candidates,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: DebateScreen(
            election: election,
            onProceedToVote: () {},
          ),
        ),
      );

      // 4発言を進める
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.byKey(const Key('debate_reaction_agree')));
        await tester.pumpAndSettle();
      }

      // 評価パネルが表示されている
      expect(find.byKey(const Key('debate_rating_panel')), findsOneWidget);

      // 各候補者の星をタップ（最初の星=評価1）
      final starKeys = [
        find.byKey(const Key('debate_rating_stars_candidate_1')),
        find.byKey(const Key('debate_rating_stars_candidate_2')),
      ];
      for (final starKey in starKeys) {
        // 最初の子（星1）をタップ
        final starRow = tester.widget<Row>(starKey);
        expect(starRow.children.length, 5);
        // 3番目の星をタップして評価3にする
        await tester.tap(find.descendant(
          of: starKey,
          matching: find.byIcon(Icons.star_border),
        ).at(2));
        await tester.pumpAndSettle();
      }

      // 評価送信ボタンをタップ
      await tester.tap(find.byKey(const Key('debate_rating_submit')));
      await tester.pumpAndSettle();

      // 投票へ進むボタンが表示される
      expect(find.byKey(const Key('debate_to_vote_button')), findsOneWidget);
    });

    testWidgets('投票へボタンでonProceedToVoteが呼ばれる', (tester) async {
      final candidates = Candidate.samples().take(2).toList();
      final election = Election(
        id: 'test',
        title: 'テスト選挙',
        scale: ElectionScale.village,
        candidates: candidates,
      );
      bool proceeded = false;
      await tester.pumpWidget(
        MaterialApp(
          home: DebateScreen(
            election: election,
            onProceedToVote: () {
              proceeded = true;
            },
          ),
        ),
      );

      // 4発言を進める
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.byKey(const Key('debate_reaction_silent')));
        await tester.pumpAndSettle();
      }

      // 各候補を星3で評価
      final starKeys = [
        find.byKey(const Key('debate_rating_stars_candidate_1')),
        find.byKey(const Key('debate_rating_stars_candidate_2')),
      ];
      for (final starKey in starKeys) {
        await tester.tap(find.descendant(
          of: starKey,
          matching: find.byIcon(Icons.star_border),
        ).at(2));
        await tester.pumpAndSettle();
      }

      // 評価送信
      await tester.tap(find.byKey(const Key('debate_rating_submit')));
      await tester.pumpAndSettle();

      // 投票へボタンをタップ
      await tester.tap(find.byKey(const Key('debate_to_vote_button')));
      await tester.pumpAndSettle();

      expect(proceeded, isTrue);
    });

    testWidgets('異なる反応を選択できる（agree/disagree/question/silent）', (tester) async {
      final candidates = Candidate.samples().take(2).toList();
      final election = Election(
        id: 'test',
        title: 'テスト選挙',
        scale: ElectionScale.village,
        candidates: candidates,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: DebateScreen(
            election: election,
            onProceedToVote: () {},
          ),
        ),
      );

      // agree
      await tester.tap(find.byKey(const Key('debate_reaction_agree')));
      await tester.pumpAndSettle();
      // disagree
      await tester.tap(find.byKey(const Key('debate_reaction_disagree')));
      await tester.pumpAndSettle();
      // question
      await tester.tap(find.byKey(const Key('debate_reaction_question')));
      await tester.pumpAndSettle();
      // silent
      await tester.tap(find.byKey(const Key('debate_reaction_silent')));
      await tester.pumpAndSettle();

      // 全4発言終了 → 評価パネルが表示
      expect(find.byKey(const Key('debate_rating_panel')), findsOneWidget);
    });

    testWidgets('評価パネルで星をタップすると星が変わる', (tester) async {
      final candidates = Candidate.samples().take(2).toList();
      final election = Election(
        id: 'test',
        title: 'テスト選挙',
        scale: ElectionScale.village,
        candidates: candidates,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: DebateScreen(
            election: election,
            onProceedToVote: () {},
          ),
        ),
      );

      // 全発言を進める
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.byKey(const Key('debate_reaction_silent')));
        await tester.pumpAndSettle();
      }

      final starKey = find.byKey(const Key('debate_rating_stars_candidate_1'));

      // 最初は星が埋まっていない（評価0）
      expect(find.descendant(of: starKey, matching: find.byIcon(Icons.star)),
          findsNothing);

      // 3番目の星をタップ
      await tester.tap(find.descendant(
        of: starKey,
        matching: find.byIcon(Icons.star_border),
      ).at(2));
      await tester.pumpAndSettle();

      // 星1, 2, 3が埋まる
      expect(find.descendant(of: starKey, matching: find.byIcon(Icons.star)),
          findsNWidgets(3));
      // 星4, 5は枠のまま
      expect(find.descendant(of: starKey, matching: find.byIcon(Icons.star_border)),
          findsNWidgets(2));
    });
  });
}
