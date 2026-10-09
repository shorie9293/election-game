import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/manifesto.dart';

/// 公約実現度トラッカーの記録を永続化するリポジトリの抽象。
abstract class ManifestoRepository {
  /// 保存済みの全記録を読み込む。
  Future<List<ManifestoRecord>> load();

  /// 全記録を上書き保存する。
  Future<void> save(List<ManifestoRecord> records);

  /// 1件の記録を既存の記録に追加する（同一選挙IDは重複追加しない）。
  Future<void> add(ManifestoRecord record);
}

/// SharedPreferences に公約実現度の記録を永続化するリポジトリ。
///
/// 破損時のフォールバック方針（election_archive_repository.dart と共通）:
/// - キー未保存・JSON破損・型不一致 → 空リスト
/// - 要素単位の変換失敗は読み飛ばし（1件の破損で全体を失わない）
class SharedPreferencesManifestoRepository implements ManifestoRepository {
  /// SharedPreferences 上の保存キー
  static const manifestoKey = 'manifesto_records';

  const SharedPreferencesManifestoRepository();

  /// 保存済み記録を読み込む。未保存・破損時は空リスト。
  @override
  Future<List<ManifestoRecord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(manifestoKey);
    if (raw == null) return const <ManifestoRecord>[];

    final List<dynamic> decoded;
    try {
      final value = jsonDecode(raw);
      if (value is! List) return const <ManifestoRecord>[];
      decoded = value;
    } catch (_) {
      // JSON全体が破損している場合は安全に空リストへフォールバック
      return const <ManifestoRecord>[];
    }

    final records = <ManifestoRecord>[];
    for (final item in decoded) {
      if (item is! Map<String, dynamic>) continue;
      try {
        records.add(ManifestoRecord.fromJson(item));
      } catch (_) {
        // 1件の破損要素で全体を失わないよう読み飛ばす
      }
    }
    return records;
  }

  /// 全記録を上書き保存する。
  @override
  Future<void> save(List<ManifestoRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(records.map((r) => r.toJson()).toList());
    await prefs.setString(manifestoKey, json);
  }

  /// 1件の記録を既存記録へ追加する（同一選挙IDは重複追加しない）。
  @override
  Future<void> add(ManifestoRecord record) async {
    final current = await load();
    final exists = current.any((r) => r.electionId == record.electionId);
    if (exists) return;
    await save([...current, record]);
  }
}

/// 試験用のメモリ内リポジトリ。SharedPreferences に触れない。
class InMemoryManifestoRepository implements ManifestoRepository {
  /// 保存領域（試練から観察可能）
  final List<ManifestoRecord> store;

  InMemoryManifestoRepository([List<ManifestoRecord>? initial])
      : store = List<ManifestoRecord>.from(initial ?? const <ManifestoRecord>[]);

  @override
  Future<List<ManifestoRecord>> load() async => List<ManifestoRecord>.from(store);

  @override
  Future<void> save(List<ManifestoRecord> records) async {
    store
      ..clear()
      ..addAll(records);
  }

  @override
  Future<void> add(ManifestoRecord record) async {
    if (store.any((r) => r.electionId == record.electionId)) return;
    store.add(record);
  }
}

/// 何もしないリポジトリ（読込は常に空、保存は破棄）。
class NoopManifestoRepository implements ManifestoRepository {
  const NoopManifestoRepository();

  @override
  Future<List<ManifestoRecord>> load() async => const <ManifestoRecord>[];

  @override
  Future<void> save(List<ManifestoRecord> records) async {}

  @override
  Future<void> add(ManifestoRecord record) async {}
}
