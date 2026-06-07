import 'package:flutter/material.dart';
import 'package:election_game/core/accessibility/semantic_helper.dart';
import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/domain/models/citizen.dart';

/// 市民アバター作成画面
class CitizenCreateScreen extends StatefulWidget {
  final ValueChanged<Citizen>? onCreated;

  const CitizenCreateScreen({super.key, this.onCreated});

  @override
  State<CitizenCreateScreen> createState() => _CitizenCreateScreenState();
}

class _CitizenCreateScreenState extends State<CitizenCreateScreen> {
  final _nameController = TextEditingController(text: '');
  Job _selectedJob = Job.farmer;

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
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preview = Citizen.initial(_selectedJob);

    return Scaffold(
      backgroundColor: RetroPalette.bgDark,
      appBar: AppBar(title: const Text('市民の創造')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '名前を決めよ',
              style: TextStyle(
                fontSize: 16,
                color: RetroPalette.panelBorder,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextField(
              key: AppKeys.citizenNameInput,
              controller: _nameController,
              style: const TextStyle(color: RetroPalette.textNormal),
              decoration: InputDecoration(
                hintText: 'あなたの名前',
                hintStyle:
                    const TextStyle(color: RetroPalette.textAccent),
                filled: true,
                fillColor: RetroPalette.panelBg,
                border: OutlineInputBorder(
                  borderSide:
                      const BorderSide(color: RetroPalette.panelBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: RetroPalette.panelBorder.withValues(alpha: 0.5)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide:
                      BorderSide(color: RetroPalette.panelBorder, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '職業を選べ',
              style: TextStyle(
                fontSize: 16,
                color: RetroPalette.panelBorder,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ...Job.values.map((job) {
              final isSelected = _selectedJob == job;
              return SemanticHelper.interactive(
                key: Key('${AppKeys.citizenJobSelector}_${job.name}'),
                label: _jobLabels[job] ?? job.name,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedJob = job),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? RetroPalette.panelBorder
                          : RetroPalette.panelBg,
                      border: Border.all(color: RetroPalette.panelBorder),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _jobLabels[job] ?? job.name,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected
                            ? RetroPalette.bgDark
                            : RetroPalette.textNormal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
            // Preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: RetroPalette.panelBg,
                border: Border.all(color: RetroPalette.panelBorder),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  const Text(
                    '関心事',
                    style: TextStyle(
                      fontSize: 14,
                      color: RetroPalette.panelBorder,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...preview.concerns.map((c) => Text(
                        '・$c',
                        style: const TextStyle(
                          fontSize: 13,
                          color: RetroPalette.textAccent,
                        ),
                      )),
                  const SizedBox(height: 12),
                  const Text(
                    '初期生活',
                    style: TextStyle(
                      fontSize: 14,
                      color: RetroPalette.panelBorder,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...preview.lifeParams.entries.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _paramLabel(e.key),
                              style: const TextStyle(
                                fontSize: 12,
                                color: RetroPalette.textNormal,
                              ),
                            ),
                            Text(
                              '${e.value}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: RetroPalette.gold,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SemanticHelper.interactive(
              key: AppKeys.citizenCreateButton,
              label: '市民を創造する',
              button: true,
              child: ElevatedButton(
                onPressed: _nameController.text.trim().isEmpty
                    ? null
                    : () {
                        final citizen = Citizen.initial(_selectedJob)
                            .copyWith(name: _nameController.text.trim());
                        widget.onCreated?.call(citizen);
                      },
                child: const Text('市民を創造する'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _paramLabel(String key) {
    const labels = {
      'lifeCost': '生活費',
      'healthcare': '医療',
      'education': '教育',
      'employment': '仕事',
      'environment': '環境',
      'safety': '治安',
    };
    return labels[key] ?? key;
  }
}
