import 'package:election_game/domain/models/candidate.dart';

import 'package:election_game/domain/services/candidate_almanac_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// タイブレーク試験用の同スコア候補者
List<Candidate> _tiedCandidates() => [
      const Candidate(
        id: 'b_tie',
        name: '第二候補',
        portraitKey: 'p2',
        faction: '同点の会',
        personality: '同点',
        policies: [
          Policy(
            title: '公約',
            description: '同じ効果',
            category: '経済',
            effects: {'employment': 5},
          ),
        ],
      ),
      const Candidate(
        id: 'a_tie',
        name: '第一候補',
        portraitKey: 'p1',
        faction: '同点の会',
        personality: '同点',
        policies: [
          Policy(
            title: '公約',
            description: '同じ効果',
            category: '経済',
            effects: {'employment': 5},
          ),
        ],
      ),
    ];

void main() {
  group('lifeParamLabels / lifeParamLabel', () {
    test('6 生活パラメータのラベルを定義する', () {
      expect(CandidateAlmanacService.lifeParamLabels.length, 6);
      expect(CandidateAlmanacService.lifeParamLabels['lifeCost'], '生活費');
      expect(CandidateAlmanacService.lifeParamLabels['safety'], '治安');
    });

    test('lifeParamLabel は登録済みキーの日本語ラベルを返す', () {
      expect(CandidateAlmanacService.lifeParamLabel('healthcare'), '医療');
      expect(CandidateAlmanacService.lifeParamLabel('education'), '教育');
      expect(CandidateAlmanacService.lifeParamLabel('environment'), '環境');
    });

    test('lifeParamLabel は未登録キーをそのまま返す（境界）', () {
      expect(CandidateAlmanacService.lifeParamLabel('unknown_key'), 'unknown_key');
      expect(CandidateAlmanacService.lifeParamLabel(''), '');
    });
  });

  group('effectLabel', () {
    test('正・負・ゼロを規則通りに表示する', () {
      expect(CandidateAlmanacService.effectLabel(10), '+10');
      expect(CandidateAlmanacService.effectLabel(-5), '-5');
      expect(CandidateAlmanacService.effectLabel(0), '±0');
      expect(CandidateAlmanacService.effectLabel(1), '+1');
      expect(CandidateAlmanacService.effectLabel(-1), '-1');
    });
  });

  group('normalize', () {
    test('全角英数字を半角に変換する', () {
      expect(CandidateAlmanacService.normalize('ＡＢＣ１２３'), 'abc123');
    });

    test('全角スペースを半角に変換する', () {
      expect(CandidateAlmanacService.normalize('ｘ　ｙ'), 'x y');
    });

    test('前後の空白を除去し小文字化する', () {
      expect(CandidateAlmanacService.normalize('  Hello World  '), 'hello world');
    });

    test('全角英字と記号も半角になる', () {
      expect(CandidateAlmanacService.normalize('Ｔｅｓｔ！'), 'test!');
    });
  });

  group('buildProfile', () {
    test('effects は |value| 降順に整列する', () {
      final profile = CandidateAlmanacService.buildProfile(
        Candidate.samples().first,
      );
      for (var i = 0; i < profile.effects.length - 1; i++) {
        expect(
          profile.effects[i].value.abs(),
          greaterThanOrEqualTo(profile.effects[i + 1].value.abs()),
        );
      }
    });

    test('|value| 同順位は label 昇順に整列する', () {
      final c = const Candidate(
        id: 'same_abs',
        name: '同絶対値',
        portraitKey: 'p',
        faction: '整列の会',
        personality: '秩序',
        policies: [
          Policy(
            title: '公約',
            description: '同絶対値',
            category: '経済',
            effects: {'safety': 3, 'lifeCost': 3},
          ),
        ],
      );
      final profile = CandidateAlmanacService.buildProfile(c);
      // |3| == |3| → label 昇順: '治安'(safety) < '生活費'(lifeCost)? 昇順なら '治安' が先
      final labels = profile.effects.map((e) => e.label).toList();
      expect(labels.indexOf('治安'), lessThan(labels.indexOf('生活費')));
    });

    test('value が 0 の効果も effects に含まれる', () {
      final c = const Candidate(
        id: 'zero',
        name: 'ゼロ効果',
        portraitKey: 'p',
        faction: '無風の会',
        personality: '静観',
        policies: [
          Policy(
            title: '公約',
            description: 'ゼロ',
            category: '経済',
            effects: {'lifeCost': 0, 'employment': 2},
          ),
        ],
      );
      final profile = CandidateAlmanacService.buildProfile(c);
      expect(profile.effects.map((e) => e.key), contains('lifeCost'));
      expect(
        profile.effects.firstWhere((e) => e.key == 'lifeCost').display,
        '±0',
      );
    });

    test('effects のラベルは生活パラメータの日本語になる', () {
      final profile = CandidateAlmanacService.buildProfile(
        Candidate.samples().first,
      );
      expect(profile.effects.map((e) => e.label), contains('雇用'));
      expect(profile.effects.map((e) => e.label), contains('生活費'));
    });

    test('公約 0 件なら effects 空で dominantCategory は空文字（境界）', () {
      final c = Candidate(
        id: 'none',
        name: '無公約',
        portraitKey: 'p',
        faction: '無',
        personality: '自由',
        policies: const [],
      );
      final profile = CandidateAlmanacService.buildProfile(c);
      expect(profile.effects, isEmpty);
      expect(profile.dominantCategory, '');
      expect(profile.hasPolicies, isFalse);
    });

    test('dominantCategory はカテゴリ最頻値を返す', () {
      final profile = CandidateAlmanacService.buildProfile(
        Candidate.samples().first,
      );
      // 山田太郎は「経済」2 件 → 経済
      expect(profile.dominantCategory, '経済');
    });

    test('dominantCategory は同数のとき初出のカテゴリを採用する', () {
      final c = const Candidate(
        id: 'even',
        name: '均等候補',
        portraitKey: 'p',
        faction: '均衡の会',
        personality: '公平',
        policies: [
          Policy(
            title: 'A',
            description: '先の医療',
            category: '医療',
            effects: {},
          ),
          Policy(
            title: 'B',
            description: '後の経済',
            category: '経済',
            effects: {},
          ),
        ],
      );
      final profile = CandidateAlmanacService.buildProfile(c);
      expect(profile.dominantCategory, '医療');
    });

    test('未登録の lifeParamKey は key をそのままラベルにする', () {
      final c = const Candidate(
        id: 'odd_key',
        name: '変則候補',
        portraitKey: 'p',
        faction: '変則の会',
        personality: '規格外',
        policies: [
          Policy(
            title: '公約',
            description: '未登録キー',
            category: '経済',
            effects: {'mystery': 4},
          ),
        ],
      );
      final profile = CandidateAlmanacService.buildProfile(c);
      expect(profile.effects.single.label, 'mystery');
    });

    test('totalEffectScore が負の候補者も構築できる（境界）', () {
      final c = const Candidate(
        id: 'neg',
        name: '負候補',
        portraitKey: 'p',
        faction: '負の会',
        personality: '削減',
        policies: [
          Policy(
            title: '大型削減',
            description: '全て削る',
            category: '経済',
            effects: {'lifeCost': -10, 'employment': -3},
          ),
        ],
      );
      final profile = CandidateAlmanacService.buildProfile(c);
      expect(profile.totalEffectScore, -13);
      // |value| 降順: lifeCost(-10) が先
      expect(profile.effects.first.key, 'lifeCost');
    });
  });

  group('build', () {
    test('空リストなら空を返す（境界）', () {
      expect(CandidateAlmanacService.build(const []), isEmpty);
    });

    test('入力順を保つ', () {
      final samples = Candidate.samples();
      final profiles = CandidateAlmanacService.build(samples);
      expect(profiles.length, samples.length);
      for (var i = 0; i < samples.length; i++) {
        expect(profiles[i].candidate.id, samples[i].id);
      }
    });
  });

  group('sortByTotalEffect', () {
    test('降順に整列し同値は candidate.id 昇順（境界）', () {
      final profiles = CandidateAlmanacService.build(_tiedCandidates());
      final sorted = CandidateAlmanacService.sortByTotalEffect(profiles);
      expect(sorted.first.candidate.id, 'a_tie');
      expect(sorted.last.candidate.id, 'b_tie');
    });

    test('昇順にも整列できる', () {
      final profiles = CandidateAlmanacService.build(Candidate.samples());
      final sorted =
          CandidateAlmanacService.sortByTotalEffect(profiles, descending: false);
      for (var i = 0; i < sorted.length - 1; i++) {
        expect(
          sorted[i].totalEffectScore,
          lessThanOrEqualTo(sorted[i + 1].totalEffectScore),
        );
      }
    });

    test('入力リストを破壊しない（非破壊性・境界）', () {
      final samples = Candidate.samples();
      final before = samples.map((c) => c.id).toList();
      final profiles = CandidateAlmanacService.build(samples);
      final beforeOrder = profiles.map((p) => p.candidate.id).toList();
      CandidateAlmanacService.sortByTotalEffect(profiles);
      expect(profiles.map((p) => p.candidate.id).toList(), beforeOrder);
      expect(samples.map((c) => c.id).toList(), before);
    });
  });

  group('filterByFaction', () {
    test('null・空文字・すべて は全件を返す（境界）', () {
      final profiles = CandidateAlmanacService.build(Candidate.samples());
      expect(CandidateAlmanacService.filterByFaction(profiles, null).length,
          profiles.length);
      expect(CandidateAlmanacService.filterByFaction(profiles, '').length,
          profiles.length);
      expect(
          CandidateAlmanacService.filterByFaction(profiles, 'すべて').length,
          profiles.length);
    });

    test('指定派閥のみに絞り込む', () {
      final profiles = CandidateAlmanacService.build(Candidate.samples());
      final filtered =
          CandidateAlmanacService.filterByFaction(profiles, '発展の会');
      expect(filtered.length, 1);
      expect(filtered.single.candidate.faction, '発展の会');
    });

    test('該当なしなら空リスト', () {
      final profiles = CandidateAlmanacService.build(Candidate.samples());
      expect(
        CandidateAlmanacService.filterByFaction(profiles, '存在しない会'),
        isEmpty,
      );
    });
  });

  group('searchByName', () {
    test('名前の部分一致で検索できる', () {
      final profiles = CandidateAlmanacService.build(Candidate.samples());
      final hit = CandidateAlmanacService.searchByName(profiles, '山田');
      expect(hit.length, 1);
      expect(hit.single.candidate.name, '山田太郎');
    });

    test('派閥の部分一致でも検索できる', () {
      final profiles = CandidateAlmanacService.build(Candidate.samples());
      final hit = CandidateAlmanacService.searchByName(profiles, '共生');
      expect(hit.length, 1);
      expect(hit.single.candidate.faction, '共生の会');
    });

    test('空クエリ・空白のみなら全件（境界）', () {
      final profiles = CandidateAlmanacService.build(Candidate.samples());
      expect(CandidateAlmanacService.searchByName(profiles, '').length,
          profiles.length);
      expect(CandidateAlmanacService.searchByName(profiles, '   ').length,
          profiles.length);
    });

    test('全角英数字入力でも半角データにヒットする（境界）', () {
      final c = const Candidate(
        id: 'abc',
        name: 'Taro2026',
        portraitKey: 'p',
        faction: '未来の会',
        personality: '先進',
        policies: [],
      );
      final profiles = CandidateAlmanacService.build([c]);
      // 全角「Ｔａｒｏ」→ 半角 taro に正規化して一致
      final hit =
          CandidateAlmanacService.searchByName(profiles, 'Ｔａｒｏ');
      expect(hit.length, 1);
      // 全角数字も
      final hit2 =
          CandidateAlmanacService.searchByName(profiles, '２０２６');
      expect(hit2.length, 1);
    });

    test('大文字小文字を無視して検索する', () {
      final c = const Candidate(
        id: 'abc2',
        name: 'JaneDOE',
        portraitKey: 'p',
        faction: '国際の会',
        personality: '外交',
        policies: [],
      );
      final profiles = CandidateAlmanacService.build([c]);
      expect(
        CandidateAlmanacService.searchByName(profiles, 'janedoe').length,
        1,
      );
      expect(
        CandidateAlmanacService.searchByName(profiles, 'JANEDOE').length,
        1,
      );
    });

    test('該当なしなら空リスト', () {
      final profiles = CandidateAlmanacService.build(Candidate.samples());
      expect(
        CandidateAlmanacService.searchByName(profiles, '存在しない名前'),
        isEmpty,
      );
    });
  });

  group('factions', () {
    test('出現順・重複除去で派閥一覧を返す', () {
      final samples = Candidate.samples();
      final factions = CandidateAlmanacService.factions(samples);
      // 重複無し
      expect(factions.toSet().length, factions.length);
      // 出現順（サンプルは全員別派閥）
      expect(factions, samples.map((c) => c.faction).toList());
    });

    test('空リストなら空（境界）', () {
      expect(CandidateAlmanacService.factions(const []), isEmpty);
    });

    test('同一派閥が複数いても 1 つにまとまる', () {
      final tied = _tiedCandidates();
      final factions = CandidateAlmanacService.factions(tied);
      expect(factions, ['同点の会']);
    });
  });

  group('topByEffect', () {
    test('空リストなら null（境界）', () {
      expect(CandidateAlmanacService.topByEffect(const []), isNull);
    });

    test('最大スコアの候補者を返す', () {
      final profiles = CandidateAlmanacService.build(Candidate.samples());
      final top = CandidateAlmanacService.topByEffect(profiles)!;
      final maxScore = profiles
          .map((p) => p.totalEffectScore)
          .reduce((a, b) => a > b ? a : b);
      expect(top.totalEffectScore, maxScore);
    });

    test('同値タイは candidate.id 昇順で決定的（境界）', () {
      final profiles = CandidateAlmanacService.build(_tiedCandidates());
      final top1 = CandidateAlmanacService.topByEffect(profiles);
      final top2 = CandidateAlmanacService.topByEffect(
          CandidateAlmanacService.build(_tiedCandidates().reversed.toList()));
      expect(top1!.candidate.id, 'a_tie');
      expect(top2!.candidate.id, 'a_tie');
    });
  });

  group('純粋性・入力非破壊', () {
    test('build と検索は入力リストを変化させない', () {
      final samples = Candidate.samples();
      final beforeIds = samples.map((c) => c.id).toList();
      final beforeFirst = samples.first.name;

      final profiles = CandidateAlmanacService.build(samples);
      CandidateAlmanacService.searchByName(profiles, '山田');
      CandidateAlmanacService.filterByFaction(profiles, '発展の会');
      CandidateAlmanacService.topByEffect(profiles);

      expect(samples.map((c) => c.id).toList(), beforeIds);
      expect(samples.first.name, beforeFirst);
    });
  });
}
