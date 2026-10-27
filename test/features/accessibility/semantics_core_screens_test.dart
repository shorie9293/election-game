// コード適応神書 原則③ Semantics体系 — コア画面の identifier 試練
//
// 対象5画面:
//   HomeScreen / VoteScreen / ElectionResultScreen / DebateScreen /
//   CandidateAlmanacScreen
//
// 検証観点（1画面 2〜4 ケース）:
//   1. SemanticHelper が発行する identifier が「一意」であること（重複identifier検出）
//   2. identifier の SemanticsNode.label に期待する日本語ラベルが含まれること
//   3. 対象ウィジェットがタップ到達可能であること（必要に応じ ensureVisible）
//
// 実装メモ:
//   - find.bySemanticsIdentifier は Semantics 有効化が必須のため
//     tester.ensureSemantics() を pump 前に呼ぶ。
//   - 重複検出は「Semantics ウィジェットの identifier 宣言数」と
//     「Semantics ツリー上の到達性」の二段で撃つ（マージ耐性のため）。
//   - 画面外の要素は ensureVisible（scrollFirst）で可視化してからタップする。
//   - CandidateAlmanacScreen は identifier 未発行の実欠陥があるため、
//     「未発行であること」を固定する DEFECT 記録試練とした（lib は不変）。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/concern_evolution.dart';
import 'package:election_game/domain/models/daily_event.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/domain/services/election_service.dart';
import 'package:election_game/features/almanac/presentation/candidate_almanac_screen.dart';
import 'package:election_game/features/election/presentation/debate_screen.dart';
import 'package:election_game/features/election/presentation/election_result_screen.dart';
import 'package:election_game/features/election/presentation/vote_screen.dart';
import 'package:election_game/features/home/presentation/home_screen.dart';

// --- 共通ヘルパー ---------------------------------------------------------

/// Semantics を有効化する（find.bySemanticsIdentifier の前提条件）。
// testWidgets は既定 semanticsEnabled: true（ensureSemantics 済み）ゆえ
// 個別の ensureSemantics() は不要。呼ぶと SemanticsHandle 未解放で必ず赤化する。
void _enableSemantics(WidgetTester tester) {}

Finder _sem(String identifier) => find.bySemanticsIdentifier(identifier);

/// identifier が一意に存在し、label に日本語文字列が含まれることを検証する。
void _expectSemantics(
  WidgetTester tester,
  String identifier, {
  String? labelContains,
}) {
  final finder = _sem(identifier);
  expect(
    finder,
    findsOneWidget,
    reason: 'identifier「$identifier」が一意に発行されていない（0件または重複）',
  );
  if (labelContains != null) {
    final label = tester.getSemantics(finder).label;
    expect(
      label,
      contains(labelContains),
      reason: 'identifier「$identifier」の label「$label」に「$labelContains」が含まれない',
    );
  }
}

/// SemanticHelper 命名規則（type_identifier）に沿った identifier のみを対象にする。
/// Flutter 内部が発行する identifier を誤検出しないための絞り込み。
final RegExp _helperIdPattern = RegExp(r'^(btn|tgl|txt|sec|nav|item|dlg|ico)_');

/// widget 木に宣言された identifier を列挙する（SemanticsNode のマージに影響されない）。
List<String> _declaredIdentifiers(WidgetTester tester) => tester
    .widgetList<Semantics>(find.byType(Semantics))
    .map((w) => w.properties.identifier)
    .whereType<String>()
    .where(_helperIdPattern.hasMatch)
    .toList();

/// 一覧系画面を含む identifier 群に重複・欠落が無いことを一括検証する。
///
/// 「宣言側の個数」と「Semantics ツリー上の到達性」の両面から重複を撃つ。
void _expectNoDuplicate(WidgetTester tester, List<String> identifiers) {
  final declared = _declaredIdentifiers(tester);
  for (final identifier in identifiers) {
    final count = declared.where((id) => id == identifier).length;
    expect(
      count,
      1,
      reason: '重複identifier検出: $identifier が $count 個宣言されている',
    );
    expect(
      _sem(identifier),
      findsOneWidget,
      reason: 'identifier「$identifier」が Semantics ツリー上で一意でない',
    );
  }
}

/// Semantics identifier 経由でタップする（下部要素は scrollFirst で可視化）。
Future<void> _tapSemantics(
  WidgetTester tester,
  String identifier, {
  bool scrollFirst = false,
  bool warnIfMissed = true,
}) async {
  final finder = _sem(identifier);
  expect(finder, findsOneWidget, reason: 'identifier「$identifier」が見つからない');
  if (scrollFirst) {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }
  await tester.tap(finder, warnIfMissed: warnIfMissed);
  await tester.pumpAndSettle();
}

// --- 画面ハーネス ---------------------------------------------------------

final _citizen = Citizen(
  name: 'テスト太郎',
  job: Job.farmer,
  concerns: [Concern.agriculture],
  lifeParams: {
    'lifeCost': 50,
    'healthcare': 50,
    'education': 50,
    'employment': 50,
    'environment': 70,
    'safety': 50,
  },
);

final _society = SocietyState(
  happiness: 65.0,
  mood: 0.4,
  electionCount: 2,
);

final _dailyEvent = DailyEvent(
  title: '町内清掃',
  description: '地域の清掃活動が行われた',
  icon: '🧹',
);

final _evolutions = [
  ConcernEvolution.initial(Concern.agriculture),
  ConcernEvolution(
    concern: Concern.education,
    acquiredAtElection: 1,
    reason: '討論で教育の重要性に気づいた',
  ),
];

Widget _buildHome({
  int remainingTurns = 10,
  DailyEvent? dailyEvent,
  List<ConcernEvolution> concernEvolutions = const [],
  VoidCallback? onStartElection,
}) {
  return MaterialApp(
    home: HomeScreen(
      citizen: _citizen,
      societyState: _society,
      remainingTurns: remainingTurns,
      dailyEvent: dailyEvent,
      concernEvolutions: concernEvolutions,
      onStartElection: onStartElection,
    ),
  );
}

Future<void> _pumpHome(WidgetTester tester, Widget home) async {
  _enableSemantics(tester);
  await tester.pumpWidget(home);
  await tester.pumpAndSettle();
}

Election _debateElection() {
  final candidates = Candidate.samples().take(2).toList();
  return Election(
    id: 'test',
    title: 'テスト選挙',
    scale: ElectionScale.village,
    candidates: candidates,
  );
}

Election _resultElection() =>
    ElectionService.computeElectionResult(Election.sample());

void main() {
  setUp(() {
    // HomeScreen（クロスアプリ連携カード）と DebateScreen（評価保存）が
    // SharedPreferences を触るため、必ずモック値を入れておく。
    SharedPreferences.setMockInitialValues({});
  });

  // ======================================================================
  // HomeScreen
  // ======================================================================
  group('HomeScreen semantics', () {
    testWidgets('主要カードは identifier が一意で、日本語 label を持つ', (tester) async {
      await _pumpHome(tester, _buildHome());

      _expectSemantics(tester, 'btn_home_citizen_info', labelContains: '市民情報');
      _expectSemantics(tester, 'btn_home_society_mood', labelContains: '社会ムード');
      _expectSemantics(tester, 'btn_home_life_params', labelContains: '生活パラメータ');
      _expectSemantics(
        tester,
        'btn_home_countdown',
        labelContains: '次回選挙までのカウントダウン',
      );
      _expectSemantics(
        tester,
        'btn_home_crossapp_link',
        labelContains: 'クロスアプリ連携',
      );
    });

    testWidgets('条件表示カード（デイリーイベント・政治的成長）も一意に発行される', (tester) async {
      await _pumpHome(
        tester,
        _buildHome(dailyEvent: _dailyEvent, concernEvolutions: _evolutions),
      );

      _expectSemantics(tester, 'btn_home_daily_event', labelContains: '今日の出来事');
      _expectSemantics(tester, 'btn_home_concern_growth', labelContains: '政治的成長');
    });

    testWidgets('全 identifier が重複せず 1 つずつ発行される', (tester) async {
      await _pumpHome(
        tester,
        _buildHome(
          remainingTurns: 0,
          dailyEvent: _dailyEvent,
          concernEvolutions: _evolutions,
        ),
      );

      _expectNoDuplicate(tester, const [
        'btn_home_citizen_info',
        'btn_home_concern_growth',
        'btn_home_society_mood',
        'btn_home_daily_event',
        'btn_home_life_params',
        'btn_home_countdown',
        'btn_start_election',
        'btn_home_crossapp_link',
      ]);
    });

    testWidgets('btn_start_election はタップ到達可能で onStartElection を呼ぶ', (tester) async {
      var started = false;
      await _pumpHome(
        tester,
        _buildHome(remainingTurns: 0, onStartElection: () => started = true),
      );

      _expectSemantics(tester, 'btn_start_election', labelContains: '選挙に行く');
      await _tapSemantics(tester, 'btn_start_election', scrollFirst: true);
      expect(started, isTrue);
    });
  });

  // ======================================================================
  // VoteScreen
  // ======================================================================
  group('VoteScreen semantics', () {
    testWidgets('ヘッダー・候補者リスト・棄権の identifier が一意で label を持つ', (tester) async {
      _enableSemantics(tester);
      await tester.pumpWidget(MaterialApp(home: VoteScreen(election: Election.sample())));
      await tester.pumpAndSettle();

      _expectSemantics(tester, 'btn_vote_title', labelContains: '投票');
      _expectSemantics(
        tester,
        'btn_vote_candidate_list',
        labelContains: '投票候補者一覧',
      );
      _expectSemantics(tester, 'btn_vote_abstain', labelContains: '棄権');
    });

    testWidgets('候補者リストは複数候補者でも identifier が重複しない', (tester) async {
      final election = Election.sample(); // 4 候補者
      expect(election.candidates.length, greaterThan(1));

      _enableSemantics(tester);
      await tester.pumpWidget(MaterialApp(home: VoteScreen(election: election)));
      await tester.pumpAndSettle();

      _expectNoDuplicate(tester, const [
        'btn_vote_title',
        'btn_vote_candidate_list',
        'btn_vote_abstain',
      ]);
    });

    testWidgets('btn_vote_abstain はタップ到達可能で onAbstain を呼ぶ', (tester) async {
      var abstained = false;
      _enableSemantics(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: VoteScreen(
            election: Election.sample(),
            onAbstain: () => abstained = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _tapSemantics(tester, 'btn_vote_abstain');
      expect(abstained, isTrue);
    });

    testWidgets('候補者選択後に btn_vote_confirm が一意に現れ、タップで投票できる', (tester) async {
      final election = Election.sample();
      String? votedCandidateId;
      _enableSemantics(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: VoteScreen(
            election: election,
            onVoteCast: (candidateId) => votedCandidateId = candidateId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 選択前は確定ボタンが存在しない
      expect(_sem('btn_vote_confirm'), findsNothing);

      await tester.tap(find.text(election.candidates[0].name).first);
      await tester.pumpAndSettle();

      _expectSemantics(tester, 'btn_vote_confirm', labelContains: '投票を確定');
      // 一覧側 identifier が選択後も重複しないこと
      _expectNoDuplicate(tester, const [
        'btn_vote_title',
        'btn_vote_candidate_list',
        'btn_vote_confirm',
        'btn_vote_abstain',
      ]);

      await _tapSemantics(tester, 'btn_vote_confirm');
      expect(votedCandidateId, election.candidates[0].id);
    });
  });

  // ======================================================================
  // ElectionResultScreen
  // ======================================================================
  group('ElectionResultScreen semantics', () {
    testWidgets('結果セクションの identifier が重複せず 1 つずつ発行される', (tester) async {
      _enableSemantics(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: ElectionResultScreen(
            result: _resultElection(),
            lifeParamChanges: {'employment': 10, 'lifeCost': -5},
          ),
        ),
      );
      await tester.pumpAndSettle();

      _expectNoDuplicate(tester, const [
        'btn_result_title',
        'btn_result_winner',
        'btn_result_vote_counts',
        'btn_result_vote_explanation',
        'btn_result_life_impact',
        'btn_return_to_town',
      ]);
    });

    testWidgets('各 identifier の label に期待する日本語が含まれる', (tester) async {
      final result = _resultElection();
      final winner = result.candidates.firstWhere((c) => c.id == result.winnerId);

      _enableSemantics(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: ElectionResultScreen(
            result: result,
            lifeParamChanges: {'employment': 10},
            votedCandidateId: result.candidates.first.id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      _expectSemantics(tester, 'btn_result_title', labelContains: '選挙結果');
      _expectSemantics(tester, 'btn_result_winner', labelContains: '当選者');
      // 当選者名が label に載っていること（ネストした Semantics の融合検知）
      _expectSemantics(tester, 'btn_result_winner', labelContains: winner.name);
      _expectSemantics(tester, 'btn_result_vote_counts', labelContains: '得票数');
      _expectSemantics(
        tester,
        'btn_result_vote_explanation',
        labelContains: 'あなたの投票の影響',
      );
      _expectSemantics(tester, 'btn_result_life_impact', labelContains: '生活への影響');
      _expectSemantics(tester, 'btn_return_to_town', labelContains: '街に戻る');
    });

    testWidgets('btn_return_to_town はタップ到達可能で onContinue を呼ぶ', (tester) async {
      var continued = false;
      _enableSemantics(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: ElectionResultScreen(
            result: _resultElection(),
            lifeParamChanges: const {},
            onContinue: () => continued = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _tapSemantics(tester, 'btn_return_to_town', scrollFirst: true);
      expect(continued, isTrue);
    });
  });

  // ======================================================================
  // DebateScreen
  // ======================================================================
  group('DebateScreen semantics', () {
    testWidgets('討論ヘッダー・発言者・吹き出しの identifier が一意で label を持つ', (tester) async {
      final election = _debateElection();
      _enableSemantics(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: DebateScreen(election: election, onProceedToVote: () {}),
        ),
      );
      await tester.pumpAndSettle();

      _expectSemantics(tester, 'btn_debate_title', labelContains: '候補者討論会');
      _expectSemantics(
        tester,
        'btn_debate_candidate_name',
        labelContains: '発言者: ${election.candidates.first.name}',
      );
      _expectSemantics(
        tester,
        'btn_debate_speech_bubble',
        labelContains: '私の公約は',
      );
    });

    testWidgets('反応ボタン4種は identifier が重複せず、タップで次の発言へ進む', (tester) async {
      final election = _debateElection();
      _enableSemantics(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: DebateScreen(election: election, onProceedToVote: () {}),
        ),
      );
      await tester.pumpAndSettle();

      _expectNoDuplicate(tester, const [
        'btn_debate_reaction_agree',
        'btn_debate_reaction_disagree',
        'btn_debate_reaction_question',
        'btn_debate_reaction_silent',
      ]);
      _expectSemantics(
        tester,
        'btn_debate_reaction_agree',
        labelContains: '同意する',
      );

      await _tapSemantics(tester, 'btn_debate_reaction_agree');

      // 2 番目の発言者に切り替わっている（identifier は同一で label が変化）
      _expectSemantics(
        tester,
        'btn_debate_candidate_name',
        labelContains: election.candidates[1].name,
      );
    });

    testWidgets('評価フェーズと投票遷移の identifier が機能する', (tester) async {
      final election = _debateElection();
      var proceeded = false;
      _enableSemantics(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: DebateScreen(
            election: election,
            onProceedToVote: () => proceeded = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 2 候補者 → 4 発言をすべて消化して評価フェーズへ
      for (var i = 0; i < 4; i++) {
        await _tapSemantics(tester, 'btn_debate_reaction_silent');
      }

      _expectSemantics(tester, 'btn_submit_ratings', labelContains: '評価を送信');

      // 全候補者を星 3 で評価（AppKeys 側の既存 Key を利用）
      for (final candidate in election.candidates) {
        await tester.tap(
          find
              .descendant(
                of: find.byKey(AppKeys.debateRatingStars(candidate.id)),
                matching: find.byIcon(Icons.star_border),
              )
              .at(2),
        );
        await tester.pumpAndSettle();
      }

      await _tapSemantics(tester, 'btn_submit_ratings');

      _expectSemantics(tester, 'btn_proceed_to_vote', labelContains: '投票へ進む');
      await _tapSemantics(tester, 'btn_proceed_to_vote');
      expect(proceeded, isTrue);
    });
  });

  // ======================================================================
  // CandidateAlmanacScreen
  // ======================================================================
  group('CandidateAlmanacScreen semantics', () {
    Future<void> pumpAlmanac(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      _enableSemantics(tester);
      await tester.pumpWidget(const MaterialApp(home: CandidateAlmanacScreen()));
      await tester.pumpAndSettle();
    }

    testWidgets('画面骨格（タイトル・検索欄・件数）が描画される', (tester) async {
      await pumpAlmanac(tester);

      expect(find.byKey(AppKeys.almanacTitle), findsOneWidget);
      expect(find.byKey(AppKeys.almanacSearchField), findsOneWidget);
      expect(find.byKey(AppKeys.almanacCountLabel), findsOneWidget);
      expect(find.text('候補者名鑑'), findsOneWidget);
    });

    testWidgets('候補者カードはタップ到達可能で詳細ダイアログが開く', (tester) async {
      await pumpAlmanac(tester);

      final card = find.byKey(AppKeys.almanacCandidateCard('candidate_1'));
      expect(card, findsOneWidget);

      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      await tester.tap(card);
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.almanacDetailDialog), findsOneWidget);
    });

    // 令和八年十月二十八日 是正:
    //   candidate_almanac_screen.dart は Semantics 皆無だった（identifier 0 件）ため
    //   SemanticHelper（txt_/sec_/item_）を付与し、本試練を「未発行の記録」から
    //   「一意に発行され日本語 label を持つ」検証へ格上げした。
    testWidgets('名鑑画面の identifier が一意に発行され、日本語 label を持つ', (tester) async {
      await pumpAlmanac(tester);

      _expectSemantics(tester, 'txt_almanac_search', labelContains: '候補者を検索');
      _expectSemantics(
        tester,
        'sec_almanac_faction_filter',
        labelContains: '派閥',
      );
      _expectSemantics(tester, 'txt_almanac_count');

      final declared = _declaredIdentifiers(tester);
      expect(
        declared.toSet().length,
        declared.length,
        reason: 'identifier が重複宣言されている: $declared',
      );
      // 一覧項目は候補者ごとに一意（item_almanac_candidate_<id>）。
      expect(
        declared.where((id) => id.startsWith('item_almanac_candidate_')).length,
        greaterThan(0),
        reason: '候補者カードに一意 identifier が付与されていない',
      );
    });

  });
}
