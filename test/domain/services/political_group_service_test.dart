import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/political_group.dart';
import 'package:election_game/domain/models/political_group_profile.dart';
import 'package:election_game/domain/services/political_group_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('economicLabel', () {
    test('正の値は 自由市場', () {
      expect(PoliticalGroupService.economicLabel(0.8), '自由市場');
    });
    test('負の値は 規制', () {
      expect(PoliticalGroupService.economicLabel(-0.5), '規制');
    });
    test('0.0 ちょうどは 中立', () {
      expect(PoliticalGroupService.economicLabel(0.0), '中立');
    });
  });

  group('welfareLabel', () {
    test('正の値は 社会保障重視', () {
      expect(PoliticalGroupService.welfareLabel(0.9), '社会保障重視');
    });
    test('負の値は 自己責任', () {
      expect(PoliticalGroupService.welfareLabel(-0.2), '自己責任');
    });
    test('0.0 ちょうどは 中立', () {
      expect(PoliticalGroupService.welfareLabel(0.0), '中立');
    });
  });

  group('quadrantLabel', () {
    test('経済×福祉 の複合ラベルを返す', () {
      expect(PoliticalGroupService.quadrantLabel(0.8, -0.2), '自由市場 × 自己責任');
      expect(PoliticalGroupService.quadrantLabel(-0.3, 0.9), '規制 × 社会保障重視');
    });
    test('中立を含む複合ラベル', () {
      expect(PoliticalGroupService.quadrantLabel(0.0, 0.0), '中立 × 中立');
    });
  });

  group('neutralThreshold', () {
    test('0.0 で定義されている', () {
      expect(PoliticalGroupService.neutralThreshold, 0.0);
    });
  });

  group('buildProfiles', () {
    test('既定は samples() の5団体を入力順に返す', () {
      final profiles = PoliticalGroupService.buildProfiles();
      expect(profiles.length, 5);
      expect(
        profiles.map((p) => p.group.id).toList(),
        [
          'group_development',
          'group_symbiosis',
          'group_defense',
          'group_green',
          'group_reform',
        ],
      );
    });

    test('軸ラベルと象限ラベルが埋め込まれる', () {
      final profiles = PoliticalGroupService.buildProfiles();
      final dev = profiles.first;
      expect(dev.economicLabel, '自由市場');
      expect(dev.welfareLabel, '自己責任');
      expect(dev.quadrantLabel, '自由市場 × 自己責任');
    });

    test('発展の会は candidate_1, candidate_2 の順（宣言順保持）', () {
      final profiles = PoliticalGroupService.buildProfiles();
      final dev = profiles.firstWhere((p) => p.group.id == 'group_development');
      expect(dev.supportedCandidates.map((c) => c.id).toList(),
          ['candidate_1', 'candidate_2']);
      expect(dev.supportCount, 2);
      expect(dev.hasSupport, isTrue);
      expect(dev.supportedNamesLabel, '山田太郎、佐藤花子');
    });

    test('未知IDは無視される', () {
      final group = PoliticalGroup(
        id: 'g_unknown',
        name: '未知の会',
        ideology: '未知',
        economicAxis: 0.0,
        welfareAxis: 0.0,
        supportedCandidateIds: ['candidate_1', 'candidate_unknown'],
      );
      final profiles = PoliticalGroupService.buildProfiles(groups: [group]);
      expect(profiles.single.supportedCandidates.map((c) => c.id).toList(),
          ['candidate_1']);
    });

    test('supportedCandidateIds の順序は candidates の宣言順に並べ替えられない', () {
      final group = PoliticalGroup(
        id: 'g_rev',
        name: '逆順の会',
        ideology: '逆',
        economicAxis: 0.0,
        welfareAxis: 0.0,
        supportedCandidateIds: ['candidate_2', 'candidate_1'],
      );
      final profiles = PoliticalGroupService.buildProfiles(groups: [group]);
      expect(profiles.single.supportedCandidates.map((c) => c.id).toList(),
          ['candidate_2', 'candidate_1']);
    });

    test('推薦候補なしは supportedNamesLabel が 推薦候補なし', () {
      final profiles = PoliticalGroupService.buildProfiles();
      final green = profiles.firstWhere((p) => p.group.id == 'group_green');
      expect(green.hasSupport, isFalse);
      expect(green.supportedNamesLabel, '推薦候補なし');
    });

    test('カスタム candidates を渡して解決できる', () {
      final candidate = Candidate.samples().first;
      final profiles = PoliticalGroupService.buildProfiles(
        groups: [PoliticalGroup.samples().first],
        candidates: [candidate],
      );
      expect(profiles.single.supportedCandidates.single.id, candidate.id);
    });
  });

  group('analyze', () {
    test('totalGroups は profiles の件数', () {
      final analysis = PoliticalGroupService.analyze();
      expect(analysis.totalGroups, 5);
    });

    test('totalSupportEdges は支持辺の合計', () {
      final analysis = PoliticalGroupService.analyze();
      // 2 + 1 + 1 + 0 + 1
      expect(analysis.totalSupportEdges, 5);
    });

    test('withSupport は推薦候補ありの4団体', () {
      final analysis = PoliticalGroupService.analyze();
      expect(analysis.withSupport.length, 4);
      expect(analysis.withSupport
          .every((p) => p.group.id != 'group_green'), isTrue);
    });

    test('緑の会 が zeroSupportGroups に入る', () {
      final analysis = PoliticalGroupService.analyze();
      expect(analysis.zeroSupportGroups.map((g) => g.id).toList(),
          ['group_green']);
    });

    test('candidateSupports は支持団体を持つ候補のみ・Candidate.samples() 宣言順', () {
      final analysis = PoliticalGroupService.analyze();
      expect(analysis.candidateSupports.map((s) => s.candidate.id).toList(),
          ['candidate_1', 'candidate_2', 'candidate_3', 'candidate_4']);
    });

    test('candidate_2 は 発展の会 と 共生の会 に支持される', () {
      final analysis = PoliticalGroupService.analyze();
      final sato =
          analysis.candidateSupports.firstWhere((s) => s.candidate.id == 'candidate_2');
      expect(sato.groupCount, 2);
      expect(sato.groupNamesLabel, '発展の会、共生の会');
    });

    test('candidateSupports の groups は PoliticalGroup.samples() の宣言順', () {
      final groups = [
        PoliticalGroup.samples().last,
        PoliticalGroup.samples().first,
      ];
      final analysis = PoliticalGroupService.analyze(
        groups: groups,
        candidates: Candidate.samples(),
      );
      final yamada = analysis.candidateSupports
          .firstWhere((s) => s.candidate.id == 'candidate_1');
      expect(yamada.groups.map((g) => g.id).toList(), ['group_development']);
    });
  });

  group('sortByEconomic', () {
    test('既定は economicAxis 降順', () {
      final sorted = PoliticalGroupService.sortByEconomic(
          PoliticalGroupService.buildProfiles());
      final axes = sorted.map((p) => p.group.economicAxis).toList();
      expect(axes, [0.8, 0.2, -0.3, -0.5, -0.6]);
    });

    test('ascending は昇順', () {
      final sorted = PoliticalGroupService.sortByEconomic(
          PoliticalGroupService.buildProfiles(),
          descending: false);
      final axes = sorted.map((p) => p.group.economicAxis).toList();
      expect(axes, [-0.6, -0.5, -0.3, 0.2, 0.8]);
    });

    test('入力を破壊しない', () {
      final input = PoliticalGroupService.buildProfiles();
      final before = input.map((p) => p.group.id).toList();
      PoliticalGroupService.sortByEconomic(input);
      expect(input.map((p) => p.group.id).toList(), before);
    });

    test('tie は group.name 昇順', () {
      final base = PoliticalGroupService.buildProfiles(
        groups: [
          PoliticalGroup(
            id: 'g_b',
            name: '乙の会',
            ideology: 'b',
            economicAxis: 0.5,
            welfareAxis: 0.0,
            supportedCandidateIds: const [],
          ),
          PoliticalGroup(
            id: 'g_a',
            name: '甲の会',
            ideology: 'a',
            economicAxis: 0.5,
            welfareAxis: 0.0,
            supportedCandidateIds: const [],
          ),
          PoliticalGroup(
            id: 'g_c',
            name: '丙の会',
            ideology: 'c',
            economicAxis: 0.1,
            welfareAxis: 0.0,
            supportedCandidateIds: const [],
          ),
        ],
      );
      final sorted = PoliticalGroupService.sortByEconomic(base);
      expect(sorted.map((p) => p.group.name).toList(), ['乙の会', '甲の会', '丙の会']);
    });
  });

  group('filterByQuadrant', () {
    test('象限ラベルで完全一致フィルタ', () {
      final profiles = PoliticalGroupService.buildProfiles();
      final filtered = PoliticalGroupService.filterByQuadrant(
          profiles, '自由市場 × 自己責任');
      expect(filtered.length, 1);
      expect(filtered.single.group.id, 'group_development');
    });

    test('一致なしは空リスト', () {
      final filtered =
          PoliticalGroupService.filterByQuadrant(
              PoliticalGroupService.buildProfiles(), '存在しない象限');
      expect(filtered, isEmpty);
    });

    test('空文字は全件', () {
      final filtered =
          PoliticalGroupService.filterByQuadrant(
              PoliticalGroupService.buildProfiles(), '');
      expect(filtered.length, 5);
    });
  });

  group('groupsForCandidate', () {
    test('candidate_2 を支持する団体は2件（宣言順）', () {
      final groups =
          PoliticalGroupService.groupsForCandidate(
              PoliticalGroup.samples(), 'candidate_2');
      expect(groups.map((g) => g.id).toList(),
          ['group_development', 'group_symbiosis']);
    });

    test('candidate_1 を支持する団体は1件', () {
      final groups =
          PoliticalGroupService.groupsForCandidate(
              PoliticalGroup.samples(), 'candidate_1');
      expect(groups.single.id, 'group_development');
    });

    test('支持されない候補は空', () {
      final groups =
          PoliticalGroupService.groupsForCandidate(
              PoliticalGroup.samples(), 'candidate_none');
      expect(groups, isEmpty);
    });

    test('PoliticalGroups.fromCandidateId と異なり複数件を返す', () {
      final groups =
          PoliticalGroupService.groupsForCandidate(
              PoliticalGroup.samples(), 'candidate_2');
      expect(groups.length, 2);
    });
  });

  group('searchByName', () {
    test('name の部分一致', () {
      final found = PoliticalGroupService.searchByName(
          PoliticalGroupService.buildProfiles(), '発展');
      expect(found.single.group.id, 'group_development');
    });

    test('ideology の部分一致', () {
      final found = PoliticalGroupService.searchByName(
          PoliticalGroupService.buildProfiles(), '支え合う');
      expect(found.single.group.id, 'group_symbiosis');
    });

    test('全角英数は半角化してマッチする', () {
      final profiles = PoliticalGroupService.buildProfiles(groups: [
        PoliticalGroup(
          id: 'g_alpha',
          name: 'ＡＢ会',
          ideology: 'テスト',
          economicAxis: 0.0,
          welfareAxis: 0.0,
          supportedCandidateIds: const [],
        ),
      ]);
      expect(
        PoliticalGroupService.searchByName(profiles, 'AB').single.group.id,
        'g_alpha',
      );
      // 半角で入力しても全角nameにマッチ
      expect(
        PoliticalGroupService.searchByName(profiles, 'ａｂ').single.group.id,
        'g_alpha',
      );
    });

    test('全角スペースは半角化・trim される', () {
      final profiles = PoliticalGroupService.buildProfiles(groups: [
        PoliticalGroup(
          id: 'g_ws',
          name: '宇宙　会議',
          ideology: '星',
          economicAxis: 0.0,
          welfareAxis: 0.0,
          supportedCandidateIds: const [],
        ),
      ]);
      expect(
        PoliticalGroupService.searchByName(profiles, '宇宙 会議'.replaceAll(' ', '　'))
            .single
            .group
            .id,
        'g_ws',
      );
      expect(
        PoliticalGroupService.searchByName(profiles, '　宇宙 会議　').single.group.id,
        'g_ws',
      );
    });

    test('大文字小文字を無視する', () {
      final profiles = PoliticalGroupService.buildProfiles(groups: [
        PoliticalGroup(
          id: 'g_eng',
          name: 'Green Party',
          ideology: 'eco',
          economicAxis: 0.0,
          welfareAxis: 0.0,
          supportedCandidateIds: const [],
        ),
      ]);
      expect(
        PoliticalGroupService.searchByName(profiles, 'green').single.group.id,
        'g_eng',
      );
    });

    test('空クエリは全件', () {
      expect(
        PoliticalGroupService.searchByName(
                PoliticalGroupService.buildProfiles(), '')
            .length,
        5,
      );
    });

    test('該当なしは空リスト', () {
      expect(
        PoliticalGroupService.searchByName(
                PoliticalGroupService.buildProfiles(), '存在しない団体名')
            .length,
        0,
      );
    });
  });

  group('Equatable / 集計getter', () {
    test('PoliticalGroupProfile は同値で等しい', () {
      final a = PoliticalGroupService.buildProfiles().first;
      final b = PoliticalGroupService.buildProfiles().first;
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('CandidateSupport の集計getter', () {
      final groups = PoliticalGroupService.groupsForCandidate(
          PoliticalGroup.samples(), 'candidate_2');
      final support = CandidateSupport(
        candidate: Candidate.samples()[1],
        groups: groups,
      );
      expect(support.groupCount, 2);
      expect(support.groupNamesLabel, '発展の会、共生の会');
    });

    test('PoliticalGroupAnalysis は同値で等しい', () {
      expect(PoliticalGroupService.analyze(), equals(PoliticalGroupService.analyze()));
    });
  });
}
