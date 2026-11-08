import 'dart:convert';

/// 用語集検索の履歴を保持する純粋 Dart モデル。
///
/// - 新しい順（先頭が最新）
/// - 最大 [maxEntries] 件
/// - 追加時に正規化（trim・全角空白→半角・連続空白畳み込み）
/// - 空文字は無視
/// - 大小無視で重複したら先頭へ移動し、表記は新しい入力で更新
class SearchHistory {
  /// 保持する履歴の上限。
  static const int maxEntries = 8;

  const SearchHistory._(this._entries);

  final List<String> _entries;

  /// 空の履歴。
  factory SearchHistory.empty() => const SearchHistory._(<String>[]);

  /// 任意の文字列群から履歴を作る（正規化・重複排除・上限適用）。
  factory SearchHistory.fromList(Iterable<String> source) {
    var result = SearchHistory.empty();
    // 先頭が最新として順に積む（後の要素が古い）。
    for (final value in source.toList().reversed) {
      result = result.add(value);
    }
    return result;
  }

  /// 新しい順の履歴（変更不可）。
  List<String> get entries => List<String>.unmodifiable(_entries);

  int get length => _entries.length;

  bool get isEmpty => _entries.isEmpty;

  bool get isNotEmpty => _entries.isNotEmpty;

  /// 正規化する。全角空白を半角へ、連続空白を1つへ、前後空白を除去。
  static String normalize(String raw) {
    return raw.replaceAll('\u3000', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// 1件追加した新しい履歴を返す（元のインスタンスは不変）。
  ///
  /// 正規化して空になった場合は自分自身を返す。
  SearchHistory add(String raw) {
    final value = normalize(raw);
    if (value.isEmpty) {
      return this;
    }
    final key = value.toLowerCase();
    final next = <String>[
      value,
      for (final entry in _entries)
        if (entry.toLowerCase() != key) entry,
    ];
    if (next.length > maxEntries) {
      next.removeRange(maxEntries, next.length);
    }
    return SearchHistory._(List<String>.unmodifiable(next));
  }

  /// JSON 文字列へ符号化する。
  String encode() => jsonEncode(_entries);

  /// JSON 文字列から復号する。壊れていても例外を投げず空の履歴を返す。
  static SearchHistory decode(String? source) {
    if (source == null || source.isEmpty) {
      return SearchHistory.empty();
    }
    try {
      final decoded = jsonDecode(source);
      if (decoded is! List) {
        return SearchHistory.empty();
      }
      return SearchHistory.fromList(decoded.whereType<String>());
    } catch (_) {
      return SearchHistory.empty();
    }
  }

  @override
  String toString() => 'SearchHistory($_entries)';
}
