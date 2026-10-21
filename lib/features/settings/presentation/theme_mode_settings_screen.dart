import 'package:flutter/material.dart';
import 'package:takamagahara_ui/takamagahara_ui.dart' hide AppKeys;
import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/reduce_motion_repository.dart';
import 'package:election_game/core/theme/reduce_motion_setting.dart';
import 'package:election_game/core/theme/theme_mode_setting.dart';
import 'package:election_game/features/settings/presentation/reduce_motion_settings_screen.dart';

/// テーマ設定画面 — ライト／ダーク／システムの選択と永続化
///
/// アクセシビリティ設定の入口として「動きを減らす」導線も兼ねる
/// （ホームの AppBar は既にアイコンで飽和しており、追加すると溢れるため）。
class ThemeModeSettingsScreen extends StatefulWidget {
  final ThemeModeSetting currentMode;
  final ValueChanged<ThemeModeSetting> onModeChanged;

  /// 現在の「動きを減らす」設定（ルートが保持する値）。
  final ReduceMotionSetting reduceMotion;

  /// 「動きを減らす」設定の変更通知。
  final ValueChanged<ReduceMotionSetting>? onReduceMotionChanged;

  const ThemeModeSettingsScreen({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    this.reduceMotion = ReduceMotionSetting.system,
    this.onReduceMotionChanged,
  });

  @override
  State<ThemeModeSettingsScreen> createState() =>
      _ThemeModeSettingsScreenState();
}

class _ThemeModeSettingsScreenState extends State<ThemeModeSettingsScreen> {
  void _openReduceMotionSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReduceMotionSettingsScreen(
          key: AppKeys.reduceMotionScreen,
          repository: const SharedPreferencesReduceMotionRepository(),
          initial: widget.reduceMotion,
          onChanged: (setting) {
            widget.onReduceMotionChanged?.call(setting);
            setState(() {});
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: AppKeys.themeModeScreen,
      appBar: AppBar(title: const Text('テーマ設定')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('アプリのテーマを選択できます。選択すると即座に反映されます。'),
          ),
          for (final mode in ThemeModeSetting.values)
            SemanticHelper.interactive(
              testId: 'btn_theme_mode_${mode.storageKey}',
              label: 'テーマ ${mode.label}',
              child: RadioListTile<ThemeModeSetting>(
                key: AppKeys.themeModeOption(mode.storageKey),
                title: Text(mode.label),
                secondary: Icon(mode.icon),
                value: mode,
                groupValue: widget.currentMode,
                onChanged: (value) {
                  if (value == null) return;
                  widget.onModeChanged(value);
                  setState(() {});
                },
              ),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              '動きの設定',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          ListTile(
            key: AppKeys.reduceMotionEntry,
            leading: const Icon(Icons.motion_photos_off_outlined),
            title: const Text('動きを減らす'),
            subtitle: Text(widget.reduceMotion.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openReduceMotionSettings,
          ),
        ],
      ),
    );
  }
}
