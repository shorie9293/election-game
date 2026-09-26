import 'package:flutter/material.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/political_group.dart';
import 'package:election_game/domain/models/political_group_profile.dart';
import 'package:election_game/domain/services/political_group_service.dart';

/// 政党（政治団体）の可視化画面。
///
/// 5政党の政策ポジションを経済軸×福祉軸の2次元マップに図示し、
/// 政党ごとの理念・推薦候補と、候補者ごとの支持政党を提示する。
/// 集計・絞込・並替のロジックは [PoliticalGroupService] に委譲し、
/// この画面は表示と選択状態の保持に徹する。
class PoliticalGroupsScreen extends StatefulWidget {
  /// 表示する政党（未指定なら [PoliticalGroup.samples]）
  final List<PoliticalGroup>? groupsOverride;

  /// 推薦候補の解決に使う候補者（未指定なら [Candidate.samples]）
  final List<Candidate>? candidatesOverride;

  const PoliticalGroupsScreen({
    super.key,
    this.groupsOverride,
    this.candidatesOverride,
  });

  @override
  State<PoliticalGroupsScreen> createState() => _PoliticalGroupsScreenState();
}

class _PoliticalGroupsScreenState extends State<PoliticalGroupsScreen> {
  static const String _allQuadrants = 'すべて';

  List<PoliticalGroup> get _groups =>
      widget.groupsOverride ?? PoliticalGroup.samples();

  List<Candidate> get _candidates =>
      widget.candidatesOverride ?? Candidate.samples();

  String _query = '';
  String _quadrant = _allQuadrants;
  bool _economicDescending = true;

  List<PoliticalGroupProfile> get _allProfiles =>
      PoliticalGroupService.buildProfiles(
        groups: _groups,
        candidates: _candidates,
      );

  List<PoliticalGroupProfile> get _visibleProfiles {
    final searched = PoliticalGroupService.searchByName(_allProfiles, _query);
    final quadrantFiltered = PoliticalGroupService.filterByQuadrant(
      searched,
      _quadrant == _allQuadrants ? '' : _quadrant,
    );
    return PoliticalGroupService.sortByEconomic(
      quadrantFiltered,
      descending: _economicDescending,
    );
  }

  List<String> get _quadrantLabels {
    final labels = <String>[];
    for (final profile in _allProfiles) {
      if (!labels.contains(profile.quadrantLabel)) {
        labels.add(profile.quadrantLabel);
      }
    }
    return labels;
  }

  void _showDetail(PoliticalGroupProfile profile) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: AppKeys.politicalGroupsDetailDialog,
        backgroundColor: RetroPalette.panelBg,
        title: Text(
          profile.group.name,
          style: const TextStyle(color: RetroPalette.gold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                profile.group.ideology,
                style: const TextStyle(color: RetroPalette.textNormal),
              ),
              const SizedBox(height: 12),
              Text(
                '経済軸: ${profile.economicLabel}'
                '（${profile.group.economicAxis.toStringAsFixed(2)}）',
                style: const TextStyle(color: RetroPalette.textAccent),
              ),
              Text(
                '福祉軸: ${profile.welfareLabel}'
                '（${profile.group.welfareAxis.toStringAsFixed(2)}）',
                style: const TextStyle(color: RetroPalette.textAccent),
              ),
              const SizedBox(height: 12),
              Text(
                '推薦候補: ${profile.supportedNamesLabel}',
                style: const TextStyle(color: RetroPalette.textNormal),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            key: AppKeys.politicalGroupsDetailCloseButton,
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profiles = _visibleProfiles;
    final analysis = PoliticalGroupService.analyze(
      groups: _groups,
      candidates: _candidates,
    );

    return Scaffold(
      key: AppKeys.politicalGroupsScreen,
      backgroundColor: RetroPalette.bgDark,
      appBar: AppBar(
        title: Semantics(
          key: AppKeys.politicalGroupsTitle,
          header: true,
          label: '政党の可視化',
          child: const Text('政党の可視化'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSummaryCard(analysis),
              const SizedBox(height: 16),
              _buildAxisMap(analysis.profiles),
              const SizedBox(height: 16),
              _buildControls(),
              const SizedBox(height: 8),
              Text(
                '${profiles.length}団体',
                key: AppKeys.politicalGroupsCountLabel,
                style: const TextStyle(color: RetroPalette.textAccent),
              ),
              const SizedBox(height: 8),
              _buildGroupCards(profiles),
              const SizedBox(height: 20),
              _buildSupportSection(analysis),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(PoliticalGroupAnalysis analysis) {
    final zero = analysis.zeroSupportGroups.isEmpty
        ? 'なし'
        : analysis.zeroSupportGroups.map((g) => g.name).join('、');
    return Container(
      key: AppKeys.politicalGroupsSummaryCard,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RetroPalette.panelBg,
        border: Border.all(color: RetroPalette.gold),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '政党の構図',
            style: TextStyle(
              color: RetroPalette.gold,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '政党数: ${analysis.totalGroups}'
            '／推薦を持つ政党: ${analysis.withSupport.length}'
            '／推薦候補なし: ${analysis.zeroSupportGroups.length}',
            style: const TextStyle(color: RetroPalette.textNormal),
          ),
          Text(
            '推薦候補なしの政党: $zero',
            style: const TextStyle(color: RetroPalette.textAccent),
          ),
          Text(
            '推薦の総数: ${analysis.totalSupportEdges}',
            style: const TextStyle(color: RetroPalette.textAccent),
          ),
        ],
      ),
    );
  }

  /// 経済軸×福祉軸の2次元マップ。
  Widget _buildAxisMap(List<PoliticalGroupProfile> profiles) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: RetroPalette.panelBg,
        border: Border.all(color: RetroPalette.gold),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // 中心線（横=経済軸、縦=福祉軸）
          Positioned(
            left: 0,
            right: 0,
            top: 159,
            child: Container(height: 1, color: const Color(0x66FFD700)),
          ),
          Positioned(
            left: 159,
            right: 159,
            top: 0,
            bottom: 0,
            child: Container(width: 1, color: const Color(0x66FFD700)),
          ),
          // 象限ラベル
          const Positioned(
            top: 6,
            left: 8,
            child: Text('規制 × 社会保障重視',
                style: TextStyle(color: Color(0x99E8E8E8), fontSize: 10)),
          ),
          const Positioned(
            top: 6,
            right: 8,
            child: Text('自由市場 × 社会保障重視',
                style: TextStyle(color: Color(0x99E8E8E8), fontSize: 10)),
          ),
          const Positioned(
            bottom: 6,
            left: 8,
            child: Text('規制 × 自己責任',
                style: TextStyle(color: Color(0x99E8E8E8), fontSize: 10)),
          ),
          const Positioned(
            bottom: 6,
            right: 8,
            child: Text('自由市場 × 自己責任',
                style: TextStyle(color: Color(0x99E8E8E8), fontSize: 10)),
          ),
          // 各政党のプロット
          for (final profile in profiles)
            Align(
              alignment: Alignment(
                profile.group.economicAxis.clamp(-1.0, 1.0),
                (-profile.group.welfareAxis).clamp(-1.0, 1.0),
              ),
              child: GestureDetector(
                key: AppKeys.politicalGroupsMarker(profile.group.id),
                onTap: () => _showDetail(profile),
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: profile.hasSupport
                        ? RetroPalette.gold
                        : RetroPalette.voteAbstain,
                    shape: BoxShape.circle,
                    border: Border.all(color: RetroPalette.textNormal),
                  ),
                  child: Text(
                    profile.group.name.characters.first,
                    style: const TextStyle(
                      color: Color(0xFF1A1A2E),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: AppKeys.politicalGroupsSearchField,
          style: const TextStyle(color: RetroPalette.textNormal),
          decoration: InputDecoration(
            hintText: '政党名・理念で検索',
            hintStyle: const TextStyle(color: Color(0x99E8E8E8)),
            suffixIcon: IconButton(
              key: AppKeys.politicalGroupsSearchClear,
              icon: const Icon(Icons.clear),
              color: RetroPalette.textAccent,
              onPressed: () => setState(() => _query = ''),
            ),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              key: AppKeys.politicalGroupsQuadrantChip(_allQuadrants),
              label: const Text(_allQuadrants),
              selected: _quadrant == _allQuadrants,
              onSelected: (_) => setState(() => _quadrant = _allQuadrants),
            ),
            for (final label in _quadrantLabels)
              FilterChip(
                key: AppKeys.politicalGroupsQuadrantChip(label),
                label: Text(label),
                selected: _quadrant == label,
                onSelected: (_) => setState(() => _quadrant = label),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: PopupMenuButton<bool>(
            key: AppKeys.politicalGroupsSortButton,
            icon: const Icon(Icons.sort, color: RetroPalette.gold),
            tooltip: '並び替え',
            onSelected: (descending) =>
                setState(() => _economicDescending = descending),
            itemBuilder: (context) => const [
              PopupMenuItem<bool>(
                value: true,
                child: Text('経済軸 降順（自由市場→規制）'),
              ),
              PopupMenuItem<bool>(
                value: false,
                child: Text('経済軸 昇順（規制→自由市場）'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroupCards(List<PoliticalGroupProfile> profiles) {
    if (profiles.isEmpty) {
      return const Padding(
        key: AppKeys.politicalGroupsEmptyState,
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          '該当する政党がありません',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0x99E8E8E8)),
        ),
      );
    }
    return Column(
      key: AppKeys.politicalGroupsList,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final profile in profiles)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              key: AppKeys.politicalGroupsCard(profile.group.id),
              onTap: () => _showDetail(profile),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: RetroPalette.panelBg,
                  border: Border.all(color: RetroPalette.panelBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.group.name,
                      style: const TextStyle(
                        color: RetroPalette.gold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      profile.group.ideology,
                      style: const TextStyle(color: RetroPalette.textNormal),
                    ),
                    Text(
                      profile.quadrantLabel,
                      style: const TextStyle(color: RetroPalette.textAccent),
                    ),
                    Text(
                      '推薦候補: ${profile.supportedNamesLabel}',
                      style: const TextStyle(color: RetroPalette.textNormal),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSupportSection(PoliticalGroupAnalysis analysis) {
    return Column(
      key: AppKeys.politicalGroupsSupportList,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '候補者ごとの支持政党',
          style: TextStyle(
            color: RetroPalette.gold,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        for (final support in analysis.candidateSupports)
          Padding(
            key: AppKeys.politicalGroupsSupportRow(support.candidate.id),
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '${support.candidate.name}: ${support.groupNamesLabel}'
              '（${support.groupCount}政党）',
              style: const TextStyle(color: RetroPalette.textNormal),
            ),
          ),
      ],
    );
  }
}
