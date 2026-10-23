import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/domain/models/support_timeline.dart';
import 'package:election_game/domain/repositories/support_timeline_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final t0 = DateTime.utc(2026, 10, 24, 9, 0);

  SupportTimelineEntry entry(String id, DateTime at, {double rate = 0.4}) {
    return SupportTimelineEntry(
      id: id,
      recordedAt: at,
      electionTitle: '秋の模擬選挙',
      leaderCandidateId: 'cand_a',
      leaderCandidateName: '候補者A',
      leaderSupportRate: rate,
      voterCount: 10,
      moodLabel: '穏やかな世論',
    );
  }

  Map<String, dynamic> jsonOf(SupportTimelineEntry e) => e.toJson();

  group('SharedPreferencesSupportTimelineRepository', () {
    test('保存キーは support_timeline で他機能と衝突しない', () {
      expect(SharedPreferencesSupportTimelineRepository.storageKey,
          'support_timeline');
      expect(SharedPreferencesSupportTimelineRepository.maxEntries, 200);
    });

    test('キー未保存なら空リスト', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const repo = SharedPreferencesSupportTimelineRepository();
      expect(await repo.load(), isEmpty);
    });

    test('save / load で往復し、昇順に整列される', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const repo = SharedPreferencesSupportTimelineRepository();
      final b = entry('b', t0.add(const Duration(hours: 1)));
      final a = entry('a', t0);
      await repo.save([b, a]);
      final loaded = await repo.load();
      expect(loaded.map((e) => e.id).toList(), ['a', 'b']);
      expect(loaded.first, a);
    });

    test('JSON 全体が破損していれば空リスト', () async {
      SharedPreferences.setMockInitialValues(
        <String, Object>{
          SharedPreferencesSupportTimelineRepository.storageKey: '{not json',
        },
      );
      const repo = SharedPreferencesSupportTimelineRepository();
      expect(await repo.load(), isEmpty);
    });

    test('JSON が List でなければ空リスト', () async {
      SharedPreferences.setMockInitialValues(
        <String, Object>{
          SharedPreferencesSupportTimelineRepository.storageKey: '{"a":1}',
        },
      );
      const repo = SharedPreferencesSupportTimelineRepository();
      expect(await repo.load(), isEmpty);
    });

    test('破損した要素だけを読み飛ばす', () async {
      final good = entry('a', t0);
      SharedPreferences.setMockInitialValues(
        <String, Object>{
          SharedPreferencesSupportTimelineRepository.storageKey: jsonEncode([
            jsonOf(good),
            {'id': 'broken'},
            'not-a-map',
            jsonOf(entry('b', t0.add(const Duration(hours: 1)))),
          ]),
        },
      );
      const repo = SharedPreferencesSupportTimelineRepository();
      final loaded = await repo.load();
      expect(loaded.map((e) => e.id).toList(), ['a', 'b']);
    });

    test('save は 200 件上限へトリムする', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const repo = SharedPreferencesSupportTimelineRepository();
      final many = List.generate(
        205,
        (i) => entry('id_${i.toString().padLeft(3, '0')}',
            t0.add(Duration(minutes: i))),
      );
      await repo.save(many);
      final loaded = await repo.load();
      expect(loaded.length, 200);
      expect(loaded.first.id, 'id_005');
      expect(loaded.last.id, 'id_204');
    });

    test('add は重複 id を追加しない', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const repo = SharedPreferencesSupportTimelineRepository();
      await repo.add(entry('a', t0));
      await repo.add(entry('a', t0.add(const Duration(hours: 2))));
      final loaded = await repo.load();
      expect(loaded.length, 1);
      expect(loaded.single.recordedAt, t0);
    });
  });

  group('InMemorySupportTimelineRepository', () {
    test('add は append 経由で昇順・重複なしに積む', () async {
      final repo = InMemorySupportTimelineRepository();
      await repo.add(entry('b', t0.add(const Duration(hours: 1))));
      await repo.add(entry('a', t0));
      await repo.add(entry('b', t0.add(const Duration(hours: 3))));
      expect(repo.store.map((e) => e.id).toList(), ['a', 'b']);
      expect((await repo.load()).length, 2);
    });

    test('save で全置換され、store から観察できる', () async {
      final repo = InMemorySupportTimelineRepository();
      await repo.save([entry('x', t0)]);
      expect(repo.store.map((e) => e.id).toList(), ['x']);
      await repo.save([entry('y', t0.add(const Duration(minutes: 1)))]);
      expect(repo.store.map((e) => e.id).toList(), ['y']);
    });
  });
}
