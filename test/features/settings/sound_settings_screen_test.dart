import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/core/sound/sound_settings.dart';
import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/features/settings/presentation/sound_settings_screen.dart';

void main() {
  Widget wrap(SoundSettings settings, ValueChanged<SoundSettings> onChanged) {
    return MaterialApp(
      home: SoundSettingsScreen(
        currentSettings: settings,
        onChanged: onChanged,
      ),
    );
  }

  group('SoundSettingsScreen', () {
    testWidgets('画面が描画され AppBar 標識がある', (tester) async {
      SoundSettings? reported;
      await tester.pumpWidget(wrap(SoundSettings.defaults, (s) => reported = s));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.soundSettingsScreen), findsOneWidget);
      expect(find.text('サウンド設定'), findsOneWidget);
      expect(find.byKey(AppKeys.soundBgmSwitch), findsOneWidget);
      expect(find.byKey(AppKeys.soundSfxSwitch), findsOneWidget);
      expect(find.byKey(AppKeys.soundVolumeSlider), findsOneWidget);
      expect(find.byKey(AppKeys.soundVolumeLabel), findsOneWidget);
      expect(find.byKey(AppKeys.soundSummaryLabel), findsOneWidget);
      expect(reported, isNull);
    });

    testWidgets('BGMスイッチOFF→onChanged に bgmEnabled=false が渡り他フィールドは保持',
        (tester) async {
      SoundSettings? reported;
      await tester.pumpWidget(
        wrap(
          const SoundSettings(bgmEnabled: true, sfxEnabled: true, volume: 0.4),
          (s) => reported = s,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(AppKeys.soundBgmSwitch));
      await tester.pumpAndSettle();

      expect(reported, isNotNull);
      expect(reported!.bgmEnabled, isFalse);
      expect(reported!.sfxEnabled, isTrue);
      expect(reported!.volume, 0.4);
      // 自画面も更新されている
      final switchWidget = tester.widget<SwitchListTile>(
        find.byKey(AppKeys.soundBgmSwitch),
      );
      expect(switchWidget.value, isFalse);
      expect(find.byKey(AppKeys.soundSettingsScreen), findsOneWidget);
    });

    testWidgets('効果音スイッチOFF→onChanged に sfxEnabled=false が渡る', (tester) async {
      SoundSettings? reported;
      await tester.pumpWidget(wrap(SoundSettings.defaults, (s) => reported = s));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(AppKeys.soundSfxSwitch));
      await tester.pumpAndSettle();

      expect(reported, isNotNull);
      expect(reported!.sfxEnabled, isFalse);
      expect(reported!.bgmEnabled, isTrue);
      expect(reported!.volume, SoundSettings.defaults.volume);
    });

    testWidgets('isSilent 時はスライダーが無効、非isSilent 時は有効', (tester) async {
      // 両オフ → 無効
      await tester.pumpWidget(
        wrap(const SoundSettings(bgmEnabled: false, sfxEnabled: false), (_) {}),
      );
      await tester.pumpAndSettle();
      var slider = tester.widget<Slider>(
        find.byKey(AppKeys.soundVolumeSlider),
      );
      expect(slider.onChanged, isNull);

      // 片方オン → 有効
      await tester.pumpWidget(
        wrap(const SoundSettings(bgmEnabled: false, sfxEnabled: true), (_) {}),
      );
      await tester.pumpAndSettle();
      slider = tester.widget<Slider>(find.byKey(AppKeys.soundVolumeSlider));
      expect(slider.onChanged, isNotNull);
    });

    testWidgets('スライダー変更が volume に反映される', (tester) async {
      SoundSettings? reported;
      await tester.pumpWidget(wrap(SoundSettings.defaults, (s) => reported = s));
      await tester.pumpAndSettle();

      final center = tester.getCenter(find.byKey(AppKeys.soundVolumeSlider));
      // divisions=5（0.0..1.0）、既定0.7。右端へドラッグして 1.0 へ
      await tester.drag(
        find.byKey(AppKeys.soundVolumeSlider),
        Offset(500, 0),
      );
      await tester.pumpAndSettle();
      final slider = tester.widget<Slider>(
        find.byKey(AppKeys.soundVolumeSlider),
      );
      expect(slider.value, greaterThan(center.dx * 0));
      expect(slider.value, greaterThanOrEqualTo(0.8));
      expect(reported, isNotNull);
      expect(reported!.volume, slider.value);
    });

    testWidgets('音量ラベル・要約ラベルの表示', (tester) async {
      await tester.pumpWidget(
        wrap(
          const SoundSettings(bgmEnabled: true, sfxEnabled: true, volume: 0.6),
          (_) {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('音量 60%'), findsOneWidget);
      expect(find.text('BGM オン / 効果音 オン / 音量 60%'), findsOneWidget);
    });

    testWidgets('isSilent 時は要約ラベルが消音表記になる', (tester) async {
      await tester.pumpWidget(
        wrap(const SoundSettings(bgmEnabled: false, sfxEnabled: false), (_) {}),
      );
      await tester.pumpAndSettle();

      expect(find.text('消音（すべてオフ）'), findsOneWidget);
    });
  });
}
