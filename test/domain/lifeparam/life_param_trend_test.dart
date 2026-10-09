import 'package:election_game/domain/models/life_param_trend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t1 = DateTime.utc(2026, 1, 1).toLocal();
  final t2 = DateTime.utc(2026, 2, 1).toLocal();
  final t3 = DateTime.utc(2026, 3, 1).toLocal();

  group('LifeParamTrendPoint', () {
    test('deltaLabel variants', () {
      final p = LifeParamTrendPoint(
        electionId: 'election_1',
        occurredAt: t1,
        value: 50,
        delta: 3,
      );
      expect(p.deltaLabel, '+3');

      final n = LifeParamTrendPoint(
        electionId: 'election_1',
        occurredAt: t1,
        value: 50,
        delta: -2,
      );
      expect(n.deltaLabel, '-2');

      final z = LifeParamTrendPoint(
        electionId: 'election_1',
        occurredAt: t1,
        value: 50,
        delta: 0,
      );
      expect(z.deltaLabel, '±0');
    });
  });

  group('LifeParamTrendSeries', () {
    test('hasData / firstValue / latestValue', () {
      const empty = LifeParamTrendSeries(key: 'lifeCost', label: 'l');
      expect(empty.hasData, isFalse);
      expect(empty.firstValue, isNull);
      expect(empty.latestValue, isNull);

      final series = LifeParamTrendSeries(
        key: 'lifeCost',
        label: 'l',
        points: [
          LifeParamTrendPoint(
              electionId: 'election_1', occurredAt: t1, value: 50, delta: 0),
          LifeParamTrendPoint(
              electionId: 'election_2', occurredAt: t2, value: 60, delta: 10),
        ],
      );
      expect(series.hasData, isTrue);
      expect(series.firstValue, 50);
      expect(series.latestValue, 60);
    });

    test('min/max are 0 when empty', () {
      const empty = LifeParamTrendSeries(key: 'k', label: 'l');
      expect(empty.minValue, 0);
      expect(empty.maxValue, 0);
    });

    test('min/max computed over points', () {
      final series = LifeParamTrendSeries(
        key: 'k',
        label: 'l',
        points: [
          LifeParamTrendPoint(
              electionId: 'e1', occurredAt: t1, value: 40, delta: 0),
          LifeParamTrendPoint(
              electionId: 'e2', occurredAt: t2, value: 80, delta: 40),
          LifeParamTrendPoint(
              electionId: 'e3', occurredAt: t3, value: 55, delta: -25),
        ],
      );
      expect(series.minValue, 40);
      expect(series.maxValue, 80);
    });

    test('totalDelta / totalDeltaLabel / directionLabel', () {
      const empty = LifeParamTrendSeries(key: 'k', label: 'l');
      expect(empty.totalDelta, 0);
      expect(empty.totalDeltaLabel, '±0');
      expect(empty.directionLabel, '横ばい');

      LifeParamTrendSeries series(int first, int last) => LifeParamTrendSeries(
            key: 'k',
            label: 'l',
            points: [
              LifeParamTrendPoint(
                  electionId: 'e1', occurredAt: t1, value: first, delta: 0),
              LifeParamTrendPoint(
                  electionId: 'e2', occurredAt: t2, value: last, delta: last - first),
            ],
          );

      final up = series(50, 55);
      expect(up.totalDelta, 5);
      expect(up.totalDeltaLabel, '+5');
      expect(up.directionLabel, '上昇');

      final down = series(60, 57);
      expect(down.totalDelta, -3);
      expect(down.totalDeltaLabel, '-3');
      expect(down.directionLabel, '低下');

      final flat = series(50, 50);
      expect(flat.totalDeltaLabel, '±0');
      expect(flat.directionLabel, '横ばい');
    });
  });
}
