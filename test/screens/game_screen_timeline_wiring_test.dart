import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/repositories/support_timeline_repository.dart';
import 'package:election_game/screens/game_screen.dart';

void main() {
  group('GameScreen × 世論の推移', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'election_game_tutorial_completed': true,
      });
    });

    testWidgets('投票→結果確定で世論タイムラインに1件自動記録される', (tester) async {
      final repo = InMemorySupportTimelineRepository();

      await tester.pumpWidget(
        MaterialApp(home: GameScreen(supportTimelineRepository: repo)),
      );
      await tester.pumpAndSettle();

      // キャラメイク
      await tester.enterText(find.byKey(AppKeys.citizenNameInput), 'タロウ');
      await tester.tap(find.byKey(AppKeys.citizenCreateButton));
      await tester.pumpAndSettle();

      // ホーム → 選挙告示
      await tester.scrollUntilVisible(
        find.byKey(AppKeys.homeElectionButton),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(AppKeys.homeElectionButton));
      await tester.pumpAndSettle();
      expect(find.byKey(AppKeys.electionAnnounceTitle), findsOneWidget);

      // 告示 → 討論会
      await tester.tap(find.byKey(AppKeys.electionProceedButton));
      await tester.pumpAndSettle();
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.byKey(AppKeys.debateReactionSilent));
        await tester.pumpAndSettle();
      }

      // 評価フェーズ
      await tester.tap(find
          .descendant(
            of: find.byKey(AppKeys.debateRatingStars('candidate_1')),
            matching: find.byIcon(Icons.star_border),
          )
          .at(2));
      await tester.pumpAndSettle();
      await tester.tap(find
          .descendant(
            of: find.byKey(AppKeys.debateRatingStars('candidate_2')),
            matching: find.byIcon(Icons.star_border),
          )
          .at(2));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.debateRatingSubmit));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.debateToVoteButton));
      await tester.pumpAndSettle();

      // 投票確定 → 結果画面
      expect(find.byKey(AppKeys.voteTitle), findsOneWidget);
      expect(repo.store, isEmpty);

      await tester.tap(find.text('山田太郎').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.voteConfirmButton));
      await tester.pumpAndSettle();
      expect(find.byKey(AppKeys.resultTitle), findsOneWidget);

      // 自動記録は投げっぱなしなので、マイクロタスク消化のためもう一度 pump
      await tester.pump();

      expect(repo.store, hasLength(1));
      expect(repo.store.single.leaderCandidateName, isNotEmpty);
      expect(repo.store.single.leaderCandidateId, isNotEmpty);
      expect(repo.store.single.electionTitle, isNotEmpty);
    });
  });
}
