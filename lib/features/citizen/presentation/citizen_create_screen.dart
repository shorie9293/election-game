import 'package:flutter/material.dart';
import 'package:takamagahara_ui/takamagahara_ui.dart' hide AppKeys;
import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';

/// 市民作成画面
class CitizenCreateScreen extends StatefulWidget {
  final void Function(Citizen citizen)? onCitizenCreated;

  const CitizenCreateScreen({super.key, this.onCitizenCreated});

  @override
  State<CitizenCreateScreen> createState() => _CitizenCreateScreenState();
}

class _CitizenCreateScreenState extends State<CitizenCreateScreen> {
  final _nameController = TextEditingController();
  Job _selectedJob = Job.farmer;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onCreate() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final citizen = Citizen.initial(_selectedJob).copyWith(name: name);
    widget.onCitizenCreated?.call(citizen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RetroPalette.bgDark,
      appBar: AppBar(title: const Text('市民登録')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'あなたの名前と職業を選んでください',
              style: TextStyle(
                color: RetroPalette.textAccent,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),

            // 名前入力
            SemanticHelper.interactive(
              testId: 'btn_citizen_name_input',
              label: '名前入力',
              child: TextField(
                key: AppKeys.citizenNameInput,
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '名前',
                  labelStyle: TextStyle(color: RetroPalette.textAccent),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: RetroPalette.panelBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: RetroPalette.gold),
                  ),
                ),
                style: const TextStyle(color: RetroPalette.textNormal),
              ),
            ),
            const SizedBox(height: 24),

            // 職業選択
            SemanticHelper.interactive(
              testId: 'btn_citizen_job_selector',
              label: '職業選択',
              child: DropdownButtonFormField<Job>(
                key: AppKeys.citizenJobSelector,
                value: _selectedJob,
                dropdownColor: RetroPalette.panelBg,
                decoration: const InputDecoration(
                  labelText: '職業',
                  labelStyle: TextStyle(color: RetroPalette.textAccent),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: RetroPalette.panelBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: RetroPalette.gold),
                  ),
                ),
                items: Job.values.map((job) {
                  return DropdownMenuItem(
                    value: job,
                    child: Text(
                      job.label,
                      style: const TextStyle(color: RetroPalette.textNormal),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedJob = value);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // 選択した職業の初期パラメータ表示
            _JobPreview(job: _selectedJob),
            const SizedBox(height: 24),

            // 確定ボタン
            SemanticHelper.interactive(
              testId: 'btn_citizen_create',
              label: '決定',
              child: ElevatedButton(
                key: AppKeys.citizenCreateButton,
                onPressed: _onCreate,
                child: const Text('決定'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobPreview extends StatelessWidget {
  final Job job;

  const _JobPreview({required this.job});

  @override
  Widget build(BuildContext context) {
    final citizen = Citizen.initial(job);
    return Container(
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
            '【${job.label}】の初期パラメータ',
            style: const TextStyle(
              color: RetroPalette.gold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ...citizen.lifeParams.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '${LifeParamKeys.label(e.key)}: ${e.value}',
                style: const TextStyle(color: RetroPalette.textNormal),
              ),
            );
          }),
        ],
      ),
    );
  }
}
