import 'package:flutter/material.dart';
import 'package:election_game/core/accessibility/semantic_helper.dart';
import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/society_state.dart';

/// マイホーム画面 — 市民生活パラメータと社会状態を表示
class HomeScreen extends StatelessWidget {
  final Citizen citizen;
  final SocietyState society;
  final VoidCallback? onGoToElection;

  const HomeScreen({
    super.key,
    required this.citizen,
    required this.society,
    this.onGoToElection,
  });

  static const _paramLabels = {
    'lifeCost': '生活費',
    'healthcare': '医療',
    'education': '教育',
    'employment': '仕事',
    'environment': '環境',
    'safety': '治安',
  };

  static const _jobLabels = <Job, String>{
    Job.farmer: '農家',
    Job.fisher: '漁師',
    Job.carpenter: '大工',
    Job.merchant: '商人',
    Job.teacher: '教師',
    Job.doctor: '医者',
    Job.official: '役人',
    Job.artisan: '職人',
    Job.student: '学生',
    Job.unemployed: '無職',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RetroPalette.bgDark,
      appBar: AppBar(
        title: const Text('マイホーム'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Citizen info
            SemanticHelper.interactive(
              key: AppKeys.homeTitle,
              label: '市民 ${citizen.name}',
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: RetroPalette.panelBg,
                  border: Border.all(color: RetroPalette.panelBorder),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    Text(
                      citizen.name,
                      style: const TextStyle(
                        fontSize: 20,
                        color: RetroPalette.panelBorder,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _jobLabels[citizen.job] ?? citizen.job.name,
                      style: const TextStyle(
                        fontSize: 14,
                        color: RetroPalette.textAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      citizen.concerns.join(' / '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: RetroPalette.textNormal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Life params
            Container(
              key: AppKeys.homeLifeParams,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: RetroPalette.panelBg,
                border: Border.all(color: RetroPalette.panelBorder),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '生活状態',
                    style: TextStyle(
                      fontSize: 16,
                      color: RetroPalette.panelBorder,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ...citizen.lifeParams.entries.map((e) => _buildParamBar(
                        _paramLabels[e.key] ?? e.key,
                        e.value,
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Society mood
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: RetroPalette.panelBg,
                border: Border.all(color: _moodColor(society.mood)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  const Text(
                    '社会の空気',
                    style: TextStyle(
                      fontSize: 16,
                      color: RetroPalette.panelBorder,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    society.moodLabel,
                    key: AppKeys.homeSocietyMood,
                    style: TextStyle(
                      fontSize: 24,
                      color: _moodColor(society.mood),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '幸福度 ${society.happiness.toInt()}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: RetroPalette.textAccent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Election button
            SemanticHelper.interactive(
              key: AppKeys.homeElectionButton,
              label: '選挙に行く',
              button: true,
              child: ElevatedButton(
                onPressed: onGoToElection,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  '選挙に行く',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParamBar(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: RetroPalette.textNormal,
                ),
              ),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 12,
                  color: RetroPalette.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: RetroPalette.bgDark,
              color: value >= 50 ? RetroPalette.success : RetroPalette.warning,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Color _moodColor(double mood) {
    if (mood < 0.2) return RetroPalette.moodCollusion;
    if (mood < 0.4) return RetroPalette.moodHarmony;
    if (mood < 0.6) return RetroPalette.moodHealthyDebate;
    if (mood < 0.8) return RetroPalette.moodUnhealthy;
    return RetroPalette.moodDictatorship;
  }
}
