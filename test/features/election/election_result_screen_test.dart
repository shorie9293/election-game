import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:election_game/features/election/presentation/election_result_screen.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/concern_evolution.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/services/election_service.dart';
import 'package:election_game/core/testing/app_keys.dart';

void main() {
  group('ElectionResultScreen', () {
    testWidgets('選挙結果画面が表示される', (tester) async {
      final election = ElectionService.computeElectionResult(Election.sample());
      await tester.pumpWidget(
        MaterialApp(
          home: ElectionResultScreen(
            result: election,
            lifeParamChanges: {'employment': 10, 'lifeCost': -5},
          ),
        ),
      );

      expect(find.byKey(const Key('result_title')), findsOneWidget);
      expect(find.byKey(const Key('result_winner')), findsOneWidget);
      expect(find.byKey(const Key('result_life_impact')), findsOneWidget);
      expect(find.byKey(const Key('result_continue_button')), findsOneWidget);
    });

    testWidgets('当選者名が表示される', (tester) async {
      final election = ElectionService.computeElectionResult(Election.sample());
      final winner = election.candidates.firstWhere(
        (c) => c.id == election.winnerId,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ElectionResultScreen(
            result: election,
            lifeParamChanges: {},
          ),
        ),
      );

      expect(find.textContaining(winner.name), findsWidgets);
    });

    testWidgets('関心事成長がある場合、成長セクションが表示される', (tester) async {
      final election = ElectionService.computeElectionResult(Election.sample());
      final evolutions = [
        ConcernEvolution(
          concern: Concern.economy,
          acquiredAtElection: 1,
          reason: '鈴木一郎の当選により新たな関心が芽生えた',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: ElectionResultScreen(
            result: election,
            lifeParamChanges: {},
            concernEvolutions: evolutions,
          ),
        ),
      );

      expect(find.byKey(AppKeys.resultConcernGrowth), findsOneWidget);
      expect(find.text('政治的成長'), findsOneWidget);
    });

    testWidgets('関心事成長がない場合、成長セクションは表示されない', (tester) async {
      final election = ElectionService.computeElectionResult(Election.sample());

      await tester.pumpWidget(
        MaterialApp(
          home: ElectionResultScreen(
            result: election,
            lifeParamChanges: {},
            concernEvolutions: [],
          ),
        ),
      );

      expect(find.byKey(AppKeys.resultConcernGrowth), findsNothing);
    });
  });
}
