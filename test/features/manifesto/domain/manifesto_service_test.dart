import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/manifesto.dart';
import 'package:election_game/domain/services/manifesto_service.dart';
import 'package:flutter_test/flutter_test.dart';

Candidate _winner() => const Candidate(
      id: 'candidate_1',
      name: '山田太郎',
      portraitKey: 'p',
      faction: '発展の会',
      personality: '経済成長',
      policies: [
        Policy(
          title: '大規模開発',
          description: 'd',
          category: '経済',
          effects: {'employment': 10, 'environment': -5},
        ),
        Policy(
          title: '減税',
          description: 'd',
          category: '経済',
          effects: {'lifeCost': -10},
        ),
        Policy(
          title: '追加雇用',
          description: 'd',
          category: '経済',
          effects: {'employment': 3, 'safety': 2},
        ),
        Policy(
          title: ' secret tech',
          description: 'd',
          category: '未来',
          effects: {'zzCustom': 1, 'aaCustom': 2},
        ),
      ],
    );

Election _election({String? winnerId, Map<String, int>? voteCounts}) {
  final base = Election.sample();
  return base.copyWith(
    winnerId: winnerId,
    voteCounts: voteCounts,
    clearWinner: winnerId == null,
  );
}

void main() {
  group('ManifestoService.pledgesFor', () {
    test('key順序は LifeParamKeys.all 順 → 未知keyは昇順', () {
      final pledges = ManifestoService.pledgesFor(
        _winner(),
        const {'employment': 0},
        const {'employment': 5},
      );
      expect(pledges.map((e) => e.lifeParamKey).toList(), [
        'lifeCost',
        'employment',
        'environment',
        'safety',
        'aaCustom',
        'zzCustom',
      ]);
    });

    test('複数公約が同一keyに触れたら promised は合算・titlesは重複除去', () {
      final pledges = ManifestoService.pledgesFor(
        _winner(),
        const {'employment': 0},
        const {'employment': 5},
      );
      final employment = pledges.firstWhere((p) => p.lifeParamKey == 'employment');
      expect(employment.promisedDelta, 13); // 10 + 3
      expect(employment.policyTitles, ['大規模開発', '追加雇用']);
    });

    test('actualDelta は after - before（欠損keyは0扱い）', () {
      final pledges = ManifestoService.pledgesFor(
        _winner(),
        const {'lifeCost': 20, 'environment': -2},
        const {'lifeCost': 15}, // environment 欠損
      );
      final lifeCost = pledges.firstWhere((p) => p.lifeParamKey == 'lifeCost');
      expect(lifeCost.promisedDelta, -10);
      expect(lifeCost.actualDelta, -5);
      expect(lifeCost.status, ManifestoStatus.partial);

      final environment = pledges.firstWhere((p) => p.lifeParamKey == 'environment');
      expect(environment.actualDelta, 2); // 0 - (-2)
      expect(environment.status, ManifestoStatus.reversed);
    });

    test('入力の before/after を破壊しない', () {
      final before = {'employment': 0};
      final after = {'employment': 5};
      ManifestoService.pledgesFor(_winner(), before, after);
      expect(before, {'employment': 0});
      expect(after, {'employment': 5});
    });
  });

  group('ManifestoService.evaluate', () {
    test('当選者情報を含む ManifestoRecord を組み立てる', () {
      final record = ManifestoService.evaluate(
        electionId: 'e9',
        title: '天照町長選',
        winner: _winner(),
        before: const {'employment': 0},
        after: const {'employment': 13},
        occurredAt: DateTime(2026, 10, 9),
      );
      expect(record.electionId, 'e9');
      expect(record.title, '天照町長選');
      expect(record.winnerId, 'candidate_1');
      expect(record.winnerName, '山田太郎');
      expect(record.occurredAt, DateTime(2026, 10, 9));
      expect(record.pledges, isNotEmpty);
    });

    test('occurredAt 省略時は null', () {
      final record = ManifestoService.evaluate(
        electionId: 'e9',
        title: '天照町長選',
        winner: _winner(),
        before: const {},
        after: const {},
      );
      expect(record.occurredAt, isNull);
    });
  });

  group('ManifestoService.fromResult', () {
    test('未完了選挙なら null', () {
      final result = _election(winnerId: null, voteCounts: null);
      expect(
        ManifestoService.fromResult(
          result: result,
          before: const {'employment': 0},
          after: const {'employment': 5},
        ),
        isNull,
      );
    });

    test('当選者が候補一覧に存在しなければ null', () {
      final result = _election(winnerId: 'candidate_99', voteCounts: const {'candidate_99': 5});
      expect(
        ManifestoService.fromResult(
          result: result,
          before: const {'employment': 0},
          after: const {'employment': 5},
        ),
        isNull,
      );
    });

    test('完了選挙から当選者の公約実現度を評価する', () {
      final result = _election(winnerId: 'candidate_1', voteCounts: const {'candidate_1': 10});
      final record = ManifestoService.fromResult(
        result: result,
        before: const {'employment': 0},
        after: const {'employment': 13},
      );
      expect(record, isNotNull);
      expect(record!.electionId, 'election_1');
      expect(record.winnerId, 'candidate_1');
      final employment = record.pledges.firstWhere((p) => p.lifeParamKey == 'employment');
      expect(employment.status, ManifestoStatus.fulfilled);
    });
  });

  group('ManifestoService.sortByDateDesc', () {
    ManifestoRecord r(String id, DateTime? at) => ManifestoRecord(
          electionId: id,
          title: 't$id',
          winnerId: 'w',
          winnerName: 'n',
          occurredAt: at,
        );

    test('occurredAt 降順・null は末尾', () {
      final records = [
        r('b', null),
        r('c', DateTime(2026, 1, 1)),
        r('a', null),
        r('d', DateTime(2027, 1, 1)),
      ];
      final sorted = ManifestoService.sortByDateDesc(records);
      expect(sorted.map((e) => e.electionId).toList(), ['d', 'c', 'a', 'b']);
    });

    test('同時刻は electionId 昇順でタイブレーク（null同士含む）', () {
      final records = [
        r('z', DateTime(2026, 5, 5)),
        r('m', null),
        r('a', DateTime(2026, 5, 5)),
        r('b', null),
      ];
      final sorted = ManifestoService.sortByDateDesc(records);
      expect(sorted.map((e) => e.electionId).toList(), ['a', 'z', 'b', 'm']);
    });

    test('元のリストを破壊しない', () {
      final records = [
        r('b', DateTime(2026, 1, 1)),
        r('a', DateTime(2027, 1, 1)),
      ];
      final sorted = ManifestoService.sortByDateDesc(records);
      expect(records.map((e) => e.electionId).toList(), ['b', 'a']);
      expect(sorted.map((e) => e.electionId).toList(), ['a', 'b']);
    });
  });

  group('ManifestoService.search', () {
    ManifestoRecord r(String id, String name, String title) => ManifestoRecord(
          electionId: id,
          title: title,
          winnerId: 'w$id',
          winnerName: name,
        );

    test('空クエリは全件を順序保持で返す', () {
      final records = [r('1', '山田太郎', '町長選'), r('2', '佐藤花子', '市長選')];
      expect(ManifestoService.search(records, ''), records);
      expect(ManifestoService.search(records, '   '), records);
    });

    test('winnerName の部分一致', () {
      final records = [r('1', '山田太郎', '町長選'), r('2', '佐藤花子', '市長選')];
      final hit = ManifestoService.search(records, '山田');
      expect(hit.length, 1);
      expect(hit.first.electionId, '1');
    });

    test('title の部分一致', () {
      final records = [r('1', '山田太郎', '町長選'), r('2', '佐藤花子', '市長選')];
      final hit = ManifestoService.search(records, '市長');
      expect(hit.length, 1);
      expect(hit.first.electionId, '2');
    });

    test('全角英数・全角スペース・大文字を正規化して一致させる', () {
      final records = [r('1', 'ＴＡＮＡＫＡ　美咲', 'ＴＯＷＮ選'), r('2', '山田太郎', '町長選')];
      expect(ManifestoService.search(records, 'tanaka').length, 1);
      expect(ManifestoService.search(records, 'ＴＡＮＡＫＡ').length, 1);
      expect(ManifestoService.search(records, 'TOWN').length, 1);
      expect(ManifestoService.search(records, 'tanaka　美咲').length, 1);
    });

    test('一致順序は入力順を保持する', () {
      final records = [
        r('1', '山田太郎', '町長選'),
        r('2', '山田次郎', '市長選'),
        r('3', '佐藤花子', '村長選'),
      ];
      final hit = ManifestoService.search(records, '山田');
      expect(hit.map((e) => e.electionId).toList(), ['1', '2']);
    });
  });

  group('ManifestoService.fulfilledTotal', () {
    test('全レコードの fulfilledCount を合計する', () {
      ManifestoPledge p(int promised, int actual) => ManifestoPledge(
            lifeParamKey: 'safety',
            promisedDelta: promised,
            actualDelta: actual,
          );
      final records = [
        ManifestoRecord(
          electionId: '1',
          title: 't',
          winnerId: 'w',
          winnerName: 'n',
          pledges: [p(5, 5), p(5, 2)],
        ),
        ManifestoRecord(
          electionId: '2',
          title: 't',
          winnerId: 'w',
          winnerName: 'n',
          pledges: [p(0, 0), p(5, 5)],
        ),
        ManifestoRecord(
          electionId: '3',
          title: 't',
          winnerId: 'w',
          winnerName: 'n',
        ),
      ];
      expect(ManifestoService.fulfilledTotal(records), 2);
    });
  });
}
