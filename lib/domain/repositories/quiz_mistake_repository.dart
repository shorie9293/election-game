import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/quiz_mistake_entry.dart';

/// 誤答復習ノートの永続化リポジトリ。
///
/// 試練では [InMemoryQuizMistakeRepository] を注入して IO を避ける。
abstract class QuizMistakeRepository {
  /// 保存済みの復習ノートを読み込む。破損要素は読み飛ばす。
  Future<List<QuizMistakeEntry>> load();

  /// 復習ノートを丸ごと保存する。
  Future<void> save(List<QuizMistakeEntry> entries);

  /// 復習ノートを全消去する。
  Future<void> clear();
}

/// SharedPreferences に JSON 文字列として復習ノートを永続化する実装。
class SharedPreferencesQuizMistakeRepository implements QuizMistakeRepository {
  /// 保存キー
  static const storageKey = 'election_quiz_mistakes';

  const SharedPreferencesQuizMistakeRepository();

  @override
  Future<List<QuizMistakeEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    return decode(raw);
  }

  @override
  Future<void> save(List<QuizMistakeEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, encode(entries));
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }

  /// エントリ一覧を JSON 文字列へ変換する（純粋関数）。
  static String encode(List<QuizMistakeEntry> entries) =>
      jsonEncode(entries.map((e) => e.toJson()).toList(growable: false));

  /// JSON 文字列から一覧を復元する（純粋関数）。
  ///
  /// - 全体が不正な JSON なら空リストを返す
  /// - 要素単位の破損は読み飛ばす（1件の破損で全損しない）
  static List<QuizMistakeEntry> decode(String raw) {
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return const [];
    }
    if (decoded is! List) return const [];

    final entries = <QuizMistakeEntry>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      try {
        entries.add(
          QuizMistakeEntry.fromJson(item.cast<String, Object?>()),
        );
      } catch (_) {
        // 破損要素は読み飛ばす
      }
    }
    return List<QuizMistakeEntry>.unmodifiable(entries);
  }
}

/// メモリ上のみで保持する実装（試練・プレビュー用）。
class InMemoryQuizMistakeRepository implements QuizMistakeRepository {
  List<QuizMistakeEntry> _entries;

  InMemoryQuizMistakeRepository([List<QuizMistakeEntry>? initial])
      : _entries = List<QuizMistakeEntry>.of(initial ?? const []);

  /// 現在保持しているエントリ（検証用）
  List<QuizMistakeEntry> get entries =>
      List<QuizMistakeEntry>.unmodifiable(_entries);

  @override
  Future<List<QuizMistakeEntry>> load() async =>
      List<QuizMistakeEntry>.unmodifiable(_entries);

  @override
  Future<void> save(List<QuizMistakeEntry> entries) async {
    _entries = List<QuizMistakeEntry>.of(entries);
  }

  @override
  Future<void> clear() async {
    _entries = <QuizMistakeEntry>[];
  }
}
