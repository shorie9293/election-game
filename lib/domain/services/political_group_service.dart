import '../models/candidate.dart';
import '../models/political_group.dart';
import '../models/political_group_profile.dart';

/// 政治団体の可視化・分析を行う純粋サービス（静的関数のみ）
class PoliticalGroupService {
  PoliticalGroupService._();

  /// 軸ラベル判定用の中立しきい値（0.0 ちょうどは中立）
  static const double neutralThreshold = 0.0;

  static String economicLabel(double axis) =>
      axis > neutralThreshold ? '自由市場' : axis < neutralThreshold ? '規制' : '中立';

  static String welfareLabel(double axis) => axis > neutralThreshold
      ? '社会保障重視'
      : axis < neutralThreshold
          ? '自己責任'
          : '中立';

  static String quadrantLabel(double economic, double welfare) =>
      '${economicLabel(economic)} × ${welfareLabel(welfare)}';

  /// 政治団体ごとの可視化プロフィールを構築する
  ///
  /// supportedCandidateIds は candidates の該当 id のみを解決し、
  /// 未知 id は無視する。candidates の宣言順ではなく
  /// supportedCandidateIds の宣言順を保つ。
  static List<PoliticalGroupProfile> buildProfiles({
    List<PoliticalGroup>? groups,
    List<Candidate>? candidates,
  }) {
    final effectiveGroups = groups ?? PoliticalGroup.samples();
    final effectiveCandidates = candidates ?? Candidate.samples();
    final byId = {for (final c in effectiveCandidates) c.id: c};

    return [
      for (final group in effectiveGroups)
        PoliticalGroupProfile(
          group: group,
          economicLabel: economicLabel(group.economicAxis),
          welfareLabel: welfareLabel(group.welfareAxis),
          quadrantLabel:
              quadrantLabel(group.economicAxis, group.welfareAxis),
          supportedCandidates: [
            for (final id in group.supportedCandidateIds)
              if (byId.containsKey(id)) byId[id]!,
          ],
        ),
    ];
  }

  /// 団体・候補者双方の視点で全体を分析する
  static PoliticalGroupAnalysis analyze({
    List<PoliticalGroup>? groups,
    List<Candidate>? candidates,
  }) {
    final effectiveGroups = groups ?? PoliticalGroup.samples();
    final effectiveCandidates = candidates ?? Candidate.samples();

    final profiles =
        buildProfiles(groups: effectiveGroups, candidates: effectiveCandidates);

    // candidateSupports: 支持団体を1つ以上持つ候補者のみ、宣言順
    final supports = <CandidateSupport>[];
    for (final candidate in effectiveCandidates) {
      final supportingGroups = [
        for (final group in effectiveGroups)
          if (group.supportedCandidateIds.contains(candidate.id)) group,
      ];
      if (supportingGroups.isNotEmpty) {
        supports.add(CandidateSupport(
          candidate: candidate,
          groups: supportingGroups,
        ));
      }
    }

    final zero = [
      for (final group in effectiveGroups)
        if (group.supportedCandidateIds.isEmpty) group,
    ];

    return PoliticalGroupAnalysis(
      profiles: profiles,
      candidateSupports: supports,
      zeroSupportGroups: zero,
    );
  }

  /// economicAxis で並べ替える（既定は降順、tie は name 昇順・非破壊）
  static List<PoliticalGroupProfile> sortByEconomic(
    List<PoliticalGroupProfile> profiles, {
    bool descending = true,
  }) {
    final sorted = [...profiles]..sort((a, b) {
        final cmp = a.group.economicAxis.compareTo(b.group.economicAxis);
        final primary = descending ? -cmp : cmp;
        if (primary != 0) return primary;
        return a.group.name.compareTo(b.group.name);
      });
    return sorted;
  }

  /// quadrantLabel で完全一致フィルタ（空クエリは全件）
  static List<PoliticalGroupProfile> filterByQuadrant(
    List<PoliticalGroupProfile> profiles,
    String quadrantLabel,
  ) {
    if (quadrantLabel.isEmpty) return [...profiles];
    return profiles
        .where((p) => p.quadrantLabel == quadrantLabel)
        .toList();
  }

  /// 候補者を支持する全政治団体を返す
  static List<PoliticalGroup> groupsForCandidate(
    List<PoliticalGroup> groups,
    String candidateId,
  ) {
    return [
      for (final group in groups)
        if (group.supportedCandidateIds.contains(candidateId)) group,
    ];
  }

  /// 全角英数・全角スペースを半角化し trim・小文字化した正規形で検索する
  static List<PoliticalGroupProfile> searchByName(
    List<PoliticalGroupProfile> profiles,
    String query,
  ) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) return [...profiles];
    return profiles.where((p) {
      final name = _normalize(p.group.name);
      final ideology = _normalize(p.group.ideology);
      return name.contains(normalizedQuery) ||
          ideology.contains(normalizedQuery);
    }).toList();
  }

  static String _normalize(String input) {
    final buffer = StringBuffer();
    for (final codeUnit in input.runes) {
      final c = codeUnit;
      // 全角スペース -> 半角スペース
      if (c == 0x3000) {
        buffer.write(' ');
      } else if (c >= 0xFF01 && c <= 0xFF5E) {
        // 全角 ASCII -> 半角 ASCII
        buffer.writeCharCode(c - 0xFEE0);
      } else {
        buffer.writeCharCode(c);
      }
    }
    return buffer.toString().trim().toLowerCase();
  }
}
