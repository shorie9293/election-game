import 'package:flutter/material.dart';
import 'package:takamagahara_ui/takamagahara_ui.dart' hide AppKeys;
import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/sound/sound_settings.dart';

/// サウンド設定画面 — BGM / 効果音 / 音量の選択と永続化
class SoundSettingsScreen extends StatefulWidget {
  final SoundSettings currentSettings;
  final ValueChanged<SoundSettings> onChanged;

  const SoundSettingsScreen({
    super.key,
    required this.currentSettings,
    required this.onChanged,
  });

  @override
  State<SoundSettingsScreen> createState() => _SoundSettingsScreenState();
}

class _SoundSettingsScreenState extends State<SoundSettingsScreen> {
  SoundSettings _settings = SoundSettings.defaults;

  @override
  void initState() {
    super.initState();
    _settings = widget.currentSettings;
  }

  @override
  void didUpdateWidget(SoundSettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentSettings != oldWidget.currentSettings) {
      _settings = widget.currentSettings;
    }
  }

  void _update(SoundSettings next) {
    widget.onChanged(next);
    setState(() => _settings = next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: AppKeys.soundSettingsScreen,
      appBar: AppBar(title: const Text('サウンド設定')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('BGMと効果音の再生、音量を設定できます。設定はすぐに反映されます。'),
          ),
          SemanticHelper.interactive(
            testId: 'btn_sound_bgm',
            label: 'BGM',
            child: SwitchListTile(
              key: AppKeys.soundBgmSwitch,
              title: const Text('BGM'),
              subtitle: const Text('村・町・市のBGMを再生します'),
              secondary: const Icon(Icons.music_note),
              value: _settings.bgmEnabled,
              onChanged: (value) {
                _update(_settings.copyWith(bgmEnabled: value));
              },
            ),
          ),
          SemanticHelper.interactive(
            testId: 'btn_sound_sfx',
            label: '効果音',
            child: SwitchListTile(
              key: AppKeys.soundSfxSwitch,
              title: const Text('効果音'),
              subtitle: const Text('投票・棄権の操作音'),
              secondary: const Icon(Icons.volume_up),
              value: _settings.sfxEnabled,
              onChanged: (value) {
                _update(_settings.copyWith(sfxEnabled: value));
              },
            ),
          ),
          Slider(
            key: AppKeys.soundVolumeSlider,
            value: _settings.volume,
            divisions: SoundSettings.volumeSteps.length - 1,
            min: 0.0,
            max: 1.0,
            label: _settings.volumeLabel,
            onChanged: _settings.isSilent
                ? null
                : (value) {
                    _update(_settings.copyWith(volume: value));
                  },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '音量 ${_settings.volumeLabel}',
              key: AppKeys.soundVolumeLabel,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _settings.summaryLabel,
              key: AppKeys.soundSummaryLabel,
            ),
          ),
        ],
      ),
    );
  }
}
