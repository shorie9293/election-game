import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/features/share/domain/election_share_card_data.dart';

ElectionShareCardData _data({
  String electionId = 'e1',
  String title = '第1回町長選挙',
  String winnerName = '天照太郎',
  int winnerVotes = 60,
  int totalVotes = 100,
  int runnerUpVotes = 40,
  String scaleLabel = '町',
  double? turnoutRate,
  String? turnoutLabel,
  DateTime? occurredAt,
  DateTime? generatedAt,
}) {
  return ElectionShareCardData(
    electionId: electionId,
    title: title,
    winnerName: winnerName,
    winnerVotes: winnerVotes,
    totalVotes: totalVotes,
    runnerUpVotes: runnerUpVotes,
    scaleLabel: scaleLabel,
    turnoutRate: turnoutRate,
    turnoutLabel: turnoutLabel,
    occurredAt: occurredAt,
    generatedAt: generatedAt ?? DateTime(2026, 10, 16),
  );
}

void main() {
  group('ElectionShareCardData 派生ラベル', () {
    test('得票率・得票差・スケールのラベルを組む', () {
      final d = _data();
      expect(d.winnerShare, closeTo(0.6, 1e-9));
      expect(d.sharePercentLabel, '60.0%');
      expect(d.margin, 20);
      expect(d.marginLabel, '20票差');
      expect(d.isLandslide, isTrue);
      expect(d.headline, '【第1回町長選挙】当選: 天照太郎');
    });

    test('総投票0なら得票率0.0で0除算しない', () {
      final d = _data(winnerVotes: 0, totalVotes: 0, runnerUpVotes: 0);
      expect(d.winnerShare, 0.0);
      expect(d.sharePercentLabel, '0.0%');
      expect(d.isLandslide, isFalse);
    });

    test('得票率60%未満は圧勝ではない', () {
      final d = _data(winnerVotes: 59, totalVotes: 100, runnerUpVotes: 41);
      expect(d.isLandslide, isFalse);
    });

    test('投票率が無いときは — を返す', () {
      final d = _data();
      expect(d.hasTurnout, isFalse);
      expect(d.turnoutPercentLabel, '—');
      expect(d.lines.any((l) => l == '投票率: —'), isTrue);
    });

    test('投票率があるときは率と関心ラベルを返す', () {
      final d = _data(turnoutRate: 0.624, turnoutLabel: '高い関心');
      expect(d.hasTurnout, isTrue);
      expect(d.turnoutPercentLabel, '62.4%');
      expect(d.lines.any((l) => l == '投票率: 62.4%（高い関心）'), isTrue);
    });

    test('実施日はゼロ埋め・null は 日付不明', () {
      expect(_data(occurredAt: DateTime(2026, 1, 2)).dateLabel, '2026/01/02');
      expect(_data().dateLabel, '日付不明');
    });

    test('lines は実施日と規模を含み shareText は見出し行で始まる', () {
      final d = _data(occurredAt: DateTime(2026, 3, 4));
      expect(d.lines.contains('規模: 町'), isTrue);
      expect(d.lines.contains('実施日: 2026/03/04'), isTrue);
      expect(d.shareText.startsWith('🗳️ 選挙の歩み'), isTrue);
      expect(d.shareText.contains(d.headline), isTrue);
      expect(d.generatedDateLabel, '2026/10/16');
    });
  });

  group('ElectionShareCardData 不変条件', () {
    test('title 空文字は ArgumentError', () {
      expect(() => _data(title: ''), throwsArgumentError);
    });

    test('winnerName 空文字は ArgumentError', () {
      expect(() => _data(winnerName: ''), throwsArgumentError);
    });

    test('負の票数は ArgumentError', () {
      expect(() => _data(winnerVotes: -1), throwsArgumentError);
      expect(() => _data(totalVotes: -1), throwsArgumentError);
      expect(() => _data(runnerUpVotes: -1), throwsArgumentError);
    });

    test('投票率の範囲外は ArgumentError', () {
      expect(() => _data(turnoutRate: -0.1, turnoutLabel: '低い関心'),
          throwsArgumentError);
      expect(() => _data(turnoutRate: 1.1, turnoutLabel: '高い関心'),
          throwsArgumentError);
    });

    test('turnoutRate なしに turnoutLabel は指定できない', () {
      expect(() => _data(turnoutLabel: '高い関心'), throwsArgumentError);
    });
  });

  test('等価性は全フィールドで判定する', () {
    expect(_data(), equals(_data()));
    expect(_data().hashCode, equals(_data().hashCode));
    expect(_data(), isNot(equals(_data(title: '別の選挙'))));
  });
}
