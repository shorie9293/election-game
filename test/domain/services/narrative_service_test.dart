import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/services/election_service.dart';
import 'package:election_game/domain/services/narrative_service.dart';

void main() {
  group('NarrativeService.generateNarrative', () {
    late Election election;
    late Election result;

    setUp(() {
      election = Election.sample();
      result = ElectionService.computeElectionResult(election);
    });

    test('当選者スピーチが生成される', () {
      final narrative = NarrativeService.generateNarrative(
        result, 'candidate_2', false,
      );

      expect(narrative.winnerSpeech, isNotNull);
      expect(narrative.winnerSpeech, isNotEmpty);
    });

    test('当選者スピーチに当選者名が含まれる', () {
      final winner = result.candidates.firstWhere(
        (c) => c.id == result.winnerId,
      );
      final narrative = NarrativeService.generateNarrative(
        result, 'candidate_2', false,
      );

      expect(narrative.winnerSpeech, contains(winner.name));
    });

    test('NPCの反応が1つ以上生成される', () {
      final narrative = NarrativeService.generateNarrative(
        result, 'candidate_2', false,
      );

      expect(narrative.npcReactions, isNotEmpty);
      expect(narrative.npcReactions.length, greaterThanOrEqualTo(1));
    });

    test('投票理由のサマリーが生成される', () {
      final narrative = NarrativeService.generateNarrative(
        result, 'candidate_2', false,
      );

      expect(narrative.reasoningSummary, isNotNull);
      expect(narrative.reasoningSummary, isNotEmpty);
    });

    test('自分の投票候補が当選した場合、サマリーに当選を示す情報が含まれる', () {
      // 当選者に投票したとしてナラティブ生成
      final winnerId = result.winnerId!;
      final narrative = NarrativeService.generateNarrative(
        result, winnerId, false,
      );

      // 当選したことが反映されている（勝利を示唆する文言）
      expect(
        narrative.reasoningSummary.contains('当選') ||
        narrative.reasoningSummary.contains('勝利') ||
        narrative.reasoningSummary.contains('選ばれ'),
        isTrue,
      );
    });

    test('自分の投票候補が落選した場合、サマリーに落選を示す情報が含まれる', () {
      // 当選者と異なる候補に投票
      final winnerId = result.winnerId!;
      final loserId = result.candidates
          .firstWhere((c) => c.id != winnerId)
          .id;
      final narrative = NarrativeService.generateNarrative(
        result, loserId, false,
      );

      // 落選に関する言及がある
      expect(
        narrative.reasoningSummary.contains('落選') ||
        narrative.reasoningSummary.contains('届か') ||
        narrative.reasoningSummary.contains('及ば'),
        isTrue,
      );
    });

    test('棄権した場合、サマリーに棄権を示す情報が含まれる', () {
      final narrative = NarrativeService.generateNarrative(
        result, null, true,
      );

      expect(narrative.reasoningSummary.contains('棄権'), isTrue);
    });

    test('大差勝利の場合のムードストーリーが生成される', () {
      final landslide = election.copyWith(
        winnerId: 'candidate_1',
        voteCounts: {'candidate_1': 80, 'candidate_2': 15, 'candidate_3': 5},
      );
      final narrative = NarrativeService.generateNarrative(
        landslide, 'candidate_1', false,
      );

      expect(narrative.moodStory, isNotNull);
      expect(narrative.moodStory, isNotEmpty);
      // 大差に関する言及がある
      expect(
        narrative.moodStory.contains('大差') ||
        narrative.moodStory.contains('圧勝') ||
        narrative.moodStory.contains('圧倒'),
        isTrue,
      );
    });

    test('接戦の場合のムードストーリーが生成される', () {
      final closeRace = election.copyWith(
        winnerId: 'candidate_1',
        voteCounts: {'candidate_1': 45, 'candidate_2': 40, 'candidate_3': 15},
      );
      final narrative = NarrativeService.generateNarrative(
        closeRace, 'candidate_1', false,
      );

      expect(narrative.moodStory, isNotNull);
      expect(narrative.moodStory, isNotEmpty);
      // 接戦に関する言及がある
      expect(
        narrative.moodStory.contains('接戦') ||
        narrative.moodStory.contains('僅差') ||
        narrative.moodStory.contains('競'),
        isTrue,
      );
    });

    test('得票数がナラティブに反映される', () {
      final specific = election.copyWith(
        winnerId: 'candidate_1',
        voteCounts: {'candidate_1': 60, 'candidate_2': 25, 'candidate_3': 15},
      );
      final narrative = NarrativeService.generateNarrative(
        specific, 'candidate_1', false,
      );

      // 得票数または割合に関する言及がある
      expect(
        narrative.reasoningSummary.contains('60') ||
        narrative.reasoningSummary.contains('票') ||
        narrative.reasoningSummary.contains('%'),
        isTrue,
      );
    });

    test('候補者の政策がナラティブに反映される', () {
      // 山田太郎（candidate_1）の政策に言及があることを確認
      final yamadaWin = election.copyWith(
        winnerId: 'candidate_1',
        voteCounts: {'candidate_1': 55, 'candidate_2': 30, 'candidate_3': 15},
      );
      final narrative = NarrativeService.generateNarrative(
        yamadaWin, 'candidate_1', false,
      );

      // 当選者の政策カテゴリ（経済）に言及
      final fullText = '${narrative.winnerSpeech} ${narrative.reasoningSummary}';
      expect(
        fullText.contains('経済') ||
        fullText.contains('開発') ||
        fullText.contains('減税'),
        isTrue,
      );
    });

    test('当選者が不在の場合は空のナラティブが返る', () {
      final noWinner = election.copyWith(
        winnerId: null,
        voteCounts: {
          'candidate_1': 33, 'candidate_2': 33, 'candidate_3': 34,
        },
      );
      final narrative = NarrativeService.generateNarrative(
        noWinner, null, false,
      );

      expect(narrative.winnerSpeech, isEmpty);
      expect(narrative.npcReactions, isEmpty);
    });
  });
}
