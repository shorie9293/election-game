import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/domain/models/support_timeline.dart';

void main() {
  final baseTime = DateTime.utc(2026, 10, 24, 12, 0);

  SupportTimelineEntry entry({
    String id = 'support_1',
    DateTime? recordedAt,
    String electionTitle = '第1回 模擬選挙',
    String leaderCandidateId = 'cand_a',
    String leaderCandidateName = '候補者A',
    double leaderSupportRate = 0.425,
    int voterCount = 10,
    String moodLabel = '穏やかな世論',
  }) {
    return SupportTimelineEntry(
      id: id,
      recordedAt: recordedAt ?? baseTime,
      electionTitle: electionTitle,
      leaderCandidateId: leaderCandidateId,
      leaderCandidateName: leaderCandidateName,
      leaderSupportRate: leaderSupportRate,
      voterCount: voterCount,
      moodLabel: moodLabel,
    );
  }

  group('SupportTimelineEntry', () {
    test('正常値で生成でき、全フィールドを保持する', () {
      final e = entry();
      expect(e.id, 'support_1');
      expect(e.recordedAt, baseTime);
      expect(e.electionTitle, '第1回 模擬選挙');
      expect(e.leaderCandidateId, 'cand_a');
      expect(e.leaderCandidateName, '候補者A');
      expect(e.leaderSupportRate, 0.425);
      expect(e.voterCount, 10);
      expect(e.moodLabel, '穏やかな世論');
    });

    test('id が空文字なら ArgumentError', () {
      expect(() => entry(id: ''), throwsArgumentError);
    });

    test('electionTitle が空文字なら ArgumentError', () {
      expect(() => entry(electionTitle: ''), throwsArgumentError);
    });

    test('leaderCandidateId が空文字なら ArgumentError', () {
      expect(() => entry(leaderCandidateId: ''), throwsArgumentError);
    });

    test('leaderCandidateName が空文字なら ArgumentError', () {
      expect(() => entry(leaderCandidateName: ''), throwsArgumentError);
    });

    test('leaderSupportRate は 0.0 / 1.0 の境界を含む', () {
      expect(entry(leaderSupportRate: 0.0).leaderSupportRate, 0.0);
      expect(entry(leaderSupportRate: 1.0).leaderSupportRate, 1.0);
    });

    test('leaderSupportRate が範囲外なら ArgumentError', () {
      expect(() => entry(leaderSupportRate: -0.1), throwsArgumentError);
      expect(() => entry(leaderSupportRate: 1.1), throwsArgumentError);
    });

    test('voterCount は 0 を許容し、負値は ArgumentError', () {
      expect(entry(voterCount: 0).voterCount, 0);
      expect(() => entry(voterCount: -1), throwsArgumentError);
    });

    test('leaderShareLabel は小数1桁のパーセント表記', () {
      expect(entry(leaderSupportRate: 0.425).leaderShareLabel, '42.5%');
      expect(entry(leaderSupportRate: 0.0).leaderShareLabel, '0.0%');
      expect(entry(leaderSupportRate: 1.0).leaderShareLabel, '100.0%');
    });

    test('toJson / fromJson の往復で等価になる', () {
      final e = entry();
      final restored = SupportTimelineEntry.fromJson(e.toJson());
      expect(restored, e);
      expect(restored.recordedAt.isUtc, isTrue);
    });

    test('fromJson は num の支持率を double へ変換する', () {
      final restored = SupportTimelineEntry.fromJson({
        'id': 'support_2',
        'recordedAt': baseTime.toIso8601String(),
        'electionTitle': '選挙',
        'leaderCandidateId': 'cand_b',
        'leaderCandidateName': '候補者B',
        'leaderSupportRate': 1,
        'voterCount': 3,
        'moodLabel': '静穏',
      });
      expect(restored.leaderSupportRate, 1.0);
      expect(restored.leaderSupportRate, isA<double>());
    });

    test('fromJson は型不一致を FormatException にする', () {
      expect(
        () => SupportTimelineEntry.fromJson(const {'id': 1}),
        throwsFormatException,
      );
      expect(
        () => SupportTimelineEntry.fromJson({
          'id': 'support_1',
          'recordedAt': baseTime.toIso8601String(),
          'electionTitle': '選挙',
          'leaderCandidateId': 'cand_a',
          'leaderCandidateName': '候補者A',
          'leaderSupportRate': '0.5',
          'voterCount': 10,
          'moodLabel': '静穏',
        }),
        throwsFormatException,
      );
      expect(
        () => SupportTimelineEntry.fromJson({
          'id': 'support_1',
          'recordedAt': baseTime.toIso8601String(),
          'electionTitle': '選挙',
          'leaderCandidateId': 'cand_a',
          'leaderCandidateName': '候補者A',
          'leaderSupportRate': 0.5,
          'voterCount': 1.5,
          'moodLabel': '静穏',
        }),
        throwsFormatException,
      );
    });

    test('fromJson は ISO8601 でない recordedAt を FormatException にする', () {
      expect(
        () => SupportTimelineEntry.fromJson({
          'id': 'support_1',
          'recordedAt': 'not-a-date',
          'electionTitle': '選挙',
          'leaderCandidateId': 'cand_a',
          'leaderCandidateName': '候補者A',
          'leaderSupportRate': 0.5,
          'voterCount': 10,
          'moodLabel': '静穏',
        }),
        throwsFormatException,
      );
    });
  });

  group('SupportTimelineDelta', () {
    test('leaderChanged でない場合 leaderChangeLabel は空文字', () {
      const d = SupportTimelineDelta(
        entryId: 'e2',
        previousEntryId: 'e1',
        leaderChanged: false,
        shareDelta: 0.01,
        leaderChangeLabel: '',
      );
      expect(d.leaderChangeLabel, '');
    });

    test('leaderChanged の場合 leaderChangeLabel は「首位交代」', () {
      const d = SupportTimelineDelta(
        entryId: 'e2',
        previousEntryId: 'e1',
        leaderChanged: true,
        shareDelta: -0.02,
        leaderChangeLabel: '首位交代',
      );
      expect(d.leaderChangeLabel, '首位交代');
    });

    test('deltaLabel は符号付き pt 表記', () {
      SupportTimelineDelta d(double v) => SupportTimelineDelta(
            entryId: 'e2',
            previousEntryId: 'e1',
            leaderChanged: false,
            shareDelta: v,
            leaderChangeLabel: '',
          );
      expect(d(0.023).deltaLabel, '+2.3pt');
      expect(d(-0.010).deltaLabel, '-1.0pt');
      expect(d(0.0001).deltaLabel, '±0.0pt');
      expect(d(0.0).deltaLabel, '±0.0pt');
    });

    test('equatable により同値は等しい', () {
      const a = SupportTimelineDelta(
        entryId: 'e2',
        previousEntryId: null,
        leaderChanged: false,
        shareDelta: 0.0,
        leaderChangeLabel: '',
      );
      const b = SupportTimelineDelta(
        entryId: 'e2',
        previousEntryId: null,
        leaderChanged: false,
        shareDelta: 0.0,
        leaderChangeLabel: '',
      );
      expect(a, b);
    });
  });
}
