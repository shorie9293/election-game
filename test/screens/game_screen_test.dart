import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:election_game/screens/game_screen.dart';
import 'package:election_game/core/testing/app_keys.dart';

void main() {
  group('GameScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'election_game_tutorial_completed': true,
      });
    });
    testWidgets('起動時にキャラメイク画面が表示される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // CitizenCreateScreenのウィジェットが表示されていることを確認
      expect(find.byKey(AppKeys.citizenNameInput), findsOneWidget);
      expect(find.byKey(AppKeys.citizenJobSelector), findsOneWidget);
      expect(find.byKey(AppKeys.citizenCreateButton), findsOneWidget);
    });

    testWidgets('名前を入力→決定でホーム画面に遷移する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 名前を入力
      await tester.enterText(
        find.byKey(AppKeys.citizenNameInput),
        'テスト市民',
      );

      // 決定ボタンをタップ
      await tester.tap(find.byKey(AppKeys.citizenCreateButton));
      await tester.pumpAndSettle();

      // HomeScreenが表示されていることを確認
      expect(find.byKey(AppKeys.homeTitle), findsOneWidget);
    });

    testWidgets(
      'キャラメイク→ホーム→選挙告示→投票→結果→ホーム の最小ゲームサイクル',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: GameScreen()),
        );
        await tester.pumpAndSettle();

        // 1. キャラメイク: 名前入力して決定
        await tester.enterText(
          find.byKey(AppKeys.citizenNameInput),
          'タロウ',
        );
        await tester.tap(find.byKey(AppKeys.citizenCreateButton));
        await tester.pumpAndSettle();

        // 2. ホーム画面に遷移（remainingTurns=0 なので「選挙に行く」ボタン表示）
        expect(find.byKey(AppKeys.homeTitle), findsOneWidget);

        // 3. 「選挙に行く」ボタンまでスクロールしてタップ
        await tester.scrollUntilVisible(
          find.byKey(AppKeys.homeElectionButton),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.byKey(AppKeys.homeElectionButton));
        await tester.pumpAndSettle();
        expect(find.byKey(AppKeys.electionAnnounceTitle), findsOneWidget);

        // 4. 「投票へ進む」ボタンをタップ → 討論会画面
        await tester.tap(find.byKey(AppKeys.electionProceedButton));
        await tester.pumpAndSettle();
        expect(find.byKey(AppKeys.debateTitle), findsOneWidget);

        // 5. 討論会を進める（2候補者→4発言、反応ボタンで進行）
        for (int i = 0; i < 4; i++) {
          await tester.tap(find.byKey(AppKeys.debateReactionSilent));
          await tester.pumpAndSettle();
        }
        // 評価フェーズ: 各候補者を評価
        // 山田太郎 (candidate_1) の星を3に設定
        await tester.tap(find.descendant(
          of: find.byKey(AppKeys.debateRatingStars('candidate_1')),
          matching: find.byIcon(Icons.star_border),
        ).at(2));
        await tester.pumpAndSettle();
        // 佐藤花子 (candidate_2) の星を3に設定
        await tester.tap(find.descendant(
          of: find.byKey(AppKeys.debateRatingStars('candidate_2')),
          matching: find.byIcon(Icons.star_border),
        ).at(2));
        await tester.pumpAndSettle();
        // 評価を送信
        await tester.tap(find.byKey(AppKeys.debateRatingSubmit));
        await tester.pumpAndSettle();
        // 投票へ進むボタンをタップ → 投票画面
        await tester.tap(find.byKey(AppKeys.debateToVoteButton));
        await tester.pumpAndSettle();
        expect(find.byKey(AppKeys.voteTitle), findsOneWidget);

        // 6. 候補者を選択して投票確定
        final candidateList =
            find.byKey(AppKeys.voteCandidateList);
        expect(candidateList, findsOneWidget);
        // Tap the first candidate name in the list
        await tester.tap(find.text('山田太郎').first);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(AppKeys.voteConfirmButton));
        await tester.pumpAndSettle();

        // 6. 結果画面を確認
        expect(find.byKey(AppKeys.resultTitle), findsOneWidget);
        expect(find.byKey(AppKeys.resultContinueButton), findsOneWidget);

        // 7. 「街に戻る」→ ホーム画面に戻る（ボタンは画面外にあるためスクロール）
        await tester.scrollUntilVisible(
          find.byKey(AppKeys.resultContinueButton), 100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.byKey(AppKeys.resultContinueButton));
        await tester.pumpAndSettle();
        expect(find.byKey(AppKeys.homeTitle), findsOneWidget);
      },
    );

    testWidgets(
      '選挙後に行動選択ボタンが表示され、ターンが減る',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: GameScreen()),
        );
        await tester.pumpAndSettle();

        // キャラメイク
        await tester.enterText(
          find.byKey(AppKeys.citizenNameInput), 'ハナコ');
        await tester.tap(find.byKey(AppKeys.citizenCreateButton));
        await tester.pumpAndSettle();

        // 最初は remainingTurns=0 なので選挙ボタンがあるはず
        // 選挙に行く
        await tester.scrollUntilVisible(
          find.byKey(AppKeys.homeElectionButton), 100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.byKey(AppKeys.homeElectionButton));
        await tester.pumpAndSettle();

        // 告示→討論→評価→投票→結果
        await tester.tap(find.byKey(AppKeys.electionProceedButton));
        await tester.pumpAndSettle();
        for (int i = 0; i < 4; i++) {
          await tester.tap(find.byKey(AppKeys.debateReactionSilent));
          await tester.pumpAndSettle();
        }
        // 評価フェーズ
        await tester.tap(find.descendant(
          of: find.byKey(AppKeys.debateRatingStars('candidate_1')),
          matching: find.byIcon(Icons.star_border),
        ).at(2));
        await tester.pumpAndSettle();
        await tester.tap(find.descendant(
          of: find.byKey(AppKeys.debateRatingStars('candidate_2')),
          matching: find.byIcon(Icons.star_border),
        ).at(2));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(AppKeys.debateRatingSubmit));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(AppKeys.debateToVoteButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text('山田太郎').first);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(AppKeys.voteConfirmButton));
        await tester.pumpAndSettle();
        // 結果画面の「街に戻る」ボタンは画面外にあるためスクロール
        await tester.scrollUntilVisible(
          find.byKey(AppKeys.resultContinueButton), 100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.byKey(AppKeys.resultContinueButton));
        await tester.pumpAndSettle();

        // 選挙後: remainingTurns=10。行動選択ボタンが表示されるはず
        expect(find.byKey(AppKeys.homeActionTalkNpc), findsOneWidget);
        expect(find.byKey(AppKeys.homeActionGatherInfo), findsOneWidget);
        expect(find.byKey(AppKeys.homeActionRest), findsOneWidget);
        // 選挙に行くボタンは非表示（remainingTurns > 0）
        expect(find.byKey(AppKeys.homeElectionButton), findsNothing);

        // 行動選択を5回タップ → remainingTurns=5
        for (int i = 0; i < 5; i++) {
          await tester.scrollUntilVisible(
            find.byKey(AppKeys.homeActionRest), 100,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.tap(find.byKey(AppKeys.homeActionRest));
          await tester.pumpAndSettle();

          // 選択肢イベントが発生した場合、ダイアログを閉じる
          if (find.byKey(AppKeys.homeChoiceDialog).evaluate().isNotEmpty) {
            final choiceButtons = find.descendant(
              of: find.byKey(AppKeys.homeChoiceDialog),
              matching: find.byType(TextButton),
            );
            if (choiceButtons.evaluate().isNotEmpty) {
              await tester.tap(choiceButtons.first);
              await tester.pumpAndSettle();
            }
          }
        }
        // remainingTurns=5 がカウントダウンカードに表示されている
        expect(
          find.descendant(
            of: find.byKey(AppKeys.homeCountdown),
            matching: find.text('5'),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
