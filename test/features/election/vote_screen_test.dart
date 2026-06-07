import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:election_game/features/election/presentation/vote_screen.dart';
import 'package:election_game/domain/models/election.dart';

void main() {
  group('VoteScreen', () {
    testWidgets('投票画面が表示される', (tester) async {
      final election = Election.sample();
      await tester.pumpWidget(
        MaterialApp(
          home: VoteScreen(election: election),
        ),
      );

      expect(find.byKey(const Key('vote_title')), findsOneWidget);
      expect(find.byKey(const Key('vote_candidate_list')), findsOneWidget);
      expect(find.byKey(const Key('vote_abstain_button')), findsOneWidget);
    });

    testWidgets('候補者を選択して投票できる', (tester) async {
      final election = Election.sample();
      String? votedCandidateId;

      await tester.pumpWidget(
        MaterialApp(
          home: VoteScreen(
            election: election,
            onVoteCast: (candidateId) {
              votedCandidateId = candidateId;
            },
          ),
        ),
      );

      // 最初の候補者をタップ
      await tester.tap(find.text(election.candidates[0].name).first);
      await tester.pumpAndSettle();

      // 投票確定ボタンをタップ
      await tester.tap(find.byKey(const Key('vote_confirm_button')));
      await tester.pumpAndSettle();

      expect(votedCandidateId, election.candidates[0].id);
    });

    testWidgets('棄権できる', (tester) async {
      final election = Election.sample();
      bool abstained = false;

      await tester.pumpWidget(
        MaterialApp(
          home: VoteScreen(
            election: election,
            onAbstain: () {
              abstained = true;
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('vote_abstain_button')));
      await tester.pumpAndSettle();

      expect(abstained, true);
    });
  });
}
