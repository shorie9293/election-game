import 'package:election_game/domain/models/life_param_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t1 = DateTime.utc(2026, 1, 1).toLocal();
  final t2 = DateTime.utc(2026, 2, 1).toLocal();

  LifeParamSnapshot snap({String id = 'election_1000', DateTime? at}) {
    return LifeParamSnapshot(
      electionId: id,
      occurredAt: at ?? t1,
      values: {'lifeCost': 50, 'healthcare': 70},
    );
  }

  group('LifeParamSnapshot', () {
    test('toJson/fromJson round-trip keeps all fields', () {
      final s = snap(id: 'election_1234', at: t2);
      final restored = LifeParamSnapshot.fromJson(s.toJson());
      expect(restored.electionId, 'election_1234');
      expect(restored.occurredAt, t2);
      expect(restored.values, {'lifeCost': 50, 'healthcare': 70});
      expect(restored, s);
    });

    test('fromJson throws FormatException when electionId missing/not String', () {
      expect(
        () => LifeParamSnapshot.fromJson({'occurredAt': t1.toIso8601String(), 'values': {}}),
        throwsFormatException,
      );
      expect(
        () => LifeParamSnapshot.fromJson({
          'electionId': 123,
          'occurredAt': t1.toIso8601String(),
          'values': {},
        }),
        throwsFormatException,
      );
    });

    test('fromJson throws FormatException when occurredAt missing/not parseable', () {
      expect(
        () => LifeParamSnapshot.fromJson({'electionId': 'election_1', 'values': {}}),
        throwsFormatException,
      );
      expect(
        () => LifeParamSnapshot.fromJson({
          'electionId': 'election_1',
          'occurredAt': 'not-a-date',
          'values': {},
        }),
        throwsFormatException,
      );
    });

    test('fromJson throws FormatException when values missing/not a Map', () {
      expect(
        () => LifeParamSnapshot.fromJson({
          'electionId': 'election_1',
          'occurredAt': t1.toIso8601String(),
        }),
        throwsFormatException,
      );
      expect(
        () => LifeParamSnapshot.fromJson({
          'electionId': 'election_1',
          'occurredAt': t1.toIso8601String(),
          'values': 'oops',
        }),
        throwsFormatException,
      );
    });

    test('valueOf returns value or null', () {
      final s = snap();
      expect(s.valueOf('lifeCost'), 50);
      expect(s.valueOf('unknown'), isNull);
    });

    test('equality is by electionId + values (occurredAt ignored)', () {
      final a = snap(at: t1);
      final b = snap(at: t2);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);

      final c = LifeParamSnapshot(
        electionId: 'election_9999',
        occurredAt: t1,
        values: {'lifeCost': 50, 'healthcare': 70},
      );
      expect(a, isNot(equals(c)));

      final d = LifeParamSnapshot(
        electionId: 'election_1000',
        occurredAt: t1,
        values: {'lifeCost': 51, 'healthcare': 70},
      );
      expect(a, isNot(equals(d)));

      expect(a, isNot(equals('other type')));
    });

    test('toString contains fields', () {
      final s = snap(id: 'election_77');
      expect(s.toString(), contains('election_77'));
      expect(s.toString(), contains('lifeCost'));
    });
  });
}
