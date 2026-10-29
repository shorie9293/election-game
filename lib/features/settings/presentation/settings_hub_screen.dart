import 'package:flutter/material.dart';
import 'package:takamagahara_ui/takamagahara_ui.dart' hide AppKeys;

import 'package:election_game/core/infrastructure/app_lock_settings_screen.dart';
import 'package:election_game/core/sound/sound_settings.dart';
import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/reduce_motion_repository.dart';
import 'package:election_game/core/theme/reduce_motion_setting.dart';
import 'package:election_game/core/theme/text_scale_repository.dart';
import 'package:election_game/core/theme/theme_mode_setting.dart';
import 'package:election_game/features/about/presentation/about_screen.dart';
import 'package:election_game/features/auto_backup/data/auto_backup_restorer_impl.dart';
import 'package:election_game/features/auto_backup/data/auto_backup_sharer_impl.dart';
import 'package:election_game/features/auto_backup/data/auto_backup_store.dart';
import 'package:election_game/features/auto_backup/presentation/auto_backup_screen.dart';
import 'package:election_game/features/backup/data/game_data_backup_repository.dart';
import 'package:election_game/features/backup/presentation/game_data_backup_screen.dart';
import 'package:election_game/features/crossapp/data/crossapp_link_code_repository.dart';
import 'package:election_game/features/crossapp/presentation/crossapp_link_settings_screen.dart';
import 'package:election_game/features/reminder/data/quiet_hours_repository.dart';
import 'package:election_game/features/reminder/infrastructure/notification_permission_requester.dart';
import 'package:election_game/features/reminder/presentation/election_reminder_settings_screen.dart';
import 'package:election_game/features/reminder/presentation/quiet_hours_settings_screen.dart';
import 'package:election_game/features/settings/presentation/reduce_motion_settings_screen.dart';
import 'package:election_game/features/settings/presentation/sound_settings_screen.dart';
import 'package:election_game/features/settings/presentation/text_scale_settings_screen.dart';
import 'package:election_game/features/settings/presentation/theme_mode_settings_screen.dart';

/// 設定ハブ画面（改善提案#181）— 散在する設定画面への導線を1画面に集約する。
///
/// 設計方針:
/// - ホームの AppBar は既にアイコン飽和のため、導線はテーマ設定画面の
///   ListView 先頭に置く（#148 で実証済みの手法）。ホームへはアイコンを足さない。
/// - 各項目の遷移先は [WidgetBuilder] で差し替え可能（未指定なら実画面）。
///   試練では探針画面を注入して遷移そのものを検証する。
/// - 値と通知はホーム画面の結線（`_open*` 関数群）と同じものを引き回す。
class SettingsHubScreen extends StatelessWidget {
  const SettingsHubScreen({
    super.key,
    this.textScale = TextScaleSetting.normalScale,
    this.onTextScaleChanged,
    this.themeMode = ThemeModeSetting.system,
    this.onThemeModeChanged,
    this.reduceMotion = ReduceMotionSetting.system,
    this.onReduceMotionChanged,
    this.soundSettings = SoundSettings.defaults,
    this.onSoundSettingsChanged,
    this.crossAppLinkRepository =
        const SharedPreferencesCrossAppLinkCodeRepository(),
    this.themeModeScreenBuilder,
    this.textScaleScreenBuilder,
    this.reduceMotionScreenBuilder,
    this.soundScreenBuilder,
    this.reminderScreenBuilder,
    this.quietHoursScreenBuilder,
    this.backupScreenBuilder,
    this.autoBackupScreenBuilder,
    this.appLockScreenBuilder,
    this.crossAppScreenBuilder,
    this.aboutScreenBuilder,
  });

  /// 文字サイズの現在値と変更通知。
  final double textScale;
  final ValueChanged<double>? onTextScaleChanged;

  /// テーマの現在値と変更通知。
  final ThemeModeSetting themeMode;
  final ValueChanged<ThemeModeSetting>? onThemeModeChanged;

  /// 「動きを減らす」の現在値と変更通知。
  final ReduceMotionSetting reduceMotion;
  final ValueChanged<ReduceMotionSetting>? onReduceMotionChanged;

  /// サウンド設定の現在値と変更通知。
  final SoundSettings soundSettings;
  final ValueChanged<SoundSettings>? onSoundSettingsChanged;

  /// クロスアプリ連携コードの読み込み元（学びの循環）。
  final CrossAppLinkCodeRepository crossAppLinkRepository;

  // 遷移先ビルダー（未指定なら実画面）。
  final WidgetBuilder? themeModeScreenBuilder;
  final WidgetBuilder? textScaleScreenBuilder;
  final WidgetBuilder? reduceMotionScreenBuilder;
  final WidgetBuilder? soundScreenBuilder;
  final WidgetBuilder? reminderScreenBuilder;
  final WidgetBuilder? quietHoursScreenBuilder;
  final WidgetBuilder? backupScreenBuilder;
  final WidgetBuilder? autoBackupScreenBuilder;
  final WidgetBuilder? appLockScreenBuilder;
  final WidgetBuilder? crossAppScreenBuilder;
  final WidgetBuilder? aboutScreenBuilder;

  void _push(BuildContext context, WidgetBuilder builder) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: builder));
  }

  /// 自動バックアップ画面の既定構成（保存先・復元・共有・即時実行）。
  Widget _buildAutoBackupScreen() {
    final store = FileAutoBackupStore();
    const repository = SharedPreferencesGameDataBackupRepository();
    return AutoBackupScreen(
      store: store,
      restorer: StoreAutoBackupRestorer(
        store: store,
        repository: repository,
        buildCurrentJson: () =>
            buildCurrentGameDataJson(repository, DateTime.now()),
        now: DateTime.now,
      ),
      sharer: TempFileAutoBackupSharer(),
      onBackupNow: () => writeAutoBackupNow(
        store: store,
        repository: repository,
        now: DateTime.now(),
      ),
    );
  }

  Widget _tile({
    required Key key,
    required String testId,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return SemanticHelper.interactive(
      testId: testId,
      label: title,
      child: ListTile(
        key: key,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: AppKeys.settingsHubScreen,
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          _tile(
            key: AppKeys.settingsHubThemeTile,
            testId: 'btn_settings_hub_theme',
            icon: Icons.brightness_6,
            title: 'テーマ設定',
            subtitle: 'ライト／ダーク／システム',
            onTap: () => _push(
              context,
              themeModeScreenBuilder ??
                  (_) => ThemeModeSettingsScreen(
                        currentMode: themeMode,
                        onModeChanged: (mode) =>
                            onThemeModeChanged?.call(mode),
                        reduceMotion: reduceMotion,
                        onReduceMotionChanged: onReduceMotionChanged,
                      ),
            ),
          ),
          _tile(
            key: AppKeys.settingsHubTextScaleTile,
            testId: 'btn_settings_hub_text_scale',
            icon: Icons.text_fields,
            title: '文字サイズ',
            subtitle: 'アプリ全体の文字の大きさ',
            onTap: () => _push(
              context,
              textScaleScreenBuilder ??
                  (_) => TextScaleSettingsScreen(
                        currentScale: textScale,
                        onScaleChanged: (scale) =>
                            onTextScaleChanged?.call(scale),
                      ),
            ),
          ),
          _tile(
            key: AppKeys.settingsHubReduceMotionTile,
            testId: 'btn_settings_hub_reduce_motion',
            icon: Icons.motion_photos_off_outlined,
            title: '動きを減らす',
            subtitle: 'アニメーションの抑制（前庭障害への配慮）',
            onTap: () => _push(
              context,
              reduceMotionScreenBuilder ??
                  (_) => ReduceMotionSettingsScreen(
                        repository:
                            const SharedPreferencesReduceMotionRepository(),
                        initial: reduceMotion,
                        onChanged: onReduceMotionChanged,
                      ),
            ),
          ),
          _tile(
            key: AppKeys.settingsHubSoundTile,
            testId: 'btn_settings_hub_sound',
            icon: Icons.volume_up,
            title: 'サウンド',
            subtitle: 'BGM・効果音・音量',
            onTap: () => _push(
              context,
              soundScreenBuilder ??
                  (_) => SoundSettingsScreen(
                        currentSettings: soundSettings,
                        onChanged: (settings) =>
                            onSoundSettingsChanged?.call(settings),
                      ),
            ),
          ),
          _tile(
            key: AppKeys.settingsHubReminderTile,
            testId: 'btn_settings_hub_reminder',
            icon: Icons.notifications_active,
            title: '通知設定',
            subtitle: '選挙リマインダーの曜日と時刻',
            onTap: () => _push(
              context,
              reminderScreenBuilder ??
                  (_) => ElectionReminderSettingsScreen(
                        quietHoursRepository: HiveQuietHoursRepository(),
                        // 通知権限の要求（Android 13+ は要求しないと通知が出ない）。
                        permissionRequester:
                            PlatformNotificationPermissionRequester(),
                      ),
            ),
          ),
          _tile(
            key: AppKeys.settingsHubQuietHoursTile,
            testId: 'btn_settings_hub_quiet_hours',
            icon: Icons.bedtime_outlined,
            title: '静穏時間',
            subtitle: 'おやすみモード（通知を止める時間帯）',
            onTap: () => _push(
              context,
              quietHoursScreenBuilder ??
                  (_) => const QuietHoursSettingsScreen(),
            ),
          ),
          _tile(
            key: AppKeys.settingsHubBackupTile,
            testId: 'btn_settings_hub_backup',
            icon: Icons.save_alt,
            title: 'バックアップ',
            subtitle: 'ゲーム進行データの書き出しと復元',
            onTap: () => _push(
              context,
              backupScreenBuilder ?? (_) => const GameDataBackupScreen(),
            ),
          ),
          _tile(
            key: AppKeys.settingsHubAutoBackupTile,
            testId: 'btn_settings_hub_auto_backup',
            icon: Icons.history,
            title: '自動バックアップ',
            subtitle: '毎日の自動保存を閲覧・復元・共有',
            onTap: () => _push(
              context,
              autoBackupScreenBuilder ?? (_) => _buildAutoBackupScreen(),
            ),
          ),
          _tile(
            key: AppKeys.settingsHubAppLockTile,
            testId: 'btn_settings_hub_app_lock',
            icon: Icons.lock_outline,
            title: 'アプリロック',
            subtitle: 'パスコードで起動を保護',
            onTap: () => _push(
              context,
              appLockScreenBuilder ?? (_) => const AppLockSettingsScreen(),
            ),
          ),
          _tile(
            key: AppKeys.settingsHubCrossAppTile,
            testId: 'btn_settings_hub_cross_app',
            icon: Icons.sync_alt,
            title: 'クロスアプリ連携',
            subtitle: '学びの循環（連携コードの設定）',
            onTap: () => _push(
              context,
              crossAppScreenBuilder ??
                  (_) => CrossAppLinkSettingsScreen(
                        repository: crossAppLinkRepository,
                      ),
            ),
          ),
          _tile(
            key: AppKeys.settingsHubAboutTile,
            testId: 'btn_settings_hub_about',
            icon: Icons.info_outline,
            title: 'アプリについて',
            subtitle: 'バージョン・ライセンス・お問い合わせ',
            onTap: () => _push(
              context,
              aboutScreenBuilder ?? (_) => const AboutScreen(),
            ),
          ),
        ],
      ),
    );
  }
}
