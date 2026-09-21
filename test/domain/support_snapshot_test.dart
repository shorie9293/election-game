import 'package:election_game/domain/models/support_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SupportSnapshot 検証', () {
    test('空 candidateId は ArgumentError を throw する', () {
      expect(
        () => SupportSnapshot(
          candidateId: '',
          candidateName: '山田',
          supportRate: 0.5,
          rawAffinity: 0.5,
          supporterCount: 1,
        ),
        throwsArgumentError,
      );
    });

    test('範囲外 supportRate（-0.1）は ArgumentError を throw する', () {
      expect(
        () => SupportSnapshot(
          candidateId: 'c1',
          candidateName: '山田',
          supportRate: -0.1,
          rawAffinity: 0.5,
          supporterCount: 1,
        ),
        throwsArgumentError,
      );
    });

    test('範囲外 supportRate（1.1）は ArgumentError を throw する', () {
      expect(
        () => SupportSnapshot(
          candidateId: 'c1',
          candidateName: '山田',
          supportRate: 1.1,
          rawAffinity: 0.5,
          supporterCount: 1,
        ),
        throwsArgumentError,
      );
    });

    test('範囲外 rawAffinity（-0.1）は ArgumentError を throw する', () {
      expect(
        () => SupportSnapshot(
          candidateId: 'c1',
          candidateName: '山田',
          supportRate: 0.5,
          rawAffinity: -0.1,
          supporterCount: 1,
        ),
        throwsArgumentError,
      );
    });

    test('範囲外 rawAffinity（1.5）は ArgumentError を throw する', () {
      expect(
        () => SupportSnapshot(
          candidateId: 'c1',
          candidateName: '山田',
          supportRate: 0.5,
          rawAffinity: 1.5,
          supporterCount: 1,
        ),
        throwsArgumentError,
      );
    });

    test('負の supporterCount は ArgumentError を throw する', () {
      expect(
        () => SupportSnapshot(
          candidateId: 'c1',
          candidateName: '山田',
          supportRate: 0.5,
          rawAffinity: 0.5,
          supporterCount: -1,
        ),
        throwsArgumentError,
      );
    });

    test('正常値は生成できる', () {
      final s = SupportSnapshot(
        candidateId: 'c1',
        candidateName: '山田',
        supportRate: 0.5,
        rawAffinity: 0.5,
        supporterCount: 3,
      );
      expect(s.candidateId, 'c1');
      expect(s.candidateName, '山田');
      expect(s.supportRate, 0.5);
      expect(s.rawAffinity, 0.5);
      expect(s.supporterCount, 3);
    });
  });

  group('supportPercentLabel 書式', () {
    test('0.425 → 42.5%', () {
      expect(
        SupportSnapshot(
          candidateId: 'c1',
          candidateName: '山田',
          supportRate: 0.425,
          rawAffinity: 0.5,
          supporterCount: 1,
        ).supportPercentLabel,
        '42.5%',
      );
    });

    test('1.0 → 100.0%', () {
      expect(
        SupportSnapshot(
          candidateId: 'c1',
          candidateName: '山田',
          supportRate: 1.0,
          rawAffinity: 0.5,
          supporterCount: 1,
        ).supportPercentLabel,
        '100.0%',
      );
    });

    test('0.0 → 0.0%', () {
      expect(
        SupportSnapshot(
          candidateId: 'c1',
          candidateName: '山田',
          supportRate: 0.0,
          rawAffinity: 0.5,
          supporterCount: 0,
        ).supportPercentLabel,
        '0.0%',
      );
    });
  });

  group('copyWith / props', () {
    test('copyWith で指定フィールドのみ変わる', () {
      final base = SupportSnapshot(
        candidateId: 'c1',
        candidateName: '山田',
        supportRate: 0.5,
        rawAffinity: 0.5,
        supporterCount: 3,
      );
      final updated = base.copyWith(supportRate: 0.75, supporterCount: 7);
      expect(updated.supportRate, 0.75);
      expect(updated.supporterCount, 7);
      expect(updated.candidateId, 'c1');
      expect(updated.candidateName, '山田');
      expect(updated.rawAffinity, 0.5);
    });

    test('同じフィールド値なら等価（Equatable）', () {
      final a = SupportSnapshot(
        candidateId: 'c1',
        candidateName: '山田',
        supportRate: 0.5,
        rawAffinity: 0.5,
        supporterCount: 3,
      );
      final b = SupportSnapshot(
        candidateId: 'c1',
        candidateName: '山田',
        supportRate: 0.5,
        rawAffinity: 0.5,
        supporterCount: 3,
      );
      expect(a, equals(b));
    });
  });
}
