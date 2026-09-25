import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/domain/services/election_service.dart';
import 'package:election_game/features/election/presentation/election_result_screen.dart';

void main() {
  group('ElectionResultScreen 投票率カード', () {
    final completed =
        ElectionService.computeElectionResult(Election.sample());

    testWidgets('society を渡すと投票率カードが表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ElectionResultScreen(
            result: completed,
            lifeParamChanges: const {},
            society: SocietyState.initial(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(AppKeys.turnoutResultCard), findsOneWidget);
      expect(find.textContaining('投票率'), findsWidgets);
    });

    testWidgets('society を渡さなければ投票率カードは出ない（後方互換）', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ElectionResultScreen(
            result: completed,
            lifeParamChanges: const {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(AppKeys.turnoutResultCard), findsNothing);
    });

    testWidgets('未完了の選挙でも society があればカードは出て例外を投げない', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ElectionResultScreen(
            result: Election.sample(),
            lifeParamChanges: const {},
            society: SocietyState.initial(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(AppKeys.turnoutResultCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
