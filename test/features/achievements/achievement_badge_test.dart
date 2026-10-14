import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/models/quiz_result.dart';
import 'package:election_game/features/achievements/domain/achievement_badge.dart';
import 'package:election_game/features/achievements/domain/achievement_badge_service.dart';

/// 完了済み選挙を生成する補助（id の millis をローカル日付から決める）。
Election _election({
  required DateTime local,
  String? winnerId,
  String? voterId,
}) {
  final millis = local.toUtc().millisecondsSinceEpoch;
  return Election(
    id: 'election_$millis',
    title: 'テスト選挙',
    scale: ElectionScale.town,
    candidates: const [],
    winnerId: winnerId,
    voteCounts: winnerId == null ? null : const {'a': 1},
    voterId: voterId,
  );
}

AchievementSignals _signals({
  int electionCount = 0,
  ElectionScale scale = ElectionScale.village,
  List<Election> pastElections = const [],
  QuizBestScore? quizBest,
}) {
  return AchievementSignals(
    electionCount: electionCount,
    scale: scale,
    pastElections: pastElections,
    quizBest: quizBest,
  );
}

void main() {
  group('AchievementBadgeDefinition', () {
    test('定義は14件・ID一意・必須数は正', () {
      final defs = AchievementBadgeService.definitions;
      expect(defs.length, 14);
      expect(defs.map((d) => d.id).toSet().length, defs.length);
      for (final d in defs) {
        expect(d.requiredCount, greaterThan(0));
        expect(d.name.isNotEmpty, isTrue);
        expect(d.description.isNotEmpty, isTrue);
      }
    });

    test('定義は tier 昇順（ブロンズ→シルバー→ゴールド→伝説）に並ぶ', () {
      final tiers =
          AchievementBadgeService.definitions.map((d) => d.tier.index).toList();
      final sorted = [...tiers]..sort();
      expect(tiers, sorted);
    });

    test('id が空なら ArgumentError', () {
      expect(
        () => AchievementBadgeDefinition(
          id: '',
          name: '名',
          description: '説明',
          tier: BadgeTier.bronze,
          requiredCount: 1,
          metric: AchievementMetric.electionCount,
        ),
        throwsArgumentError,
      );
    });

    test('requiredCount が 0 以下なら ArgumentError', () {
      expect(
        () => AchievementBadgeDefinition(
          id: 'x',
          name: '名',
          description: '説明',
          tier: BadgeTier.bronze,
          requiredCount: 0,
          metric: AchievementMetric.electionCount,
        ),
        throwsArgumentError,
      );
    });

    test('tier は日本語ラベルと絵文字を持つ', () {
      expect(BadgeTier.bronze.label, 'ブロンズ');
      expect(BadgeTier.silver.label, 'シルバー');
      expect(BadgeTier.gold.label, 'ゴールド');
      expect(BadgeTier.legend.label, '伝説');
      for (final t in BadgeTier.values) {
        expect(t.emoji.isNotEmpty, isTrue);
      }
    });
  });

  group('AchievementSignals の値算出', () {
    test('electionCount はそのまま', () {
      expect(
        _signals(electionCount: 4).valueOf(AchievementMetric.electionCount),
        4,
      );
    });

    test('reachedTown / reachedCity は段階到達を 0/1 で表す', () {
      expect(
        _signals(scale: ElectionScale.village)
            .valueOf(AchievementMetric.reachedTown),
        0,
      );
      expect(
        _signals(scale: ElectionScale.town)
            .valueOf(AchievementMetric.reachedTown),
        1,
      );
      expect(
        _signals(scale: ElectionScale.town)
            .valueOf(AchievementMetric.reachedCity),
        0,
      );
      expect(
        _signals(scale: ElectionScale.city)
            .valueOf(AchievementMetric.reachedCity),
        1,
      );
    });

    test('votedWinner は「投票した候補が当選した」回数のみ数える', () {
      final s = _signals(
        pastElections: [
          // 的中
          _election(
            local: DateTime(2026, 10, 11, 9),
            winnerId: 'cand_a',
            voterId: 'cand_a',
          ),
          // 非的中
          _election(
            local: DateTime(2026, 10, 11, 12),
            winnerId: 'cand_a',
            voterId: 'cand_b',
          ),
          // 棄権（voterId なし）
          _election(
            local: DateTime(2026, 10, 12, 9),
            winnerId: 'cand_a',
          ),
          // 未完了（winnerId なし）
          _election(local: DateTime(2026, 10, 12, 10)),
        ],
      );
      expect(s.valueOf(AchievementMetric.votedWinner), 1);
    });

    test('playDays は選挙を実施したローカル日数の重複を除いた数', () {
      final s = _signals(
        pastElections: [
          _election(local: DateTime(2026, 10, 11, 9), winnerId: 'a'),
          _election(local: DateTime(2026, 10, 11, 18), winnerId: 'a'),
          _election(local: DateTime(2026, 10, 12, 9), winnerId: 'a'),
        ],
      );
      expect(s.valueOf(AchievementMetric.playDays), 2);
    });

    test('クイズ系: bestCorrect / attempts / perfect', () {
      final none = _signals();
      expect(none.valueOf(AchievementMetric.quizBestCorrect), 0);
      expect(none.valueOf(AchievementMetric.quizAttempts), 0);
      expect(none.valueOf(AchievementMetric.quizPerfect), 0);

      final full = _signals(
        quizBest: const QuizBestScore(correctCount: 5, total: 5, attempts: 3),
      );
      expect(full.valueOf(AchievementMetric.quizBestCorrect), 5);
      expect(full.valueOf(AchievementMetric.quizAttempts), 3);
      expect(full.valueOf(AchievementMetric.quizPerfect), 1);

      final partial = _signals(
        quizBest: const QuizBestScore(correctCount: 4, total: 5, attempts: 1),
      );
      expect(partial.valueOf(AchievementMetric.quizPerfect), 0);

      // 出題数0（記録なし相当）は達成扱いにしない
      final empty = _signals(
        quizBest: const QuizBestScore(correctCount: 0, total: 0),
      );
      expect(empty.valueOf(AchievementMetric.quizPerfect), 0);
    });

    test('pastElections が空でも list は空・例外なし', () {
      final s = _signals();
      final collection = AchievementBadgeService.collect(s);
      expect(collection.progresses.length, 14);
      expect(collection.earnedCount, 0);
      expect(collection.summaryLabel, '獲得 0 / 14');
    });
  });

  group('AchievementBadgeProgress', () {
    AchievementBadgeDefinition def(int required) => AchievementBadgeDefinition(
          id: 'd',
          name: '名',
          description: '説明',
          tier: BadgeTier.bronze,
          requiredCount: required,
          metric: AchievementMetric.electionCount,
        );

    test('ratio はクランプされ percent・remaining が定まる', () {
      final p = AchievementBadgeProgress(definition: def(5), current: 3);
      expect(p.ratio, closeTo(0.6, 1e-9));
      expect(p.percent, 60);
      expect(p.remaining, 2);
      expect(p.isComplete, isFalse);
      expect(p.progressLabel, '3 / 5');
    });

    test('達成時は remaining 0・ratio 1・表示は required を超えない', () {
      final p = AchievementBadgeProgress(definition: def(3), current: 10);
      expect(p.isComplete, isTrue);
      expect(p.remaining, 0);
      expect(p.ratio, 1.0);
      expect(p.progressLabel, '3 / 3');
    });

    test('負の現在値は 0 として扱い、例外にしない', () {
      final p = AchievementBadgeProgress(definition: def(3), current: -2);
      expect(p.ratio, 0.0);
      expect(p.progressLabel, '0 / 3');
    });
  });

  group('AchievementBadgeService.collect', () {
    test('シグナルに応じて獲得数と tier 内訳が定まる', () {
      final s = _signals(
        electionCount: 3,
        scale: ElectionScale.town,
        pastElections: [
          _election(
            local: DateTime(2026, 10, 11, 9),
            winnerId: 'a',
            voterId: 'a',
          ),
        ],
        quizBest: const QuizBestScore(correctCount: 3, total: 5, attempts: 1),
      );
      final c = AchievementBadgeService.collect(s);

      // bronze: first_election(1) / vote_hit_1(1) / quiz_first(1) / quiz_correct_3(3) 全達成
      expect(c.byTier(BadgeTier.bronze).where((p) => p.isEarned).length, 4);
      // silver: election_3(3) / town_reached(1) 達成・vote_hit_3(3)・play_day_3(3) は未達
      expect(c.byTier(BadgeTier.silver).where((p) => p.isEarned).length, 2);
      expect(c.byTier(BadgeTier.gold).where((p) => p.isEarned).length, 0);
      expect(c.byTier(BadgeTier.legend).where((p) => p.isEarned).length, 0);

      expect(c.earnedCount, 6);
      expect(c.totalCount, 14);
      expect(c.summaryLabel, '獲得 6 / 14');
      expect(c.completionRatio, closeTo(6 / 14, 1e-9));
      expect(c.unearned.length, 8);
    });

    test('1つの指標が複数定義を同時に満たす（electionCount=10 で 4 件）', () {
      final c = AchievementBadgeService.collect(_signals(electionCount: 10));
      final progressed = c.progresses
          .where((p) => p.definition.metric == AchievementMetric.electionCount)
          .toList();
      expect(progressed.length, 4);
      expect(progressed.every((p) => p.isEarned), isTrue);
    });

    test('全達成なら summaryLabel は獲得 14 / 14', () {
      final c = AchievementBadgeService.collect(_signals(
        electionCount: 10,
        scale: ElectionScale.city,
        pastElections: [
          _election(
            local: DateTime(2026, 10, 11, 9),
            winnerId: 'a',
            voterId: 'a',
          ),
          _election(
            local: DateTime(2026, 10, 12, 9),
            winnerId: 'a',
            voterId: 'a',
          ),
          _election(
            local: DateTime(2026, 10, 13, 9),
            winnerId: 'a',
            voterId: 'a',
          ),
        ],
        quizBest: const QuizBestScore(correctCount: 5, total: 5, attempts: 5),
      ));
      expect(c.earnedCount, 14);
      expect(c.summaryLabel, '獲得 14 / 14');
    });

    test('build は登録順（tier昇順→宣言順）を保つ', () {
      final built = AchievementBadgeService.build(_signals());
      expect(
        built.map((p) => p.definition.id).toList(),
        AchievementBadgeService.definitions.map((d) => d.id).toList(),
      );
    });
  });
}
