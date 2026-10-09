import 'dart:convert';

import 'package:election_game/domain/models/life_param_snapshot.dart';
import 'package:election_game/domain/repositories/life_param_snapshot_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

LifeParamSnapshot snap(String id, Map<String, int> values) =>
    LifeParamSnapshot(
      electionId: id,
      occurredAt: DateTime.fromMillisecondsSinceEpoch(0),
      values: values,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final s1 = snap('election_1', {'lifeCost': 10});
  final s2 = snap('election_2', {'lifeCost': 20, 'healthcare': 30});

  group('InMemoryLifeParamSnapshotRepository', () {
    test('add/load/save round trip', () async {
      final repo = InMemoryLifeParamSnapshotRepository();
      await repo.add(s1);
      await repo.add(s2);
      expect((await repo.load()).map((s) => s.electionId), ['election_1', 'election_2']);

      await repo.save([s2, s1]);
      expect((await repo.load()).map((s) => s.electionId), ['election_2', 'election_1']);
    });

    test('add dedupes by electionId', () async {
      final repo = InMemoryLifeParamSnapshotRepository();
      await repo.add(s1);
      final dupe = snap('election_1', {'lifeCost': 999});
      await repo.add(dupe);
      final loaded = await repo.load();
      expect(loaded.length, 1);
      expect(loaded.first.values['lifeCost'], 10);
    });

    test('load returns a copy, not the internal store', () async {
      final repo = InMemoryLifeParamSnapshotRepository([s1]);
      final loaded = await repo.load();
      loaded.add(s2);
      expect((await repo.load()).length, 1);
    });
  });

  group('SharedPreferencesLifeParamSnapshotRepository', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('missing key -> empty list', () async {
      const repo = SharedPreferencesLifeParamSnapshotRepository();
      expect(await repo.load(), isEmpty);
    });

    test('save/load round trip', () async {
      const repo = SharedPreferencesLifeParamSnapshotRepository();
      await repo.save([s1, s2]);
      final loaded = await repo.load();
      expect(loaded, [s1, s2]);
    });

    test('add appends and dedupes by electionId', () async {
      const repo = SharedPreferencesLifeParamSnapshotRepository();
      await repo.add(s1);
      await repo.add(s2);
      await repo.add(snap('election_1', {'lifeCost': 777}));
      final loaded = await repo.load();
      expect(loaded.length, 2);
      expect(loaded.first.values['lifeCost'], 10);
    });

    test('corrupt JSON -> empty list', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesLifeParamSnapshotRepository.storageKey: '{not json',
      });
      const repo = SharedPreferencesLifeParamSnapshotRepository();
      expect(await repo.load(), isEmpty);
    });

    test('wrong JSON type -> empty list', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesLifeParamSnapshotRepository.storageKey: jsonEncode({'a': 1}),
      });
      const repo = SharedPreferencesLifeParamSnapshotRepository();
      expect(await repo.load(), isEmpty);
    });

    test('per-element corruption is skipped', () async {
      final good = jsonEncode(s2.toJson());
      SharedPreferences.setMockInitialValues({
        SharedPreferencesLifeParamSnapshotRepository.storageKey:
            '[$good, {"electionId": "election_x"}, "not-a-map", {"electionId": 1, "occurredAt": "bad", "values": []}]',
      });
      const repo = SharedPreferencesLifeParamSnapshotRepository();
      final loaded = await repo.load();
      expect(loaded.length, 1);
      expect(loaded.first, s2);
    });
  });
}
