import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/election_archive.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/models/turnout_snapshot.dart';
import 'package:election_game/features/share/domain/election_share_card_service.dart';

ElectionArchiveEntry _entry({
  String id = 'e1',
  String title = '第1回村長選挙',
  int winner = 60,
  int total = 100,
  int runnerUp = 40,
  DateTime? occurredAt,
}) {
  return ElectionArchiveEntry(
    electionId: id,
    title: title,
    scale: ElectionScale.village,
    winnerId: 'w1',
    winnerName: '天照太郎',
    winnerVotes: winner,
    totalVotes: total,
    runnerUpVotes: runnerUp,
    occurredAt: occurredAt,
  );
}

TurnoutSnapshot _turnout() => TurnoutSnapshot(
      electionTitle: '第1回村長選挙',
      scale: ElectionScale.village,
      jobBreakdown: [
        JobTurnout(job: Job.farmer, eligible: 100, voted: 62),
      ],
    );

void main() {
  final generatedAt = DateTime(2026, 10, 16);

  group('ElectionShareCardService.build', () {
    test('エントリから各フィールドを写し、実施日を保つ', () {
      final d = ElectionShareCardService.build(
        entry: _entry(occurredAt: DateTime(2026, 1, 2)),
        generatedAt: generatedAt,
      );
      expect(d.electionId, 'e1');
      expect(d.title, '第1回村長選挙');
      expect(d.winnerName, '天照太郎');
      expect(d.scaleLabel, '村');
      expect(d.winnerVotes, 60);
      expect(d.totalVotes, 100);
      expect(d.runnerUpVotes, 40);
      expect(d.occurredAt, DateTime(2026, 1, 2));
      expect(d.generatedAt, generatedAt);
      expect(d.hasTurnout, isFalse);
    });

    test('turnout を渡すと投票率・関心ラベルが載る', () {
      final d = ElectionShareCardService.build(
        entry: _entry(),
        turnout: _turnout(),
        generatedAt: generatedAt,
      );
      expect(d.hasTurnout, isTrue);
      expect(d.turnoutPercentLabel, '62.0%');
      expect(d.turnoutLabel, '高い関心');
    });
  });

  group('ElectionShareCardService.latest', () {
    test('空リストは null', () {
      expect(
        ElectionShareCardService.latest(const [], generatedAt: generatedAt),
        isNull,
      );
    });

    test('末尾（最新）のエントリを採る', () {
      final d = ElectionShareCardService.latest(
        [
          _entry(id: 'e1', title: '第1回'),
          _entry(id: 'e2', title: '第2回'),
        ],
        generatedAt: generatedAt,
      );
      expect(d, isNotNull);
      expect(d!.electionId, 'e2');
      expect(d.title, '第2回');
    });

    test('turnoutsByElectionId が該当IDのときだけ合流する', () {
      final d = ElectionShareCardService.latest(
        [_entry(id: 'e2')],
        turnoutsByElectionId: {'e2': _turnout()},
        generatedAt: generatedAt,
      );
      expect(d!.hasTurnout, isTrue);

      final d2 = ElectionShareCardService.latest(
        [_entry(id: 'e9')],
        turnoutsByElectionId: {'e2': _turnout()},
        generatedAt: generatedAt,
      );
      expect(d2!.hasTurnout, isFalse);
    });
  });
}
