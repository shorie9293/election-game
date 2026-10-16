import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/election_archive.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/models/turnout_snapshot.dart';
import 'package:election_game/features/share/domain/election_share_card_service.dart';
import 'package:election_game/features/share/presentation/election_share_card_capture.dart';
import 'package:election_game/features/share/presentation/election_share_card_exporter.dart';
import 'package:election_game/features/share/presentation/election_share_card_screen.dart';

/// 親探針: 子の個別試練では撃たれない『合成の不変条件』を撃つ。
///
/// - 画面に渡る共有テキストが ElectionShareCardService.build の出力と完全一致するか
///   （画面側が独自整形し二重定義になっていないか）
/// - capture に渡る境界キーが実プレビューの RepaintBoundary か
/// - 選択切替が「最新」ではなく「選んだ選挙」のデータを共有へ流すか
/// - turnoutsByElectionId が build に合流しテキストへ反映されるか
/// - capture が null を返しても落ちず、テキストのみの共有へ退避するか
class _RecordingExporter implements ElectionShareCardExporter {
  final List<({Uint8List? image, String text})> calls = [];

  @override
  Future<bool> share({Uint8List? image, required String text}) async {
    calls.add((image: image, text: text));
    return true;
  }
}

class _StaticCapture implements ElectionShareCardCapture {
  _StaticCapture(this.bytes);

  final Uint8List? bytes;
  GlobalKey? lastKey;

  @override
  Future<Uint8List?> capture(GlobalKey boundaryKey) async {
    lastKey = boundaryKey;
    return bytes;
  }
}

ElectionArchiveEntry _entry({
  required String id,
  required String title,
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

Future<void> _pump(
  WidgetTester tester, {
  required List<ElectionArchiveEntry> entries,
  Map<String, TurnoutSnapshot> turnouts = const {},
  ElectionShareCardCapture? capture,
  ElectionShareCardExporter? exporter,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ElectionShareCardScreen(
        entries: entries,
        turnoutsByElectionId: turnouts,
        now: () => DateTime(2026, 10, 16),
        capture: capture,
        exporter: exporter,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

TurnoutSnapshot _turnout() => TurnoutSnapshot(
      electionTitle: '第1回村長選挙',
      scale: ElectionScale.village,
      jobBreakdown: [
        JobTurnout(job: Job.farmer, eligible: 100, voted: 62),
      ],
    );

void main() {
  testWidgets('画面→サービス→エクスポータのテキストが完全一致する（二重整形の不在）',
      (tester) async {
    final exporter = _RecordingExporter();
    final entries = [_entry(id: 'e1', title: '第1回村長選挙', occurredAt: DateTime(2026, 1, 2))];
    await _pump(tester, entries: entries, exporter: exporter);

    await tester.tap(find.byKey(AppKeys.shareCardTextShareButton));
    await tester.pumpAndSettle();

    final expected = ElectionShareCardService.build(
      entry: entries.single,
      generatedAt: DateTime(2026, 10, 16),
    ).shareText;
    expect(exporter.calls.single.text, expected);
  });

  testWidgets('capture に渡る境界キーは実プレビューの RepaintBoundary である', (tester) async {
    final capture = _StaticCapture(Uint8List.fromList([9, 8, 7]));
    await _pump(
      tester,
      entries: [_entry(id: 'e1', title: '第1回村長選挙')],
      capture: capture,
      exporter: _RecordingExporter(),
    );

    await tester.tap(find.byKey(AppKeys.shareCardImageShareButton));
    await tester.pumpAndSettle();

    final renderObject = capture.lastKey!.currentContext!.findRenderObject();
    expect(renderObject, isA<RenderRepaintBoundary>());
  });

  testWidgets('選択切替は「最新」ではなく「選んだ選挙」のデータを共有へ流す', (tester) async {
    final exporter = _RecordingExporter();
    await _pump(
      tester,
      entries: [
        _entry(id: 'e1', title: '第1回村長選挙', winner: 80, total: 100, runnerUp: 20),
        _entry(id: 'e2', title: '第2回村長選挙', winner: 55, total: 100, runnerUp: 45),
      ],
      exporter: exporter,
    );

    await tester.tap(find.byKey(AppKeys.shareCardSelector));
    await tester.pumpAndSettle();
    await tester.tap(find.text('第1回村長選挙（村）').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AppKeys.shareCardTextShareButton));
    await tester.pumpAndSettle();

    final expected = ElectionShareCardService.build(
      entry: _entry(id: 'e1', title: '第1回村長選挙', winner: 80, total: 100, runnerUp: 20),
      generatedAt: DateTime(2026, 10, 16),
    ).shareText;
    expect(exporter.calls.single.text, expected);
    expect(exporter.calls.single.text.contains('第1回村長選挙'), isTrue);
    expect(exporter.calls.single.text.contains('第2回村長選挙'), isFalse);
  });

  testWidgets('投票率スナップショットがカードと共有テキストへ合流する', (tester) async {
    final exporter = _RecordingExporter();
    final entries = [_entry(id: 'e1', title: '第1回村長選挙')];
    await _pump(
      tester,
      entries: entries,
      turnouts: {'e1': _turnout()},
      exporter: exporter,
    );

    expect(find.text('投票率: 62.0%（高い関心）'), findsOneWidget);
    await tester.tap(find.byKey(AppKeys.shareCardTextShareButton));
    await tester.pumpAndSettle();
    expect(exporter.calls.single.text.contains('投票率: 62.0%（高い関心）'), isTrue);
  });

  testWidgets('capture が null を返しても落ちずテキストのみの共有へ退避する', (tester) async {
    final exporter = _RecordingExporter();
    final capture = _StaticCapture(null);
    await _pump(
      tester,
      entries: [_entry(id: 'e1', title: '第1回村長選挙')],
      capture: capture,
      exporter: exporter,
    );

    await tester.tap(find.byKey(AppKeys.shareCardImageShareButton));
    await tester.pumpAndSettle();

    expect(exporter.calls.single.image, isNull);
    expect(exporter.calls.single.text.isNotEmpty, isTrue);
  });
}
