import 'package:flutter/material.dart';

import 'package:election_game/core/theme/reduce_motion_setting.dart';
import 'package:election_game/core/theme/reduce_motion_repository.dart';

/// 動きの削減設定画面 — システム／有効／減らす の選択と永続化
///
/// WCAG 2.3.3（アニメーションを停止する手段の提供）に配慮し、
/// 端末設定に従うだけでなくアプリ単位で明示的に選べるようにする。
class ReduceMotionSettingsScreen extends StatefulWidget {
  /// 保存先リポジトリ（省略時は SharedPreferences 実装）。
  final ReduceMotionRepository? repository;

  /// 初期選択値（省略時はリポジトリから読み込む）。
  final ReduceMotionSetting? initial;

  /// 選択変更時の通知。
  final ValueChanged<ReduceMotionSetting>? onChanged;

  const ReduceMotionSettingsScreen({
    super.key,
    this.repository,
    this.initial,
    this.onChanged,
  });

  @override
  State<ReduceMotionSettingsScreen> createState() =>
      _ReduceMotionSettingsScreenState();
}

class _ReduceMotionSettingsScreenState extends State<ReduceMotionSettingsScreen> {
  ReduceMotionSetting _setting = ReduceMotionSetting.system;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _setting = initial;
      return;
    }
    _load();
  }

  Future<void> _load() async {
    final repository = widget.repository;
    if (repository == null) return;
    final saved = await repository.load();
    if (!mounted || saved == null) return;
    setState(() => _setting = saved);
  }

  Future<void> _select(ReduceMotionSetting setting) async {
    setState(() => _setting = setting);
    widget.onChanged?.call(setting);
    final repository = widget.repository;
    if (repository != null) {
      await repository.save(setting);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('動きを減らす')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('アニメーションの動きを選べます。選択すると即座に反映されます。'),
          ),
          for (final setting in ReduceMotionSetting.values)
            RadioListTile<ReduceMotionSetting>(
              key: ValueKey('reduce_motion_option_${setting.storageKey}'),
              title: Text(setting.label),
              secondary: Icon(setting.icon),
              value: setting,
              groupValue: _setting,
              onChanged: (value) {
                if (value == null) return;
                _select(value);
              },
            ),
          Card(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'なぜこの設定があるのか',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '動きの多い画面が苦手な方、乗り物酔いしやすい方のために、'
                    'アニメーションを減らす選択肢を用意しています（WCAG 2.3.3 配慮）。'
                    '「システムに従う」では端末の「視差効果を減らす」等の設定が尊重されます。',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
