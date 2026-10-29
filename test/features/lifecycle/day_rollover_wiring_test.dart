import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/repositories/election_archive_repository.dart';
import 'package:election_game/features/lifecycle/presentation/day_rollover_providers.dart';

/// 日付跨ぎの配線試練。
///
/// 跨ぎ検出 → `invalidate(appTodayProvider)` → 日付依存の実データ
/// （選挙アーカイブから組むヒートマップ）が新しい「今日」で再計算される、
/// という配線が実際に生きていることを確かめる。
void main() {
  Election electionAt(DateTime local) {
    final millis = local.toUtc().millisecondsSinceEpoch;
    return Election(
      id: 'election_$millis',
      title: 'テスト選挙',
      scale: ElectionScale.town,
      candidates: const [],
    );
  }

  late DateTime currentDay;
  late _FakeArchiveRepository repo;

  List<Election> sampleElections() => [
        electionAt(DateTime(2026, 10, 11, 9, 0)),
        electionAt(DateTime(2026, 10, 12, 10, 0)),
        electionAt(DateTime(2026, 10, 13, 8, 0)),
      ];

  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [
        electionArchiveRepositoryProvider.overrideWithValue(repo),
        appTodayProvider.overrideWith((ref) => currentDay),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    currentDay = DateTime(2026, 10, 13, 12, 0);
    repo = _FakeArchiveRepository(sampleElections());
  });

  test('appTodayProvider の invalidate でヒートマップが新しい今日で再計算される', () async {
    final container = buildContainer();

    final before = await container.read(playActivityHeatmapProvider.future);
    expect(before.currentStreak, 3); // 11,12,13 が連続

    // 日付跨ぎ後の「今日」へ進める（本来は AppLifecycleRefresher が撃つ経路）
    currentDay = DateTime(2026, 10, 14, 0, 5);
    container.invalidate(appTodayProvider);

    final after = await container.read(playActivityHeatmapProvider.future);
    expect(after.currentStreak, 0); // 14日の活動が無いので連続は切れる
    expect(after.totalElections, 3);
  });

  test('playActivityHeatmapProvider の invalidate は実アーカイブを読み直す', () async {
    final container = buildContainer();

    await container.read(playActivityHeatmapProvider.future);
    final loadsAfterFirst = repo.loadCount;

    container.invalidate(playActivityHeatmapProvider);
    final hm = await container.read(playActivityHeatmapProvider.future);

    expect(repo.loadCount, loadsAfterFirst + 1);
    expect(hm.totalElections, 3);
  });

  test('invalidated されない限り同じ今日では再読込しない（無駄な再計算なし）', () async {
    final container = buildContainer();

    await container.read(playActivityHeatmapProvider.future);
    await container.read(playActivityHeatmapProvider.future);

    expect(repo.loadCount, 1);
  });
}

class _FakeArchiveRepository implements ElectionArchiveRepository {
  _FakeArchiveRepository(this._elections);

  final List<Election> _elections;
  int loadCount = 0;

  @override
  Future<List<Election>> load() async {
    loadCount++;
    return List<Election>.of(_elections);
  }

  @override
  Future<void> save(List<Election> elections) async {}

  @override
  Future<void> add(Election election) async {}
}
