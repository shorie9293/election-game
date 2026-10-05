import 'package:election_game/domain/models/glossary_term.dart';

/// 用語集の並べ替え順序
enum GlossarySortOrder { nameAsc, categoryOrder }

/// 政治用語辞典を提供する純粋関数サービス
///
/// すべて static メンバで、入力リストを破壊しない。
class GlossaryService {
  GlossaryService._();

  /// 政治・選挙の基本用語カタログ（14件以上）
  static final List<GlossaryTerm> catalog = [
    GlossaryTerm(
      id: 'shokyosentyoku_sei',
      term: '小選挙区制',
      reading: 'しょうせんきょくせい',
      category: '選挙制度',
      shortDefinition: '1選挙区から1人だけ当選者を出す選挙制度。',
      description:
          '1つの選挙区につき当選者は1名で、最も多く票を集めた候補者だけが当選する。勝者総取りの方式のため、議席と得票の割合が乖離しやすく、二大政党制が生まれやすいとされる。日本の衆議院では小選挙区制と比例代表制を併用している。',
      relatedTermIds: [
        'hireidaihyo_sei',
        'sentryoku',
        'ippyo_no_kakusa',
      ],
    ),
    GlossaryTerm(
      id: 'hireidaihyo_sei',
      term: '比例代表制',
      reading: 'ひれいだいひょうせい',
      category: '選挙制度',
      shortDefinition: '政党の得票率に応じて議席を配分する選挙制度。',
      description:
          '各政党の得票率にほぼ比例して議席を配分する仕組み。死票が少なくなり少数党でも議席を得やすい一方、個人の人柄より政党の政策で選びやすくなる。日本の衆議院では小選挙区制と併用されている。',
      relatedTermIds: ['shokyosentyoku_sei', 'hyoto_ritsu'],
    ),
    GlossaryTerm(
      id: 'ippyo_no_kakusa',
      term: '一票の格差',
      reading: 'いっぴょうのかくさ',
      category: '選挙制度',
      shortDefinition:
          '選挙区ごとの有権者数の違いにより、票の価値が異なること。',
      description:
          '選挙区ごとに有権者数が異なるため、同じ1票でも当選に必要な票数が変わってしまう問題。人口減少が進む地方では格差が拡大しやすく、違憲判断の対象にもなってきた。区割りの見直しで是正が続けられている。',
      relatedTermIds: ['shokyosentyoku_sei', 'sentryoku'],
    ),
    GlossaryTerm(
      id: 'sentryoku',
      term: '選挙区',
      reading: 'せんきょく',
      category: '選挙制度',
      shortDefinition: '当選者を選出するために国を分けた区域。',
      description:
          '議員を選出するために地域ごとに区切った区画。衆議院では全国に小選挙区が設けられ、住民の数や都市・地方の特性を考慮して区割りが定められる。区割りの変更は一票の格差にも影響する。',
      relatedTermIds: ['shokyosentyoku_sei', 'ippyo_no_kakusa'],
    ),
    GlossaryTerm(
      id: 'hyoto_ritsu',
      term: '得票率',
      reading: 'とくひょうりつ',
      category: '選挙制度',
      shortDefinition: '総投票数に対する各候補者・政党の票の割合。',
      description:
          '有効投票総数に対する候補者や政党が得た票の割合（％）。議席の配分や政党の勢力を測る基本的な指標で、比例代表制では特に重視される。',
      relatedTermIds: ['hireidaihyo_sei'],
    ),
    GlossaryTerm(
      id: 'kiken',
      term: '棄権',
      reading: 'きけん',
      category: '投票',
      shortDefinition: '選挙権を持っていながら投票しないこと。',
      description:
          '有権者が投票に行かないこと。棄権が増えると少数の票で当選者が決まり、結果が有権者全体の意思を反映しにくくなる。投票の利便性を高める期日前投票や不在者投票などが整備されている。',
      relatedTermIds: ['kijizen_tohyo'],
    ),
    GlossaryTerm(
      id: 'kijizen_tohyo',
      term: '期日前投票',
      reading: 'きじぜんとうひょう',
      category: '投票',
      shortDefinition:
          '投票日に事情があって投票できない人が、前もって投票できる制度。',
      description:
          '仕事や旅行などの理由で投票日に投票所へ行けない有権者が、公示（告示）日から投票日の前日までの間に投票できる制度。手続きの簡素化により利用者数が大きく増加している。',
      relatedTermIds: ['kiken'],
    ),
    GlossaryTerm(
      id: 'yoto',
      term: '与党',
      reading: 'よとう',
      category: '制度・議会',
      shortDefinition: '内閣を支え、政権を担っている政党。',
      description:
          '首相を擁して内閣を構成する政党。法律案や予算を国会に提出する主導権を持ちやすい。複数の党が政権を組む場合は連立政権と呼ばれる。',
      relatedTermIds: ['yato', 'renritsu'],
    ),
    GlossaryTerm(
      id: 'yato',
      term: '野党',
      reading: 'やとう',
      category: '制度・議会',
      shortDefinition: '与党以外で、政権を担っていない政党。',
      description:
          '政権与党ではない政党の総称。質問や審議を通じて与党を監視し、代替政権の選択肢として政策を提示する役割を担う。',
      relatedTermIds: ['yoto', 'naikai_fushin'],
    ),
    GlossaryTerm(
      id: 'renritsu',
      term: '連立',
      reading: 'れんりつ',
      category: '制度・議会',
      shortDefinition:
          '複数の政党が政権を組んで内閣を作ること（連立政権）。',
      description:
          '国会で過半数の議席を単独で確保できない党が、他党と協力して内閣を構成すること。閣僚の配分や政策協定で妥協が求められ、政局の変動要因にもなる。',
      relatedTermIds: ['yoto'],
    ),
    GlossaryTerm(
      id: 'naikai_fushin',
      term: '内閣不信任決議',
      reading: 'ないかくふしんにんけつぎ',
      category: '制度・議会',
      shortDefinition:
          '衆議院が内閣の信任を否定する決議。可決なら内閣は解散か総辞職を選ぶ。',
      description:
          '日本国憲法第69条に基づき、衆議院で内閣不信任決議案が可決されると、内閣は10日以内に衆議院を解散するか総辞職しなければならない。内閣への統制手段として野党が提出することが多い。',
      relatedTermIds: ['yato'],
    ),
    GlossaryTerm(
      id: 'manifesto',
      term: 'マニフェスト',
      reading: 'まにふぇすと',
      category: '調査・報道',
      shortDefinition: '政党が実現を公約する政策の宣言・文書。',
      description:
          '政党が選挙の際に有権者へ示す政策綱領。単なる公約とは異なり、財源や実現時期など具体的な数値目標を盛り込むことが重視される。選挙後に実現度が検証されることもある。',
      relatedTermIds: ['yoron_chosa'],
    ),
    GlossaryTerm(
      id: 'yoron_chosa',
      term: '世論調査',
      reading: 'よろんちょうさ',
      category: '調査・報道',
      shortDefinition:
          '標本調査を通じて国民の意見や支持の動向を調べる手法。',
      description:
          '無作為に選んだ有権者へ質問し、政党政権への支持や政策への賛否を推計する。報道機関や内閣府などが定期的に実施し、統計の偏りや回収率の影響を受けやすい点には注意が必要。SNS 上の反応は世論そのものとは限らない。',
      relatedTermIds: ['deguchi_chosa'],
    ),
    GlossaryTerm(
      id: 'deguchi_chosa',
      term: '出口調査',
      reading: 'でぐちちょうさ',
      category: '調査・報道',
      shortDefinition:
          '投票直後の有権者に誰に投票したか尋ねる調査。',
      description:
          '投票所の出口で有権者へ直接聞き取る調査。開票結果が確定する前に票の動きや支持層の特徴を分析するために報道機関が実施する。回答は任意で、標本の偏りが生じることもある。',
      relatedTermIds: ['yoron_chosa'],
    ),
  ];

  /// catalog の初出順で重複除去したカテゴリ一覧
  static List<String> get categories {
    final result = <String>[];
    for (final term in catalog) {
      if (!result.contains(term.category)) {
        result.add(term.category);
      }
    }
    return result;
  }

  /// catalog のコピー
  static List<GlossaryTerm> allTerms() => [...catalog];

  /// id で検索（見つからなければ null）
  static GlossaryTerm? findById(String id) {
    for (final term in catalog) {
      if (term.id == id) return term;
    }
    return null;
  }

  /// relatedTermIds を解決する（未知IDは無視・宣言順保持）
  static List<GlossaryTerm> relatedOf(GlossaryTerm t) {
    final result = <GlossaryTerm>[];
    for (final id in t.relatedTermIds) {
      final found = findById(id);
      if (found != null) result.add(found);
    }
    return result;
  }

  /// 検索・比較用の文字列正規化
  ///
  /// 全角英数字 → 半角、全角スペース → 半角、前後の空白除去、小文字化。
  static String normalize(String s) {
    final buffer = StringBuffer();
    for (final code in s.runes) {
      var c = code;
      // 全角英数字・記号（FF01-FF5E）→ 半角 ASCII（21-7E）
      if (c >= 0xFF01 && c <= 0xFF5E) {
        c = c - 0xFEE0;
      } else if (c == 0x3000) {
        // 全角スペース → 半角スペース
        c = 0x20;
      }
      buffer.writeCharCode(c);
    }
    return buffer.toString().trim().toLowerCase();
  }

  /// term / reading / shortDefinition / description のいずれかに
  /// query（normalize 後）が部分一致するか。空クエリは true。
  static bool matchesText(GlossaryTerm t, String query) {
    final normalized = normalize(query);
    if (normalized.isEmpty) return true;
    return normalize(t.term).contains(normalized) ||
        normalize(t.reading).contains(normalized) ||
        normalize(t.shortDefinition).contains(normalized) ||
        normalize(t.description).contains(normalized);
  }

  /// 検索（空クエリなら全件・母集合の宣言順を保つ）
  static List<GlossaryTerm> search(String query) {
    return catalog.where((t) => matchesText(t, query)).toList();
  }

  /// カテゴリで絞り込む（null・''・'すべて' は全件・非破壊）
  static List<GlossaryTerm> filterByCategory(
    List<GlossaryTerm> src,
    String? category,
  ) {
    if (category == null || category.isEmpty || category == 'すべて') {
      return [...src];
    }
    return src.where((t) => t.category == category).toList();
  }

  /// reading 昇順 → term 昇順 → id 昇順で並べ替える（非破壊・明示タイブレーク）
  static List<GlossaryTerm> sortByName(List<GlossaryTerm> src) {
    final sorted = [...src]..sort((a, b) {
        var cmp = a.reading.compareTo(b.reading);
        if (cmp != 0) return cmp;
        cmp = a.term.compareTo(b.term);
        if (cmp != 0) return cmp;
        return a.id.compareTo(b.id);
      });
    return sorted;
  }

  /// category の初出順 → 各カテゴリ内は reading 昇順（非破壊・安定）
  static List<GlossaryTerm> sortByCategory(List<GlossaryTerm> src) {
    final order = categories;
    final rank = <String, int>{};
    for (var i = 0; i < order.length; i++) {
      rank[order[i]] = i;
    }
    final sorted = [...src]..sort((a, b) {
        final cmp = rank[a.category]!.compareTo(rank[b.category]!);
        if (cmp != 0) return cmp;
        return a.reading.compareTo(b.reading);
      });
    return sorted;
  }

  /// 検索 → カテゴリ絞込 → ソート の順に適用する（非破壊）
  static List<GlossaryTerm> apply(
    List<GlossaryTerm> src, {
    String query = '',
    String? category,
    GlossarySortOrder sort = GlossarySortOrder.nameAsc,
  }) {
    var result = src.where((t) => matchesText(t, query)).toList();
    result = filterByCategory(result, category);
    switch (sort) {
      case GlossarySortOrder.nameAsc:
        return sortByName(result);
      case GlossarySortOrder.categoryOrder:
        return sortByCategory(result);
    }
  }
}
