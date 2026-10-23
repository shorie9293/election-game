import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/domain/models/support_timeline.dart';
import 'package:election_game/domain/services/support_timeline_service.dart';

/// 世論タイムラインを永続化するリポジトリの抽象。
abstract class SupportTimelineRepository {
  /// 保存済みの全エントリを読み込む（昇順）。
  Future<List<SupportTimelineEntry>> load();

  /// 全エントリを上書き保存する。
  Future<void> save(List<SupportTimelineEntry> entries);

  /// 1件を追加する（同一 id は重複追加しない）。
  Future<void> add(SupportTimelineEntry entry);
}

/// SharedPreferences に世論タイムラインを永続化するリポジトリ。
///
/// 破損時のフォールバック方針（life_param_snapshot_repository.dart と共通）:
/// - キー未保存・JSON全体破損・List でない → 空リスト
/// - 要素単位の変換失敗は読み飛ばし（1件の破損で全体を失わない）
class SharedPreferencesSupportTimelineRepository
    implements SupportTimelineRepository {
  /// SharedPreferences 上の保存キー
  static const storageKey = 'support_timeline';

  /// 保持上限件数
  static const maxEntries = 200;

  const SharedPreferencesSupportTimelineRepository();

  @override
  Future<List<SupportTimelineEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) return const <SupportTimelineEntry>[];

    final List<dynamic> decoded;
    try {
      final value = jsonDecode(raw);
      if (value is! List) return const <SupportTimelineEntry>[];
      decoded = value;
    } catch (_) {
      // JSON 全体が破損している場合は安全に空リストへフォールバック
      return const <SupportTimelineEntry>[];
    }

    final entries = <SupportTimelineEntry>[];
    for (final item in decoded) {
      if (item is! Map<String, dynamic>) continue;
      try {
        entries.add(SupportTimelineEntry.fromJson(item));
      } catch (_) {
        // 1件の破損要素で全体を失わないよう読み飛ばす
      }
    }
    return SupportTimelineService.sortAscending(entries);
  }

  @override
  Future<void> save(List<SupportTimelineEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final sorted = SupportTimelineService.sortAscending(entries);
    final trimmed = sorted.length <= maxEntries
        ? sorted
        : sorted.sublist(sorted.length - maxEntries);
    final json = jsonEncode(trimmed.map((e) => e.toJson()).toList());
    await prefs.setString(storageKey, json);
  }

  @override
  Future<void> add(SupportTimelineEntry entry) async {
    final current = await load();
    final appended = SupportTimelineService.append(
      current,
      entry,
      limit: maxEntries,
    );
    await save(appended);
  }
}

/// 試験用のメモリ内リポジトリ。SharedPreferences に触れない。
class InMemorySupportTimelineRepository implements SupportTimelineRepository {
  /// 保存領域（試練から観察可能）
  final List<SupportTimelineEntry> store;

  InMemorySupportTimelineRepository([List<SupportTimelineEntry>? initial])
      : store = List<SupportTimelineEntry>.from(
            initial ?? const <SupportTimelineEntry>[]);

  @override
  Future<List<SupportTimelineEntry>> load() async =>
      SupportTimelineService.sortAscending(store);

  @override
  Future<void> save(List<SupportTimelineEntry> entries) async {
    store
      ..clear()
      ..addAll(SupportTimelineService.sortAscending(entries));
  }

  @override
  Future<void> add(SupportTimelineEntry entry) async {
    final appended = SupportTimelineService.append(
      store,
      entry,
      limit: SharedPreferencesSupportTimelineRepository.maxEntries,
    );
    store
      ..clear()
      ..addAll(appended);
  }
}
