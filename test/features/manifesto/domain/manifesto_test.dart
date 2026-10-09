import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/manifesto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ManifestoStatus label', () {
    test('全ステータスの日本語ラベルを返す', () {
      expect(ManifestoStatus.neutral.label, '対象外');
      expect(ManifestoStatus.fulfilled.label, '実現');
      expect(ManifestoStatus.partial.label, '一部実現');
      expect(ManifestoStatus.blocked.label, '未実現');
      expect(ManifestoStatus.reversed.label, '逆行');
    });
  });

  group('ManifestoPledge.status 分類', () {
    test('promisedDelta == 0 は neutral', () {
      const pledge = ManifestoPledge(
        lifeParamKey: 'healthcare',
        promisedDelta: 0,
        actualDelta: 5,
      );
      expect(pledge.status, ManifestoStatus.neutral);
    });

    test('promised != 0 かつ actual == 0 は blocked', () {
      const pledge = ManifestoPledge(
        lifeParamKey: 'healthcare',
        promisedDelta: 5,
        actualDelta: 0,
      );
      expect(pledge.status, ManifestoStatus.blocked);
    });

    test('符号が逆は reversed（正→負）', () {
      const pledge = ManifestoPledge(
        lifeParamKey: 'environment',
        promisedDelta: 5,
        actualDelta: -3,
      );
      expect(pledge.status, ManifestoStatus.reversed);
    });

    test('符号が逆は reversed（負→正）', () {
      const pledge = ManifestoPledge(
        lifeParamKey: 'environment',
        promisedDelta: -5,
        actualDelta: 3,
      );
      expect(pledge.status, ManifestoStatus.reversed);
    });

    test('同符号で絶対値が等しければ fulfilled', () {
      const pledge = ManifestoPledge(
        lifeParamKey: 'education',
        promisedDelta: 5,
        actualDelta: 5,
      );
      expect(pledge.status, ManifestoStatus.fulfilled);
      expect(pledge.isFulfilled, isTrue);
    });

    test('同符号で実際が約束を超えても fulfilled', () {
      const pledge = ManifestoPledge(
        lifeParamKey: 'education',
        promisedDelta: 5,
        actualDelta: 8,
      );
      expect(pledge.status, ManifestoStatus.fulfilled);
    });

    test('同符号で絶対値が小さければ partial', () {
      const pledge = ManifestoPledge(
        lifeParamKey: 'education',
        promisedDelta: 5,
        actualDelta: 2,
      );
      expect(pledge.status, ManifestoStatus.partial);
      expect(pledge.isFulfilled, isFalse);
    });

    test('負の公約が完全実現なら fulfilled', () {
      const pledge = ManifestoPledge(
        lifeParamKey: 'lifeCost',
        promisedDelta: -10,
        actualDelta: -10,
      );
      expect(pledge.status, ManifestoStatus.fulfilled);
    });

    test('負の公約が一部実現なら partial', () {
      const pledge = ManifestoPledge(
        lifeParamKey: 'lifeCost',
        promisedDelta: -10,
        actualDelta: -4,
      );
      expect(pledge.status, ManifestoStatus.partial);
    });
  });

  group('ManifestoPledge rate / gap / label', () {
    test('promisedDelta == 0 なら rate は 0.0', () {
      const pledge = ManifestoPledge(
        lifeParamKey: 'safety',
        promisedDelta: 0,
        actualDelta: 9,
      );
      expect(pledge.rate, 0.0);
    });

    test('actual が約束を超えたら rate は 1.0 に clamp', () {
      const pledge = ManifestoPledge(
        lifeParamKey: 'safety',
        promisedDelta: 5,
        actualDelta: 10,
      );
      expect(pledge.rate, 1.0);
    });

    test('partial の rate は 絶対値比', () {
      const pledge = ManifestoPledge(
        lifeParamKey: 'safety',
        promisedDelta: 5,
        actualDelta: 2,
      );
      expect(pledge.rate, closeTo(0.4, 1e-9));
    });

    test('gap は promisedDelta - actualDelta', () {
      const pledge = ManifestoPledge(
        lifeParamKey: 'safety',
        promisedDelta: 5,
        actualDelta: 2,
      );
      expect(pledge.gap, 3);
    });

    test('label は LifeParamKeys.label を経由する', () {
      const pledge = ManifestoPledge(
        lifeParamKey: 'healthcare',
        promisedDelta: 1,
        actualDelta: 1,
      );
      expect(pledge.label, LifeParamKeys.label('healthcare'));
    });
  });

  group('ManifestoPledge JSON / copyWith / equality', () {
    test('toJson/fromJson 往復で一致する', () {
      const pledge = ManifestoPledge(
        lifeParamKey: 'education',
        promisedDelta: 10,
        actualDelta: 4,
        policyTitles: ['教育無償化', '給食無料'],
      );
      final restored = ManifestoPledge.fromJson(pledge.toJson());
      expect(restored, pledge);
      expect(restored.policyTitles, ['教育無償化', '給食無料']);
    });

    test('fromJson は policyTitles 欠損を空リストで扱う', () {
      final pledge = ManifestoPledge.fromJson(<String, dynamic>{
        'lifeParamKey': 'safety',
        'promisedDelta': 3,
        'actualDelta': 3,
      });
      expect(pledge.policyTitles, isEmpty);
    });

    test('copyWith は指定フィールドのみ差し替える', () {
      const base = ManifestoPledge(
        lifeParamKey: 'safety',
        promisedDelta: 5,
        actualDelta: 0,
        policyTitles: ['治安強化'],
      );
      final copied = base.copyWith(actualDelta: 5);
      expect(copied.lifeParamKey, 'safety');
      expect(copied.promisedDelta, 5);
      expect(copied.actualDelta, 5);
      expect(copied.policyTitles, ['治安強化']);
    });

    test('同値の2インスタンスは等価（equatable）', () {
      const a = ManifestoPledge(
        lifeParamKey: 'employment',
        promisedDelta: 8,
        actualDelta: 8,
        policyTitles: ['起業支援'],
      );
      final b = ManifestoPledge(
        lifeParamKey: 'employment',
        promisedDelta: 8,
        actualDelta: 8,
        policyTitles: ['起業支援'],
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('ManifestoRecord 集計', () {
    ManifestoPledge p(String key, int promised, int actual) => ManifestoPledge(
          lifeParamKey: key,
          promisedDelta: promised,
          actualDelta: actual,
        );

    test('totalPledges / relevantPledges / fulfilledCount を数える', () {
      final record = ManifestoRecord(
        electionId: 'e1',
        title: '町長選',
        winnerId: 'c1',
        winnerName: '山田太郎',
        pledges: [
          p('healthcare', 10, 10), // fulfilled
          p('education', 0, 3), // neutral
          p('employment', 5, 2), // partial
          p('environment', 5, 0), // blocked
          p('safety', 5, -1), // reversed
        ],
      );
      expect(record.totalPledges, 5);
      expect(record.relevantPledges, 4);
      expect(record.fulfilledCount, 1);
    });

    test('realizationRate は relevant の rate 平均', () {
      final record = ManifestoRecord(
        electionId: 'e1',
        title: '町長選',
        winnerId: 'c1',
        winnerName: '山田太郎',
        pledges: [
          p('healthcare', 10, 5), // 0.5
          p('education', 0, 9), // neutral は除外
          p('employment', -4, -4), // 1.0
        ],
      );
      expect(record.realizationRate, closeTo(0.75, 1e-9));
      expect(record.percentLabel, '75%');
    });

    test('realizationRate は relevant 0件でも 0除算しない', () {
      const empty = ManifestoRecord(
        electionId: 'e1',
        title: '町長選',
        winnerId: 'c1',
        winnerName: '山田太郎',
      );
      expect(empty.realizationRate, 0.0);
      expect(empty.percentLabel, '0%');

      final allNeutral = ManifestoRecord(
        electionId: 'e2',
        title: '町長選',
        winnerId: 'c1',
        winnerName: '山田太郎',
        pledges: [p('safety', 0, 0)],
      );
      expect(allNeutral.realizationRate, 0.0);
    });

    test('percentLabel は四捨五入する', () {
      final record = ManifestoRecord(
        electionId: 'e1',
        title: '町長選',
        winnerId: 'c1',
        winnerName: '山田太郎',
        pledges: [p('safety', 3, 2)], // 0.666... -> 67%
      );
      expect(record.percentLabel, '67%');
    });

    test('statusCounts は全ステータスを0初期化で集計する', () {
      final record = ManifestoRecord(
        electionId: 'e1',
        title: '町長選',
        winnerId: 'c1',
        winnerName: '山田太郎',
        pledges: [
          p('healthcare', 10, 10), // fulfilled
          p('education', 0, 3), // neutral
          p('employment', 5, 2), // partial
          p('environment', 5, 0), // blocked
          p('safety', 5, -1), // reversed
        ],
      );
      expect(record.statusCounts, {
        ManifestoStatus.neutral: 1,
        ManifestoStatus.fulfilled: 1,
        ManifestoStatus.partial: 1,
        ManifestoStatus.blocked: 1,
        ManifestoStatus.reversed: 1,
      });
    });

    test('statusCounts は空 pledges でも全キーを持つ', () {
      const record = ManifestoRecord(
        electionId: 'e1',
        title: '町長選',
        winnerId: 'c1',
        winnerName: '山田太郎',
      );
      expect(record.statusCounts.length, ManifestoStatus.values.length);
      expect(record.statusCounts.values.every((v) => v == 0), isTrue);
    });

    test('occurredAt あり/なしで JSON 往復できる', () {
      final withDate = ManifestoRecord(
        electionId: 'e1',
        title: '町長選',
        winnerId: 'c1',
        winnerName: '山田太郎',
        occurredAt: DateTime(2026, 10, 9, 12, 30),
        pledges: [p('safety', 5, 5)],
      );
      final restored = ManifestoRecord.fromJson(withDate.toJson());
      expect(restored, withDate);
      expect(restored.occurredAt, DateTime(2026, 10, 9, 12, 30));

      const noDate = ManifestoRecord(
        electionId: 'e2',
        title: '市長選',
        winnerId: 'c2',
        winnerName: '佐藤花子',
      );
      final restored2 = ManifestoRecord.fromJson(noDate.toJson());
      expect(restored2, noDate);
      expect(restored2.occurredAt, isNull);
    });

    test('copyWith は指定フィールドのみ差し替える', () {
      final base = ManifestoRecord(
        electionId: 'e1',
        title: '町長選',
        winnerId: 'c1',
        winnerName: '山田太郎',
        pledges: [p('safety', 5, 5)],
      );
      final copied = base.copyWith(title: '市長選', occurredAt: DateTime(2026, 1, 1));
      expect(copied.electionId, 'e1');
      expect(copied.title, '市長選');
      expect(copied.winnerId, 'c1');
      expect(copied.winnerName, '山田太郎');
      expect(copied.occurredAt, DateTime(2026, 1, 1));
      expect(copied.pledges, base.pledges);
    });

    test('同値の2レコードは等価（equatable）', () {
      final a = ManifestoRecord(
        electionId: 'e1',
        title: '町長選',
        winnerId: 'c1',
        winnerName: '山田太郎',
        pledges: [p('safety', 5, 5)],
      );
      final b = ManifestoRecord(
        electionId: 'e1',
        title: '町長選',
        winnerId: 'c1',
        winnerName: '山田太郎',
        pledges: [p('safety', 5, 5)],
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });
}
