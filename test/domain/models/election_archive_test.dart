import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/domain/models/election_archive.dart';
import 'package:election_game/domain/models/election_scale.dart';

void main() {
  ElectionArchiveEntry entry({
    String electionId = 'e1',
    String title = '村長選挙',
    ElectionScale scale = ElectionScale.village,
    String winnerName = '太郎',
    int winnerVotes = 60,
    int totalVotes = 100,
    int runnerUpVotes = 40,
    DateTime? occurredAt,
  }) {
    return ElectionArchiveEntry(
      electionId: electionId,
      title: title,
      scale: scale,
      winnerId: 'w',
      winnerName: winnerName,
      winnerVotes: winnerVotes,
      totalVotes: totalVotes,
      runnerUpVotes: runnerUpVotes,
      occurredAt: occurredAt,
    );
  }

  group('ElectionArchiveEntry', () {
    test('winnerShare は得票率を返す', () {
      expect(entry().winnerShare, 0.6);
    });

    test('winnerShare は0除算で0.0にガードする', () {
      final e = entry(winnerVotes: 0, totalVotes: 0, runnerUpVotes: 0);
      expect(e.winnerShare, 0.0);
      expect(e.isLandslide, isFalse);
    });

    test('margin は当選票と2位票の差', () {
      expect(entry().margin, 20);
    });

    test('isLandslide は得票率60%以上でtrue', () {
      expect(entry(winnerVotes: 60, totalVotes: 100).isLandslide, isTrue);
      expect(entry(winnerVotes: 59, totalVotes: 100).isLandslide, isFalse);
    });

    test('scaleLabel は村/町/市の日本語ラベル', () {
      expect(entry(scale: ElectionScale.village).scaleLabel, '村');
      expect(entry(scale: ElectionScale.town).scaleLabel, '町');
      expect(entry(scale: ElectionScale.city).scaleLabel, '市');
    });

    test('値等価（== と hashCode）', () {
      final a = entry(occurredAt: DateTime(2026));
      final b = entry(occurredAt: DateTime(2026));
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('異なる値は非等価', () {
      expect(entry(), isNot(entry(electionId: 'e2')));
      expect(entry(), isNot(entry(winnerName: '次郎')));
      expect(entry(), isNot(entry(occurredAt: DateTime(2027))));
    });

    test('occurredAt は null 許容', () {
      final e = entry();
      expect(e.occurredAt, isNull);
    });
  });
}