import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/election.dart';

/// 過去選挙のアーカイブを永続化するリポジトリの抽象。
abstract class ElectionArchiveRepository {
  /// 保存済みの全選挙を読み込む。
  Future<List<Election>> load();

  /// 全選挙を上書き保存する。
  Future<void> save(List<Election> elections);

  /// 1件の選挙を既存のアーカイブに追加する（同一IDは重複追加しない）。
  Future<void> add(Election election);
}

/// SharedPreferences に選挙アーカイブを永続化するリポジトリ。
///
/// 破損時のフォールバック方針（quiz_repository.dart と共通）:
/// - キー未保存・JSON破損・型不一致 → 空リスト
/// - 要素単位の変換失敗は読み飛ばし（1件の破損で全体を失わない）
class SharedPreferencesElectionArchiveRepository
    implements ElectionArchiveRepository {
  /// SharedPreferences 上の保存キー
  static const archiveKey = 'election_archive';

  const SharedPreferencesElectionArchiveRepository();

  /// 保存済み選挙を読み込む。未保存・破損時は空リスト。
  @override
  Future<List<Election>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(archiveKey);
    if (raw == null) return const <Election>[];

    final List<dynamic> decoded;
    try {
      final value = jsonDecode(raw);
      if (value is! List) return const <Election>[];
      decoded = value;
    } catch (_) {
      // JSON全体が破損している場合は安全に空リストへフォールバック
      return const <Election>[];
    }

    final elections = <Election>[];
    for (final item in decoded) {
      if (item is! Map<String, dynamic>) continue;
      try {
        elections.add(Election.fromJson(item));
      } catch (_) {
        // 1件の破損要素で全体を失わないよう読み飛ばす
      }
    }
    return elections;
  }

  /// 全選挙を上書き保存する。
  @override
  Future<void> save(List<Election> elections) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(elections.map((e) => e.toJson()).toList());
    await prefs.setString(archiveKey, json);
  }

  /// 1件の選挙を既存アーカイブへ追加する（同一IDは重複追加しない）。
  @override
  Future<void> add(Election election) async {
    final current = await load();
    final exists = current.any((e) => e.id == election.id);
    if (exists) return;
    await save([...current, election]);
  }
}

/// 試験用のメモリ内リポジトリ。SharedPreferences に触れない。
class InMemoryElectionArchiveRepository implements ElectionArchiveRepository {
  /// 保存領域（試練から観察可能）
  final List<Election> store;

  InMemoryElectionArchiveRepository([List<Election>? initial])
      : store = List<Election>.from(initial ?? const <Election>[]);

  @override
  Future<List<Election>> load() async => List<Election>.from(store);

  @override
  Future<void> save(List<Election> elections) async {
    store
      ..clear()
      ..addAll(elections);
  }

  @override
  Future<void> add(Election election) async {
    if (store.any((e) => e.id == election.id)) return;
    store.add(election);
  }
}