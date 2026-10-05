/// 用語集の1エントリを表す不変モデル
class GlossaryTerm {
  final String id; // 一意ID（英小文字スネーク）
  final String term; // 用語（例: '小選挙区制'）
  final String reading; // 読み（ひらがな。ソート用）
  final String category; // カテゴリ（例: '選挙制度'）
  final String shortDefinition; // 一行定義
  final String description; // 詳しい解説
  final List<String> relatedTermIds; // 関連用語のid

  GlossaryTerm({
    required this.id,
    required this.term,
    required this.reading,
    required this.category,
    this.shortDefinition = '',
    this.description = '',
    this.relatedTermIds = const [],
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'id は空であってはならない');
    }
    if (term.isEmpty) {
      throw ArgumentError.value(term, 'term', 'term は空であってはならない');
    }
  }

  GlossaryTerm copyWith({
    String? id,
    String? term,
    String? reading,
    String? category,
    String? shortDefinition,
    String? description,
    List<String>? relatedTermIds,
  }) {
    return GlossaryTerm(
      id: id ?? this.id,
      term: term ?? this.term,
      reading: reading ?? this.reading,
      category: category ?? this.category,
      shortDefinition: shortDefinition ?? this.shortDefinition,
      description: description ?? this.description,
      relatedTermIds: relatedTermIds ?? this.relatedTermIds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GlossaryTerm &&
        other.id == id &&
        other.term == term &&
        other.reading == reading &&
        other.category == category &&
        other.shortDefinition == shortDefinition &&
        other.description == description &&
        _listEquals(other.relatedTermIds, relatedTermIds);
  }

  @override
  int get hashCode => Object.hash(id, term, reading, category, shortDefinition,
      description, Object.hashAll(relatedTermIds));

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
