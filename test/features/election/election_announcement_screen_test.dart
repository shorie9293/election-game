import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:election_game/features/election/presentation/election_announcement_screen.dart';
import 'package:election_game/domain/models/election.dart';

void main() {
  group('ElectionAnnouncementScreen', () {
    testWidgets('選挙告示画面が表示される', (tester) async {
      final election = Election.sample();
      await tester.pumpWidget(
        MaterialApp(
          home: ElectionAnnouncementScreen(election: election),
        ),
      );

      expect(find.byKey(const Key('election_announce_title')), findsOneWidget);
      expect(find.byKey(const Key('election_candidate_list')), findsOneWidget);
      expect(find.byKey(const Key('election_proceed_button')), findsOneWidget);
    });

    testWidgets('候補者名が表示される', (tester) async {
      final election = Election.sample();
      await tester.pumpWidget(
        MaterialApp(
          home: ElectionAnnouncementScreen(election: election),
        ),
      );

      // 候補者リストと候補者名が表示されていることを確認
      expect(find.byKey(const Key('election_candidate_list')), findsOneWidget);
      expect(find.text(election.candidates[0].name), findsOneWidget);
      expect(find.text(election.candidates[1].name), findsOneWidget);
    });
  });
}
