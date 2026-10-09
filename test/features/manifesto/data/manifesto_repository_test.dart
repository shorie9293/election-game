import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/domain/models/manifesto.dart';
import 'package:election_game/domain/repositories/manifesto_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const record = ManifestoRecord(
    electionId: 'e1',
    title: '村長選挙',
    winnerId: 'c1',
    winnerName: '太郎',
    pledges: [
      ManifestoPledge(
        lifeParamKey: 'healthcare',
        promisedDelta: 10,
        actualDelta: 10,
        policyTitles: ['病院を増やす'],
      ),
    ],
  );

  group('SharedPreferencesManifestoRepository', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('save→load で往復できる', () async {
      final repo = const SharedPreferencesManifestoRepository();
      await repo.save([record]);

      final loaded = await repo.load();
      expect(loaded.length, 1);
      expect(loaded.first, record);
      expect(loaded.first.realizationRate, 1.0);
    });

    test('add は同一 electionId を重複追加しない', () async {
      final repo = const SharedPreferencesManifestoRepository();
      await repo.add(record);
      await repo.add(record);

      final loaded = await repo.load();
      expect(loaded.length, 1);
    });

    test('未保存なら空リスト', () async {
      final repo = const SharedPreferencesManifestoRepository();
      expect(await repo.load(), isEmpty);
    });

    test('JSON全体が破損していれば空リスト', () async {
      SharedPreferences.setMockInitialValues({
        'manifesto_records': '{{not-json',
      });
      final repo = const SharedPreferencesManifestoRepository();
      expect(await repo.load(), isEmpty);
    });

    test('型不一致（リスト以外）なら空リスト', () async {
      SharedPreferences.setMockInitialValues({
        'manifesto_records': '42',
      });
      final repo = const SharedPreferencesManifestoRepository();
      expect(await repo.load(), isEmpty);
    });

    test('破損要素は読み飛ばす', () async {
      final brokenJson =
          '[{"electionId":"e1"},{"bad":"no-required-fields"},"string-item"]';
      SharedPreferences.setMockInitialValues({
        'manifesto_records': brokenJson,
      });
      final repo = const SharedPreferencesManifestoRepository();

      final loaded = await repo.load();
      expect(loaded.length, 0, reason: '必須フィールド欠損は読み飛ばし');
    });

    test('正常要素と破損要素の混在では正常要素のみ残る', () async {
      final ok = record.toJson();
      final broken = <String, dynamic>{'title': 'no-id'};
      SharedPreferences.setMockInitialValues({
        'manifesto_records': '['
            '${const JsonEncoder().convert(ok)},'
            '${const JsonEncoder().convert(broken)}]',
      });
      final repo = const SharedPreferencesManifestoRepository();

      final loaded = await repo.load();
      expect(loaded.length, 1);
      expect(loaded.first.electionId, 'e1');
    });
  });

  group('InMemoryManifestoRepository', () {
    test('save→load で往復できる', () async {
      final repo = InMemoryManifestoRepository();
      await repo.save([record]);

      final loaded = await repo.load();
      expect(loaded.length, 1);
      expect(loaded.first, record);
    });

    test('add は同一 electionId を重複追加しない', () async {
      final repo = InMemoryManifestoRepository();
      await repo.add(record);
      await repo.add(record);

      expect(repo.store.length, 1);
      expect(await repo.load().then((r) => r.length), 1);
    });

    test('初期値を渡せる', () async {
      final repo = InMemoryManifestoRepository([record]);
      expect(await repo.load().then((r) => r.length), 1);
    });
  });

  group('NoopManifestoRepository', () {
    test('load は常に空', () async {
      const repo = NoopManifestoRepository();
      expect(await repo.load(), isEmpty);
    });

    test('save/add は何もしない（例外も出さない）', () async {
      const repo = NoopManifestoRepository();
      await repo.save([record]);
      await repo.add(record);
      expect(await repo.load(), isEmpty);
    });
  });
}
