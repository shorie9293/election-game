import 'package:flutter/material.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/candidate_profile.dart';
import 'package:election_game/domain/services/candidate_almanac_service.dart';

/// 名鑑の並び替え順
enum AlmanacSortOrder { registration, totalEffect }

extension _AlmanacSortOrderLabel on AlmanacSortOrder {
  String get label => this == AlmanacSortOrder.registration ? '登録順' : '政策効果順';
}

/// 候補者名鑑画面 — 全候補者を一覧比較する
class CandidateAlmanacScreen extends StatefulWidget {
  /// テスト等で候補者を差し替えたい場合。null なら [Candidate.samples] を使う。
  final List<Candidate>? candidatesOverride;

  const CandidateAlmanacScreen({super.key, this.candidatesOverride});

  @override
  State<CandidateAlmanacScreen> createState() => _CandidateAlmanacScreenState();
}

class _CandidateAlmanacScreenState extends State<CandidateAlmanacScreen> {
  late List<Candidate> _candidates;
  String? _selectedFaction;
  String _query = '';
  AlmanacSortOrder _sortOrder = AlmanacSortOrder.registration;

  @override
  void initState() {
    super.initState();
    _candidates = widget.candidatesOverride ?? Candidate.samples();
  }

  List<CandidateProfile> get _visible {
    var profiles = CandidateAlmanacService.build(_candidates);
    profiles = CandidateAlmanacService.filterByFaction(profiles, _selectedFaction);
    profiles = CandidateAlmanacService.searchByName(profiles, _query);
    if (_sortOrder == AlmanacSortOrder.totalEffect) {
      profiles = CandidateAlmanacService.sortByTotalEffect(profiles);
    }
    return profiles;
  }

  void _showDetail(CandidateProfile profile) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          key: AppKeys.almanacDetailDialog,
          backgroundColor: RetroPalette.panelBg,
          title: Text(
            profile.candidate.name,
            style: const TextStyle(color: RetroPalette.gold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final policy in profile.candidate.policies) ...[
                  Text(
                    policy.title,
                    style: const TextStyle(
                      color: RetroPalette.textAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    policy.description,
                    style: const TextStyle(
                      color: RetroPalette.textNormal,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'カテゴリ: ${policy.category}',
                    style: const TextStyle(
                      color: RetroPalette.textNormal,
                      fontSize: 12,
                    ),
                  ),
                  for (final effect in policy.effects.entries)
                    Text(
                      '${CandidateAlmanacService.lifeParamLabel(effect.key)}: '
                      '${CandidateAlmanacService.effectLabel(effect.value)}',
                      style: const TextStyle(
                        color: RetroPalette.textNormal,
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              key: AppKeys.almanacDetailCloseButton,
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '閉じる',
                style: TextStyle(color: RetroPalette.textAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final factions = CandidateAlmanacService.factions(_candidates);
    final visible = _visible;

    return Scaffold(
      backgroundColor: RetroPalette.bgDark,
      appBar: AppBar(
        title: const Text('候補者名鑑', key: AppKeys.almanacTitle),
        actions: [
          PopupMenuButton<AlmanacSortOrder>(
            key: AppKeys.almanacSortButton,
            icon: const Icon(Icons.sort),
            tooltip: '並び替え',
            onSelected: (order) => setState(() => _sortOrder = order),
            itemBuilder: (context) => AlmanacSortOrder.values
                .map(
                  (order) => PopupMenuItem<AlmanacSortOrder>(
                    value: order,
                    child: Text(order.label),
                  ),
                )
                .toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              key: AppKeys.almanacSearchField,
              decoration: const InputDecoration(
                hintText: '名前・政党で絞り込み',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  key: AppKeys.almanacFactionAll,
                  label: const Text('すべて'),
                  selected: _selectedFaction == null,
                  onSelected: (_) => setState(() => _selectedFaction = null),
                ),
                const SizedBox(width: 8),
                for (final faction in factions) ...[
                  FilterChip(
                    key: AppKeys.almanacFactionChip(faction),
                    label: Text(faction),
                    selected: _selectedFaction == faction,
                    onSelected: (_) =>
                        setState(() => _selectedFaction = faction),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '候補者 ${visible.length}人',
                key: AppKeys.almanacCountLabel,
                style: const TextStyle(
                  color: RetroPalette.textNormal,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? const Center(
                    child: Text(
                      '該当する候補者がいません',
                      key: AppKeys.almanacEmptyState,
                      style: TextStyle(color: RetroPalette.textNormal),
                    ),
                  )
                : ListView.builder(
                    key: AppKeys.almanacList,
                    padding: const EdgeInsets.all(16),
                    itemCount: visible.length,
                    itemBuilder: (context, index) =>
                        _CandidateCard(
                      profile: visible[index],
                      onTap: () => _showDetail(visible[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final CandidateProfile profile;
  final VoidCallback onTap;

  const _CandidateCard({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final candidate = profile.candidate;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        key: AppKeys.almanacCandidateCard(candidate.id),
        decoration: BoxDecoration(
          color: RetroPalette.panelBg,
          border: Border.all(color: RetroPalette.panelBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate.name,
                    style: const TextStyle(
                      color: RetroPalette.gold,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${candidate.faction} — ${candidate.personality}',
                    style: const TextStyle(
                      color: RetroPalette.textNormal,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '公約 ${profile.policyCount}件',
                    style: const TextStyle(
                      color: RetroPalette.textAccent,
                      fontSize: 12,
                    ),
                  ),
                  if (profile.dominantCategory.isNotEmpty)
                    Text(
                      '得意分野: ${profile.dominantCategory}',
                      style: const TextStyle(
                        color: RetroPalette.textNormal,
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '政策効果合計 '
                    '${CandidateAlmanacService.effectLabel(profile.totalEffectScore)}',
                    style: const TextStyle(
                      color: RetroPalette.textAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}