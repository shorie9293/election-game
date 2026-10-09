import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/domain/models/life_param_snapshot.dart';

/// 生活パラメータスナップショットを永続化するリポジトリの抽象。
abstract class LifeParamSnapshotRepository {
  /// 保存済みの全スナップショットを読み込む。
  Future<List<LifeParamSnapshot>> load();

  /// 全スナップショットを上書き保存する。
  Future<void> save(List<LifeParamSnapshot> snapshots);

  /// 1件のスナップショットを追加する（同一選挙IDは重複追加しない）。
  Future<void> add(LifeParamSnapshot snapshot);
}

/// SharedPreferences にスナップショットを永続化するリポジトリ。
///
/// 破損時のフォールバック方針（election_archive_repository.dart と共通）:
/// - キー未保存・JSON破損・型不一致 → 空リスト
/// - 要素単位の変換失敗は読み飛ばし（1件の破損で全体を失わない）
class SharedPreferencesLifeParamSnapshotRepository
    implements LifeParamSnapshotRepository {
  /// SharedPreferences 上の保存キー
  static const storageKey = 'life_param_snapshots';

  const SharedPreferencesLifeParamSnapshotRepository();

  @override
  Future<List<LifeParamSnapshot>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) return const <LifeParamSnapshot>[];

    final List<dynamic> decoded;
    try {
      final value = jsonDecode(raw);
      if (value is! List) return const <LifeParamSnapshot>[];
      decoded = value;
    } catch (_) {
      // JSON全体が破損している場合は安全に空リストへフォールバック
      return const <LifeParamSnapshot>[];
    }

    final snapshots = <LifeParamSnapshot>[];
    for (final item in decoded) {
      if (item is! Map<String, dynamic>) continue;
      try {
        snapshots.add(LifeParamSnapshot.fromJson(item));
      } catch (_) {
        // 1件の破損要素で全体を失わないよう読み飛ばす
      }
    }
    return snapshots;
  }

  @override
  Future<void> save(List<LifeParamSnapshot> snapshots) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(snapshots.map((s) => s.toJson()).toList());
    await prefs.setString(storageKey, json);
  }

  /// 1件を既存データへ追加する（同一選挙IDは重複追加しない）。
  @override
  Future<void> add(LifeParamSnapshot snapshot) async {
    final current = await load();
    final exists = current.any((s) => s.electionId == snapshot.electionId);
    if (exists) return;
    await save([...current, snapshot]);
  }
}

/// 試験用のメモリ内リポジトリ。SharedPreferences に触れない。
class InMemoryLifeParamSnapshotRepository implements LifeParamSnapshotRepository {
  /// 保存領域（試練から観察可能）
  final List<LifeParamSnapshot> store;

  InMemoryLifeParamSnapshotRepository([List<LifeParamSnapshot>? initial])
      : store = List<LifeParamSnapshot>.from(initial ?? const <LifeParamSnapshot>[]);

  @override
  Future<List<LifeParamSnapshot>> load() async =>
      List<LifeParamSnapshot>.from(store);

  @override
  Future<void> save(List<LifeParamSnapshot> snapshots) async {
    store
      ..clear()
      ..addAll(snapshots);
  }

  /// 1件を追加する（同一選挙IDは重複追加しない）。
  @override
  Future<void> add(LifeParamSnapshot snapshot) async {
    if (store.any((s) => s.electionId == snapshot.electionId)) return;
    store.add(snapshot);
  }
}
