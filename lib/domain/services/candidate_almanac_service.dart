import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/candidate_profile.dart';

/// 候補者名鑑を構築・整形する純粋関数サービス
///
/// すべて static メソッドで、入力を破壊しない。
class CandidateAlmanacService {
  CandidateAlmanacService._();

  /// lifeParamKey → 日本語ラベルの対応表
  static const Map<String, String> lifeParamLabels = {
    'lifeCost': '生活費',
    'healthcare': '医療',
    'education': '教育',
    'employment': '雇用',
    'environment': '環境',
    'safety': '治安',
  };

  /// lifeParamKey の日本語ラベル（未登録キーは key をそのまま返す）
  static String lifeParamLabel(String key) => lifeParamLabels[key] ?? key;

  /// 効果値の表示文字列（正は '+10'、負は '-5'、ゼロは '±0'）
  static String effectLabel(int value) {
    if (value > 0) return '+$value';
    if (value < 0) return '$value';
    return '±0';
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

  /// 候補者 1 人からプロファイルを構築する
  ///
  /// effects は |value| 降順 → label 昇順（同順位）に整列し、
  /// value が 0 の効果も含める。dominantCategory は公約カテゴリの
  /// 最頻値（同数は初出順。公約 0 件なら ''）。
  static CandidateProfile buildProfile(Candidate c) {
    final totals = c.totalEffects;
    final effects = totals.entries
        .map((e) => EffectSummary(
              key: e.key,
              label: lifeParamLabel(e.key),
              value: e.value,
            ))
        .toList()
      ..sort((a, b) {
        final cmp =
            b.value.abs().compareTo(a.value.abs()); // |value| 降順
        if (cmp != 0) return cmp;
        return a.label.compareTo(b.label); // 同順位は label 昇順
      });

    // カテゴリ最頻値（同数は初出順）
    final counts = <String, int>{};
    final firstIndex = <String, int>{};
    var index = 0;
    for (final policy in c.policies) {
      counts[policy.category] = (counts[policy.category] ?? 0) + 1;
      firstIndex.putIfAbsent(policy.category, () => index);
      index++;
    }
    var dominant = '';
    var bestCount = -1;
    var bestFirst = c.policies.length + 1;
    for (final entry in counts.entries) {
      if (entry.value > bestCount ||
          (entry.value == bestCount && firstIndex[entry.key]! < bestFirst)) {
        dominant = entry.key;
        bestCount = entry.value;
        bestFirst = firstIndex[entry.key]!;
      }
    }

    return CandidateProfile(
      candidate: c,
      effects: effects,
      dominantCategory: dominant,
    );
  }

  /// 候補者リスト全体からプロファイルを構築する（入力順を保つ）
  static List<CandidateProfile> build(List<Candidate> candidates) {
    return candidates.map(buildProfile).toList();
  }

  /// totalEffectScore で並べ替える（非破壊）
  ///
  /// descending=true なら降順、false なら昇順。同値は candidate.id 昇順。
  static List<CandidateProfile> sortByTotalEffect(
    List<CandidateProfile> profiles, {
    bool descending = true,
  }) {
    final sorted = [...profiles]..sort((a, b) {
        final cmp = descending
            ? b.totalEffectScore.compareTo(a.totalEffectScore)
            : a.totalEffectScore.compareTo(b.totalEffectScore);
        if (cmp != 0) return cmp;
        return a.candidate.id.compareTo(b.candidate.id);
      });
    return sorted;
  }

  /// 派派閥で絞り込む（null・''・'すべて' は全件）
  static List<CandidateProfile> filterByFaction(
    List<CandidateProfile> profiles,
    String? faction,
  ) {
    if (faction == null || faction.isEmpty || faction == 'すべて') {
      return [...profiles];
    }
    return profiles.where((p) => p.candidate.faction == faction).toList();
  }

  /// 名前か派閥の部分一致検索（normalize 後に比較）
  ///
  /// query が空または空白のみなら全件を返す。
  static List<CandidateProfile> searchByName(
    List<CandidateProfile> profiles,
    String query,
  ) {
    final normalized = normalize(query);
    if (normalized.isEmpty) return [...profiles];
    return profiles
        .where((p) =>
            normalize(p.candidate.name).contains(normalized) ||
            normalize(p.candidate.faction).contains(normalized))
        .toList();
  }

  /// 候補者に現れる派閥の一覧（出現順・重複除去）
  static List<String> factions(List<Candidate> candidates) {
    final result = <String>[];
    for (final c in candidates) {
      if (!result.contains(c.faction)) {
        result.add(c.faction);
      }
    }
    return result;
  }

  /// 効果値合計が最大のプロファイル（空なら null、同値は candidate.id 昇順）
  static CandidateProfile? topByEffect(List<CandidateProfile> profiles) {
    if (profiles.isEmpty) return null;
    final sorted = sortByTotalEffect(profiles);
    return sorted.first;
  }
}
