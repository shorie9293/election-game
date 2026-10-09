import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/models/life_param_snapshot.dart';
import 'package:election_game/domain/services/life_param_trend_service.dart';
import 'package:flutter_test/flutter_test.dart';

LifeParamSnapshot snap(
  String id,
  DateTime at,
  Map<String, int> values,
) =>
    LifeParamSnapshot(electionId: id, occurredAt: at, values: values);

Election electionOf(String id) => Election(
      id: id,
      title: 't',
      scale: ElectionScale.town,
      candidates: const [],
    );

void main() {
  final t1 = DateTime.utc(2026, 1, 1).toLocal();
  final t2 = DateTime.utc(2026, 2, 1).toLocal();
  final t3 = DateTime.utc(2026, 3, 1).toLocal();

  group('fromElection', () {
    test('uses timestampFromId when id is well-formed', () {
      final e = electionOf('election_1750000000000');
      final s = LifeParamTrendService.fromElection(e, {'lifeCost': 40});
      expect(s.electionId, 'election_1750000000000');
      expect(
        s.occurredAt,
        DateTime.fromMillisecondsSinceEpoch(1750000000000),
      );
      expect(s.values, {'lifeCost': 40});
    });

    test('falls back to epoch(0) for malformed id', () {
      final e = electionOf('bogus');
      final s = LifeParamTrendService.fromElection(e, {'lifeCost': 40});
      expect(s.occurredAt, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('copies the params map', () {
      final params = {'lifeCost': 40};
      final s = LifeParamTrendService.fromElection(electionOf('election_1'), params);
      params['lifeCost'] = 99;
      expect(s.values['lifeCost'], 40);
    });
  });

  group('sortSnapshots', () {
    test('sorts ascending, ties broken by electionId, non-mutating', () {
      final a = snap('election_2', t1, {'lifeCost': 1});
      final b = snap('election_1', t1, {'lifeCost': 2});
      final c = snap('election_3', t2, {'lifeCost': 3});
      final input = [c, b, a];
      final copy = List.of(input);

      final sorted = LifeParamTrendService.sortSnapshots(input);

      expect(sorted.map((s) => s.electionId), ['election_1', 'election_2', 'election_3']);
      expect(input, copy, reason: 'input must not be mutated');
      expect(sorted, isNot(same(input)));
    });
  });

  group('availableKeys', () {
    test('known keys in LifeParamKeys.all order, unknown ascending, deduped', () {
      final snapshots = [
        snap('election_1', t1, {'safety': 1, 'lifeCost': 2, 'zzCustom': 9}),
        snap('election_2', t2, {'education': 3, 'zzCustom': 8, 'aaCustom': 7}),
      ];
      expect(
        LifeParamTrendService.availableKeys(snapshots),
        ['lifeCost', 'education', 'safety', 'aaCustom', 'zzCustom'],
      );
    });

    test('empty input -> empty list', () {
      expect(LifeParamTrendService.availableKeys(const []), isEmpty);
    });
  });

  group('labelFor', () {
    test('known key returns LifeParamKeys.label', () {
      expect(LifeParamTrendService.labelFor('lifeCost'), '💰 生活費');
    });

    test('unknown key returns raw key', () {
      expect(LifeParamTrendService.labelFor('zzCustom'), 'zzCustom');
    });
  });

  group('buildSeries', () {
    test('skips snapshots lacking the key, delta chains, first delta 0', () {
      final snapshots = [
        snap('election_1', t1, {'healthcare': 50, 'lifeCost': 10}),
        snap('election_2', t2, {'lifeCost': 12}), // healthcare missing -> skip
        snap('election_3', t3, {'healthcare': 45}),
        snap('election_4', t3, {'healthcare': 45}), // tie -> id order
      ];

      final series = LifeParamTrendService.buildSeries(snapshots, 'healthcare');
      expect(series.key, 'healthcare');
      expect(series.label, '🏥 医療');
      expect(series.points.length, 3);
      expect(series.points[0].electionId, 'election_1');
      expect(series.points[0].value, 50);
      expect(series.points[0].delta, 0);
      expect(series.points[1].electionId, 'election_3');
      expect(series.points[1].value, 45);
      expect(series.points[1].delta, -5);
      expect(series.points[2].electionId, 'election_4');
      expect(series.points[2].value, 45);
      expect(series.points[2].delta, 0);
      expect(series.totalDelta, -5);
    });

    test('empty input or key absent everywhere -> empty series', () {
      final series = LifeParamTrendService.buildSeries(const [], 'lifeCost');
      expect(series.hasData, isFalse);
      expect(series.points, isEmpty);
      expect(series.minValue, 0);
      expect(series.maxValue, 0);
      expect(series.totalDelta, 0);
    });

    test('unsorted input is sorted chronologically', () {
      final snapshots = [
        snap('election_2', t2, {'lifeCost': 20}),
        snap('election_1', t1, {'lifeCost': 10}),
      ];
      final series = LifeParamTrendService.buildSeries(snapshots, 'lifeCost');
      expect(series.points.map((p) => p.electionId), ['election_1', 'election_2']);
      expect(series.points[1].delta, 10);
    });
  });

  group('buildAll', () {
    test('one series per available key, in availableKeys order', () {
      final snapshots = [
        snap('election_1', t1, {'safety': 3, 'lifeCost': 5, 'zzCustom': 1}),
        snap('election_2', t2, {'education': 7}),
      ];
      final all = LifeParamTrendService.buildAll(snapshots);
      expect(all.map((s) => s.key), ['lifeCost', 'education', 'safety', 'zzCustom']);
      expect(all[0].latestValue, 5);
      expect(all[1].latestValue, 7);
      expect(all[2].latestValue, 3);
      expect(all[3].latestValue, 1);
      expect(all[0].label, '💰 生活費');
      expect(all[3].label, 'zzCustom');
    });
  });

  group('latestValue', () {
    test('value from most recent snapshot containing key', () {
      final snapshots = [
        snap('election_1', t1, {'lifeCost': 10, 'healthcare': 1}),
        snap('election_2', t2, {'lifeCost': 20}), // healthcare missing
        snap('election_3', t3, {'lifeCost': 30, 'healthcare': 2}),
      ];
      expect(LifeParamTrendService.latestValue(snapshots, 'lifeCost'), 30);
      expect(LifeParamTrendService.latestValue(snapshots, 'healthcare'), 2);
    });

    test('0 when key never present', () {
      expect(LifeParamTrendService.latestValue(const [], 'lifeCost'), 0);
      expect(
        LifeParamTrendService.latestValue(
          [snap('election_1', t1, {'education': 5})],
          'safety',
        ),
        0,
      );
    });
  });
}
