import 'package:flutter/material.dart';
import 'package:takamagahara_ui/takamagahara_ui.dart' hide AppKeys;
import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/theme_mode_setting.dart';

/// テーマ設定画面 — ライト／ダーク／システムの選択と永続化
class ThemeModeSettingsScreen extends StatefulWidget {
  final ThemeModeSetting currentMode;
  final ValueChanged<ThemeModeSetting> onModeChanged;

  const ThemeModeSettingsScreen({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  State<ThemeModeSettingsScreen> createState() =>
      _ThemeModeSettingsScreenState();
}

class _ThemeModeSettingsScreenState extends State<ThemeModeSettingsScreen> {
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
        ],
      ),
    );
  }
}