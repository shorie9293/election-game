import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/repositories/election_archive_repository.dart';

Election _completedElection(String id, {String title = '村長選挙'}) {
  return Election(
    id: id,
    title: title,
    scale: ElectionScale.village,
    candidates: const [
      Candidate(
        id: 'a',
        name: '天照太郎',
        portraitKey: 'p_a',
        faction: 'f',
        personality: 'p',
        policies: [],
      ),
      Candidate(
        id: 'b',
        name: '天照次郎',
        portraitKey: 'p_b',
        faction: 'f',
        personality: 'p',
        policies: [],
      ),
    ],
    voteCounts: const {'a': 60, 'b': 40},
    winnerId: 'a',
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SharedPreferencesElectionArchiveRepository', () {
    test('未保存キーの読込は空リスト', () async {
      final repo = const SharedPreferencesElectionArchiveRepository();
      expect(await repo.load(), isEmpty);
    });

    test('保存→読込の往復', () async {
      final repo = const SharedPreferencesElectionArchiveRepository();
      final elections = [
        _completedElection('election_1000'),
        _completedElection('election_2000', title: '町長選挙'),
      ];
      await repo.save(elections);

      final loaded = await repo.load();
      expect(loaded.length, 2);
      expect(loaded.first.id, 'election_1000');
      expect(loaded.first, equals(elections.first));
      expect(loaded.last.title, '町長選挙');
    });

    test("JSON全体が破損（'{' 等）なら空リスト", () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesElectionArchiveRepository.archiveKey: '{',
      });
      final repo = const SharedPreferencesElectionArchiveRepository();
      expect(await repo.load(), isEmpty);
    });

    test('JSONがリストでない（型不一致）なら空リスト', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesElectionArchiveRepository.archiveKey: '"string"',
      });
      final repo = const SharedPreferencesElectionArchiveRepository();
      expect(await repo.load(), isEmpty);
    });

    test('一部破損要素は読み飛ばし、正常要素のみ残す', () async {
      final good = _completedElection('election_2000');
      final rawList = jsonEncode([
        {'id': 'broken'}, // title 欠落で fromJson が例外
        good.toJson(),
      ]);
      SharedPreferences.setMockInitialValues({
        SharedPreferencesElectionArchiveRepository.archiveKey: rawList,
      });
      final repo = const SharedPreferencesElectionArchiveRepository();

      final loaded = await repo.load();
      expect(loaded.length, 1);
      expect(loaded.first.id, 'election_2000');
    });

    test('add は既存に append する', () async {
      final repo = const SharedPreferencesElectionArchiveRepository();
      await repo.add(_completedElection('election_1000'));
      await repo.add(_completedElection('election_2000'));

      final loaded = await repo.load();
      expect(loaded.map((e) => e.id).toList(), ['election_1000', 'election_2000']);
    });

    test('add は同一IDの重複追加をしない', () async {
      final repo = const SharedPreferencesElectionArchiveRepository();
      await repo.add(_completedElection('election_1000'));
      await repo.add(_completedElection('election_1000', title: '別物'));

      final loaded = await repo.load();
      expect(loaded.length, 1);
      expect(loaded.first.title, '村長選挙');
    });
  });

  group('InMemoryElectionArchiveRepository', () {
    test('メモリ内で保存→読込が完結する', () async {
      final repo = InMemoryElectionArchiveRepository();
      expect(await repo.load(), isEmpty);
      await repo.add(_completedElection('election_1000'));
      expect((await repo.load()).length, 1);
      await repo.save([_completedElection('election_2000')]);
      expect((await repo.load()).single.id, 'election_2000');
    });

    test('add は同一IDの重複追加をしない', () async {
      final repo = InMemoryElectionArchiveRepository();
      await repo.add(_completedElection('election_1000'));
      await repo.add(_completedElection('election_1000'));
      expect((await repo.load()).length, 1);
    });
  });
}