import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/election_archive.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/models/turnout_snapshot.dart';
import 'package:election_game/features/share/domain/election_share_card_service.dart';
import 'package:election_game/features/share/presentation/election_share_card_capture.dart';
import 'package:election_game/features/share/presentation/election_share_card_exporter.dart';
import 'package:election_game/features/share/presentation/election_share_card_screen.dart';

class _FakeExporter implements ElectionShareCardExporter {
  int calls = 0;
  Uint8List? lastImage;
  String? lastText;
  bool result = true;

  @override
  Future<bool> share({Uint8List? image, required String text}) async {
    calls++;
    lastImage = image;
    lastText = text;
    return result;
  }
}

class _FakeCapture implements ElectionShareCardCapture {
  Uint8List? bytes;
  GlobalKey? lastKey;
  int calls = 0;

  @override
  Future<Uint8List?> capture(GlobalKey boundaryKey) async {
    calls++;
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

void main() {
  testWidgets('エントリが無いときは空状態を表示する', (tester) async {
    await _pump(tester, entries: const []);
    expect(find.byKey(AppKeys.shareCardEmpty), findsOneWidget);
    expect(find.byKey(AppKeys.shareCardPreview), findsNothing);
  });

  testWidgets('カードに当選者・得票率・規模・実施日が描かれる', (tester) async {
    await _pump(
      tester,
      entries: [_entry(id: 'e1', title: '第1回村長選挙', occurredAt: DateTime(2026, 1, 2))],
    );
    expect(find.byKey(AppKeys.shareCardPreview), findsOneWidget);
    expect(find.byKey(AppKeys.shareCardHeadline), findsOneWidget);
    expect(find.text('【第1回村長選挙】当選: 天照太郎'), findsOneWidget);
    expect(find.text('得票率: 60.0%（60票 / 総投票 100票）'), findsOneWidget);
    expect(find.text('規模: 村'), findsOneWidget);
    expect(find.text('実施日: 2026/01/02'), findsOneWidget);
  });

  testWidgets('テキスト共有はサービス整形の shareText をそのまま渡す', (tester) async {
    final exporter = _FakeExporter();
    await _pump(
      tester,
      entries: [_entry(id: 'e1', title: '第1回村長選挙')],
      exporter: exporter,
    );
    await tester.tap(find.byKey(AppKeys.shareCardTextShareButton));
    await tester.pumpAndSettle();

    expect(exporter.calls, 1);
    expect(exporter.lastImage, isNull);
    final expected = ElectionShareCardService.build(
      entry: _entry(id: 'e1', title: '第1回村長選挙'),
      generatedAt: DateTime(2026, 10, 16),
    ).shareText;
    expect(exporter.lastText, expected);
  });

  testWidgets('画像共有は capture のバイト列を同一のまま渡す', (tester) async {
    final exporter = _FakeExporter();
    final capture = _FakeCapture()..bytes = Uint8List.fromList([1, 2, 3, 4]);
    await _pump(
      tester,
      entries: [_entry(id: 'e1', title: '第1回村長選挙')],
      capture: capture,
      exporter: exporter,
    );
    await tester.tap(find.byKey(AppKeys.shareCardImageShareButton));
    await tester.pumpAndSettle();

    expect(capture.calls, 1);
    expect(capture.lastKey, isNotNull);
    expect(exporter.lastImage, equals([1, 2, 3, 4]));
  });

  testWidgets('capture 未注入なら画像共有ボタンは無効', (tester) async {
    final exporter = _FakeExporter();
    await _pump(
      tester,
      entries: [_entry(id: 'e1', title: '第1回村長選挙')],
      exporter: exporter,
    );
    final button = tester.widget<FilledButton>(
      find.byKey(AppKeys.shareCardImageShareButton),
    );
    expect(button.onPressed, isNull);

    await tester.tap(find.byKey(AppKeys.shareCardImageShareButton));
    await tester.pumpAndSettle();
    expect(exporter.calls, 0);
  });

  testWidgets('複数エントリでは選択した選挙のカードへ切り替わる', (tester) async {
    await _pump(
      tester,
      entries: [
        _entry(id: 'e1', title: '第1回村長選挙', winner: 80, total: 100, runnerUp: 20),
        _entry(id: 'e2', title: '第2回村長選挙', winner: 55, total: 100, runnerUp: 45),
      ],
    );
    expect(find.byKey(AppKeys.shareCardSelector), findsOneWidget);
    // 既定は末尾（最新）
    expect(find.text('【第2回村長選挙】当選: 天照太郎'), findsOneWidget);

    await tester.tap(find.byKey(AppKeys.shareCardSelector));
    await tester.pumpAndSettle();
    await tester.tap(find.text('第1回村長選挙（村）').last);
    await tester.pumpAndSettle();

    expect(find.text('【第1回村長選挙】当選: 天照太郎'), findsOneWidget);
    expect(find.text('2位との差: 60票差（圧勝）'), findsOneWidget);
  });
}
