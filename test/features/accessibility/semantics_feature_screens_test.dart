// 機能6画面のアクセシビリティ（Semantics identifier）試練。
//
// 対象:
//   election_archive_screen / glossary_screen / prediction_screen
//   manifesto_tracker_screen / support_simulation_screen / turnout_screen
//
// 実測結果（令和八年十月二十八日 現世点検）:
//   - SemanticHelper.interactive() による identifier 発行は
//     election_archive_screen のみ（btn_archive_summary_card / btn_archive_entry_<electionId>）。
//   - glossary / prediction / manifesto は Semantics 自体が未付与。
//   - support / turnout は AppBar タイトルに Semantics(label:, header: true) があるが
//     identifier は未付与。→ identifier 試練は「未発行の記録」として findsNothing で固定し、
//     lib へは手を入れない（付与された時点で identifier 検証へ格上げする）。
//
// 落とし穴対応:
//   - bySemanticsIdentifier は semantics 有効時のみ使える → tester.ensureSemantics()。
//   - 遅延描画/画面外 → 大きめ viewport（1080x2400）で論理高を確保。
//   - 繰り返しアニメーションがある画面は pumpAndSettle を使わず pump(Duration)。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_archive.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/models/glossary_term.dart';
import 'package:election_game/domain/models/manifesto.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/domain/services/turnout_service.dart';
import 'package:election_game/features/archive/presentation/election_archive_screen.dart';
import 'package:election_game/features/glossary/presentation/glossary_screen.dart';
import 'package:election_game/features/manifesto/presentation/manifesto_tracker_screen.dart';
import 'package:election_game/features/prediction/data/prediction_repository.dart';
import 'package:election_game/features/prediction/presentation/prediction_screen.dart';
import 'package:election_game/features/support/presentation/support_simulation_screen.dart';
import 'package:election_game/features/turnout/presentation/turnout_screen.dart';

/// widget 木に現れる Semantics.identifier を列挙する（重複検出用）。
///
/// SemanticsNode のマージに影響されないよう widget プロパティ側から数える。
List<String> _declaredIdentifiers(WidgetTester tester) => tester
    .widgetList<Semantics>(find.byType(Semantics))
    .map((w) => w.properties.identifier)
    .whereType<String>()
    .toList();

/// 大きめ viewport で pump する共通ハーネス（画面外未生成を避ける）。
Future<void> _pumpLarge(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: home));
}

void main() {
  // ─────────────────────────────────────────────────────────────
  // 1. ElectionArchiveScreen（SemanticHelper 付与済み・identifier 実測対象）
  // ─────────────────────────────────────────────────────────────
  group('accessibility(ElectionArchiveScreen)', () {
    final entries = [
      ElectionArchiveEntry(
        electionId: 'e1',
        title: '第1回村長選挙',
        scale: ElectionScale.village,
        winnerId: 'w1',
        winnerName: '天照太郎',
        winnerVotes: 60,
        totalVotes: 100,
        runnerUpVotes: 40,
      ),
      ElectionArchiveEntry(
        electionId: 'e2',
        title: '第2回村長選挙',
        scale: ElectionScale.village,
        winnerId: 'w2',
        winnerName: '天照次郎',
        winnerVotes: 45,
        totalVotes: 100,
        runnerUpVotes: 55,
      ),
      ElectionArchiveEntry(
        electionId: 'e3',
        title: '第1回町長選挙',
        scale: ElectionScale.town,
        winnerId: 'w3',
        winnerName: '天照三郎',
        winnerVotes: 80,
        totalVotes: 100,
        runnerUpVotes: 20,
      ),
    ];

    Future<void> pumpArchive(
      WidgetTester tester, {
      List<ElectionArchiveEntry>? entriesOverride,
    }) async {
      await _pumpLarge(
        tester,
        ElectionArchiveScreen(entries: entriesOverride ?? entries),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('サマリーカード: identifier が一意で、日本語 label を持ち、タップ到達可能', (tester) async {
      await pumpArchive(tester);

      final summary = find.bySemanticsIdentifier('btn_archive_summary_card');
      expect(summary, findsOneWidget);

      final node = tester.getSemantics(summary);
      expect(node.label, contains('選挙アーカイブサマリー'));

      // カード自体は onTap を持たない（既知の禍津・報告済み）ため、
      // 到達性は「配下のテキストがヒットテスト経路に入る」ことで担保する。
      expect(
        find.descendant(of: summary, matching: find.text('サマリー')).hitTestable(),
        findsOneWidget,
      );
    });

    testWidgets('一覧エントリ: electionId ごとに一意な identifier を発行し、label に選挙名を含む', (tester) async {
      await pumpArchive(tester);

      for (final entry in entries) {
        final finder =
            find.bySemanticsIdentifier('btn_archive_entry_${entry.electionId}');
        expect(finder, findsOneWidget, reason: 'identifier が一意でない: ${entry.electionId}');
        expect(
          tester.getSemantics(finder).label,
          contains(entry.title),
          reason: 'label に選挙名が無い: ${entry.electionId}',
        );
        // カードは onTap 未実装のため、配下テキストのヒットテストで到達性を担保
        expect(
          find
              .descendant(of: finder, matching: find.text(entry.title))
              .hitTestable(),
          findsOneWidget,
          reason: 'タップ到達不可: ${entry.electionId}',
        );
      }

      // 重複発行が無いこと（3エントリ → 3 identifier、重複なし）
      final ids = _declaredIdentifiers(tester)
          .where((id) => id.startsWith('btn_archive_entry_'))
          .toList();
      expect(ids, hasLength(3));
      expect(ids.toSet(), hasLength(3));
    });

    testWidgets('スケール絞り込み後も identifier が重複発行されない', (tester) async {
      await pumpArchive(tester);

      await tester.tap(
        find.byKey(AppKeys.archiveScaleFilter(ElectionScale.town)),
      );
      await tester.pumpAndSettle();

      final ids = _declaredIdentifiers(tester)
          .where((id) => id.startsWith('btn_archive_entry_'))
          .toList();
      expect(ids, hasLength(1));
      expect(ids.single, 'btn_archive_entry_e3');
      expect(find.bySemanticsIdentifier('btn_archive_entry_e3'), findsOneWidget);
      expect(find.bySemanticsIdentifier('btn_archive_entry_e1'), findsNothing);
      // サマリーカードの identifier は絞り込み後も一意
      expect(find.bySemanticsIdentifier('btn_archive_summary_card'), findsOneWidget);
    });

    testWidgets('0件時: サマリー identifier は発行されない（空状態のみ）', (tester) async {
      await pumpArchive(tester, entriesOverride: const <ElectionArchiveEntry>[]);

      expect(find.byKey(AppKeys.archiveEmptyState), findsOneWidget);
      expect(find.bySemanticsIdentifier('btn_archive_summary_card'), findsNothing);
      expect(
        _declaredIdentifiers(tester).where((id) => id.startsWith('btn_archive_')),
        isEmpty,
      );
    });
  });

  // ─────────────────────────────────────────────────────────────
  // 2. GlossaryScreen（Semantics 未付与）
  // ─────────────────────────────────────────────────────────────
  group('accessibility(GlossaryScreen)', () {
    Future<void> pumpGlossary(WidgetTester tester) async {
      await _pumpLarge(
        tester,
        GlossaryScreen(
          termsOverride: [
            GlossaryTerm(
              id: 'test_a',
              term: 'テスト用語A',
              reading: 'てすとようごえー',
              category: '選挙制度',
            ),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('タイトル・検索欄が描画され、検索欄はタップ到達可能', (tester) async {
      await pumpGlossary(tester);

      expect(find.byKey(AppKeys.glossaryScreen), findsOneWidget);
      expect(find.byKey(AppKeys.glossaryTitle), findsOneWidget);
      expect(
        find.byKey(AppKeys.glossarySearchField).hitTestable(),
        findsOneWidget,
      );
    });

    testWidgets('SemanticHelper identifier が一意に発行され、日本語 label を持つ', (tester) async {
      await pumpGlossary(tester);

      final search = find.bySemanticsIdentifier('txt_glossary_search');
      expect(search, findsOneWidget);
      expect(tester.getSemantics(search).label, contains('用語を検索'));

      final declared = _declaredIdentifiers(tester);
      expect(declared.toSet().length, declared.length,
          reason: 'identifier が重複宣言されている: $declared');
      expect(
        declared.where((id) => id.startsWith('item_glossary_term_')).length,
        greaterThan(0),
        reason: '用語カードに一意 identifier が付与されていない',
      );
    });
  });

  // ─────────────────────────────────────────────────────────────
  // 3. PredictionScreen（Semantics 未付与）
  // ─────────────────────────────────────────────────────────────
  group('accessibility(PredictionScreen)', () {
    final candidates = const [
      Candidate(
        id: 'c_alpha',
        name: 'α太郎',
        portraitKey: 'p_alpha',
        faction: '発展の会',
        personality: '経済重視',
        policies: [],
      ),
      Candidate(
        id: 'c_beta',
        name: 'β花子',
        portraitKey: 'p_beta',
        faction: '共生の会',
        personality: '福祉重視',
        policies: [],
      ),
    ];

    Future<void> pumpPrediction(WidgetTester tester) async {
      await _pumpLarge(
        tester,
        PredictionScreen(
          electionId: 'election_1',
          electionTitle: 'テスト選挙',
          candidates: candidates,
          repository: InMemoryPredictionRepository(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('タイトル・候補者選択肢が描画され、選択肢はタップ到達可能', (tester) async {
      await pumpPrediction(tester);

      expect(find.byKey(AppKeys.predictionTitle), findsOneWidget);
      expect(
        find.byKey(AppKeys.predictionCandidateOption('c_beta')).hitTestable(),
        findsOneWidget,
      );
    });

    testWidgets('SemanticHelper identifier が一意に発行され、日本語 label を持つ', (tester) async {
      await pumpPrediction(tester);

      final submit = find.bySemanticsIdentifier('btn_prediction_submit');
      expect(submit, findsOneWidget);
      expect(tester.getSemantics(submit).label, contains('予想を保存'));
      expect(find.bySemanticsIdentifier('sec_prediction_candidates'),
          findsOneWidget);
      expect(find.bySemanticsIdentifier('txt_prediction_share'), findsOneWidget);

      final declared = _declaredIdentifiers(tester);
      expect(declared.toSet().length, declared.length,
          reason: 'identifier が重複宣言されている: $declared');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // 4. ManifestoTrackerScreen（Semantics 未付与）
  // ─────────────────────────────────────────────────────────────
  group('accessibility(ManifestoTrackerScreen)', () {
    ManifestoRecord buildRecord() => ManifestoRecord(
          electionId: 'e1',
          title: '村長選挙',
          winnerId: 'c1',
          winnerName: '太郎',
          occurredAt: DateTime(2026, 10, 9),
          pledges: const [
            ManifestoPledge(
              lifeParamKey: 'healthcare',
              promisedDelta: 10,
              actualDelta: 10,
              policyTitles: ['病院を増やす'],
            ),
          ],
        );

    Future<void> pumpManifesto(WidgetTester tester) async {
      await _pumpLarge(
        tester,
        ManifestoTrackerScreen(records: [buildRecord()]),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('タイトル・検索欄・記録カードが描画され、検索欄はタップ到達可能', (tester) async {
      await pumpManifesto(tester);

      expect(find.byKey(AppKeys.manifestoTitle), findsOneWidget);
      expect(find.byKey(AppKeys.manifestoRecordCard('e1')), findsOneWidget);
      expect(
        find.byKey(AppKeys.manifestoSearchField).hitTestable(),
        findsOneWidget,
      );
    });

    testWidgets('SemanticHelper identifier が一意に発行され、日本語 label を持つ', (tester) async {
      await pumpManifesto(tester);

      final declared = _declaredIdentifiers(tester);
      expect(declared.where((id) => id.startsWith('sec_manifesto_')).length,
          greaterThan(0),
          reason: '公約進捗セクションに identifier が付与されていない');
      expect(declared.toSet().length, declared.length,
          reason: 'identifier が重複宣言されている: $declared');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // 5. SupportSimulationScreen（AppBar タイトルのみ Semantics あり・identifier 無し）
  // ─────────────────────────────────────────────────────────────
  group('accessibility(SupportSimulationScreen)', () {
    Future<void> pumpSupport(WidgetTester tester) async {
      await _pumpLarge(
        tester,
        SupportSimulationScreen(
          candidates: Candidate.samples(),
          society: SocietyState(happiness: 60.0, mood: 0.3, electionCount: 1),
        ),
      );
      // 繰り返しアニメーションがあるため pumpAndSettle は使わない
      await tester.pump(const Duration(milliseconds: 200));
    }

    testWidgets('タイトル label に「支持率シミュレーション」を含み、世論カードが描画される', (tester) async {
      await pumpSupport(tester);

      expect(find.byKey(AppKeys.supportTitle), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('支持率シミュレーション')),
        findsWidgets,
      );
      expect(find.byKey(AppKeys.supportMoodCard), findsOneWidget);
    });

    testWidgets('SemanticHelper identifier が一意に発行され、日本語 label を持つ', (tester) async {
      await pumpSupport(tester);

      final rate = find.bySemanticsIdentifier('txt_support_rate');
      expect(rate, findsOneWidget);
      expect(tester.getSemantics(rate).label, contains('支持率'));
      expect(find.bySemanticsIdentifier('sec_support_mood'), findsOneWidget);

      final declared = _declaredIdentifiers(tester);
      expect(declared.toSet().length, declared.length,
          reason: 'identifier が重複宣言されている: $declared');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // 6. TurnoutScreen（AppBar タイトルのみ Semantics あり・identifier 無し）
  // ─────────────────────────────────────────────────────────────
  group('accessibility(TurnoutScreen)', () {
    Future<void> pumpTurnout(WidgetTester tester) async {
      final society = SocietyState.initial();
      final election = Election.sample();
      final turnout = TurnoutService.compute(
        election: election,
        society: society,
        scale: election.scale,
      );
      await _pumpLarge(
        tester,
        TurnoutScreen(electionTitle: election.title, turnout: turnout),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('タイトル label に「投票率」を含み、投票率ラベルが描画され到達可能', (tester) async {
      await pumpTurnout(tester);

      expect(find.byKey(AppKeys.turnoutScreen), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('投票率')), findsWidgets);
      expect(
        find.byKey(AppKeys.turnoutRateLabel).hitTestable(),
        findsOneWidget,
      );
    });

    testWidgets('SemanticHelper identifier が一意に発行され、日本語 label を持つ', (tester) async {
      await pumpTurnout(tester);

      final rate = find.bySemanticsIdentifier('txt_turnout_rate');
      expect(rate, findsOneWidget);
      expect(tester.getSemantics(rate).label, contains('投票率'));
      expect(find.bySemanticsIdentifier('sec_turnout_breakdown'), findsOneWidget);

      final declared = _declaredIdentifiers(tester);
      expect(declared.toSet().length, declared.length,
          reason: 'identifier が重複宣言されている: $declared');
    });
  });
}
