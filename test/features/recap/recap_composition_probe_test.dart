import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/election_archive.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/models/turnout_snapshot.dart';
import 'package:election_game/domain/services/election_recap_service.dart';
import 'package:election_game/features/recap/presentation/election_recap_screen.dart';

/// 親探針: 子の個別試練では撃たれない『合成の不変条件』を撃つ。
///
/// - 画面→（copyHandler なし時）→ 実 Clipboard チャネルへ到達するか
///   （state だけ更新して永続化/外部系に届かない型を撃つ）
/// - 画面表示テキストが ElectionRecapService.build の text と完全一致するか
///   （画面側が独自整形して二重定義になっていないか）
/// - turnoutsByElectionId が build に合流しテキストへ反映されるか
ElectionArchiveEntry _entry({
  required String id,
  required String title,
  required int winner,
  required int total,
  required int runnerUp,
}) {
  return ElectionArchiveEntry(
    electionId: id,
    title: title,
    scale: ElectionScale.village,
    winnerId: 'w',
    winnerName: '太郎',
    winnerVotes: winner,
    totalVotes: total,
    runnerUpVotes: runnerUp,
    occurredAt: DateTime(2026, 10, 4),
  );
}

TurnoutSnapshot _turnout() {
  return TurnoutSnapshot(
    electionTitle: '天照村長選',
    scale: ElectionScale.village,
    jobBreakdown: [
      JobTurnout(job: Job.farmer, eligible: 100, voted: 70),
    ],
  );
}

void main() {
  testWidgets('親探針: copyHandler 未指定時は実 Clipboard.setData チャネルへ到達する', (tester) async {
    final entry = _entry(
      id: 'election_1',
      title: '天照村長選',
      winner: 70,
      total: 100,
      runnerUp: 30,
    );
    final expected = ElectionRecapService.build(entry).text;

    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: ElectionRecapScreen(entries: [entry]),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(AppKeys.recapCopyButton));
    await tester.pumpAndSettle();

    final setData = calls.where((c) => c.method == 'Clipboard.setData').toList();
    expect(setData, isNotEmpty,
        reason: 'コピー押下が実 Clipboard チャネルに到達していない');
    expect((setData.first.arguments as Map)['text'], expected,
        reason: 'クリップボードへ渡った文字列が build の text と不一致');
  });

  testWidgets('親探針: 画面表示テキストは build の text と完全一致（独自整形なし）', (tester) async {
    final entry = _entry(
      id: 'election_1',
      title: '天照村長選',
      winner: 70,
      total: 100,
      runnerUp: 30,
    );
    final expected = ElectionRecapService.build(entry).text;

    await tester.pumpWidget(
      MaterialApp(home: ElectionRecapScreen(entries: [entry])),
    );
    await tester.pumpAndSettle();

    final text = tester.widget<SelectableText>(
      find.byKey(AppKeys.recapText),
    );
    expect(text.data, expected);
  });

  testWidgets('親探針: turnoutsByElectionId が合流し投票率がテキストに反映される', (tester) async {
    final entry = _entry(
      id: 'election_1',
      title: '天照村長選',
      winner: 70,
      total: 100,
      runnerUp: 30,
    );
    final turnout = _turnout();
    final expected =
        ElectionRecapService.build(entry, turnout: turnout).text;
    expect(expected.contains('70.0%'), isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: ElectionRecapScreen(
          entries: [entry],
          turnoutsByElectionId: {'election_1': turnout},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final text = tester.widget<SelectableText>(find.byKey(AppKeys.recapText));
    expect(text.data, expected);
    expect(text.data!.contains('70.0%'), isTrue,
        reason: '投票率スナップショットが画面テキストに合流していない');
    expect(text.data!.contains('選挙の振り返り') , isFalse); // 画面タイトル混入なし（健全性の確証）
  });
}
