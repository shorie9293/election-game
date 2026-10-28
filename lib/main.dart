import 'dart:async';
import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:takamagahara_ui/takamagahara_ui.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/core/theme/text_scale_repository.dart';
import 'package:election_game/core/theme/theme_mode_repository.dart';
import 'package:election_game/core/theme/theme_mode_setting.dart';
import 'package:election_game/core/theme/reduce_motion_repository.dart';
import 'package:election_game/core/theme/reduce_motion_setting.dart';
import 'package:election_game/core/sound/sound_settings.dart';
import 'package:election_game/core/sound/sound_settings_repository.dart';
import 'package:election_game/core/infrastructure/app_lock_gate.dart';
import 'package:election_game/features/auto_backup/data/auto_backup_bootstrap.dart';
import 'package:election_game/features/backup/data/game_data_backup_repository.dart';
import 'package:election_game/features/backup/domain/game_data_backup.dart';
import 'package:election_game/features/reminder/data/election_reminder_repository.dart';
import 'package:election_game/features/reminder/data/quiet_hours_repository.dart';
import 'package:election_game/features/reminder/domain/notification_route_resolver.dart';
import 'package:election_game/features/reminder/infrastructure/election_notification_service.dart';
import 'package:election_game/features/reminder/presentation/notification_tap_router.dart';
import 'package:election_game/screens/game_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ━━━ Firebase 運用監視基盤（Crashlytics クラッシュ検知 + Analytics KPI計測）━━━
  Future<void> initFirebase() async {
    try {
      await Firebase.initializeApp();
      // Analytics: セッション開始を記録し DAU/定着率のKPI計測を有効化
      unawaited(FirebaseAnalytics.instance.logAppOpen());
      debugPrint('[main] ✅ Firebase 初期化完了');
    } catch (e) {
      // テスト環境や Firebase 未設定時はアプリ起動を妨げず継続する
      debugPrint('[main] ⚠️ Firebase初期化失敗（アプリは継続）: $e');
    }
  }

  initFirebase();

  // 通知設定（リマインダー・静穏時間）の保存先を起動時に開いておく。
  // 通知経路の静穏時間ガードは「既に open 済みの box を読むだけ」のため、
  // ここで open しないと保存済み設定が通知へ反映されない。
  Future<void> initReminderStorage() async {
    try {
      await Hive.initFlutter();
      await Hive.openBox<String>(HiveQuietHoursRepository.boxName);
      await Hive.openBox<String>(HiveElectionReminderRepository.boxName);
    } catch (e) {
      // 失敗しても起動は妨げない（通知設定は既定値＝静穏時間なしで継続）。
      debugPrint('[main] ⚠️ 通知設定ストレージ初期化失敗（アプリは継続）: $e');
    }
  }

  initReminderStorage();

  // クラッシュ検知: Flutterフレームワーク内の致命的エラーを Crashlytics へ送信
  FlutterError.onError = (FlutterErrorDetails details) {
    try {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    } catch (_) {
      // Firebase 未初期化（テスト環境等）はスキップ
    }
    FlutterError.presentError(details);
  };
  // ゾーン外の非同期エラー（Platformレベル）
  PlatformDispatcher.instance.onError = (error, stack) {
    try {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } catch (_) {
      // Firebase 未初期化（テスト環境等）はスキップ
    }
    return true;
  };

  // ━━━ 起動時1日1回の自動バックアップ（世代3ローテーション・投げっぱなし）━━━
  // 既存の手動バックアップ画面は不変。失敗しても起動は妨げない。
  scheduleAutoBackup(
    buildJson: () async {
      final data =
          await const SharedPreferencesGameDataBackupRepository().collect();
      return const GameDataBackupService().build(data);
    },
  );

  runApp(
    ErrorBoundary(
      child: ElectionGameApp(
        navigatorKey: _navigatorKey,
        notificationService: _notificationService,
        onNotificationRoute: _notificationTapRouter.handle,
      ),
    ),
  );
}

/// 通知タップ遷移用の Navigator 参照（MaterialApp へ渡す）。
final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

/// 通知タップの遷移先 router（route → 画面）。
final NotificationTapRouter _notificationTapRouter =
    NotificationTapRouter(navigatorKey: _navigatorKey);

/// 通知サービス（タップ payload → router の結線を含む）。
final ElectionNotificationService _notificationService =
    ElectionNotificationService(
  onRouteSelected: _notificationTapRouter.handle,
);

class ElectionGameApp extends StatefulWidget {
  const ElectionGameApp({
    super.key,
    this.navigatorKey,
    this.notificationService,
    this.onNotificationRoute,
  });

  /// 通知タップからの遷移に使う Navigator 参照。
  final GlobalKey<NavigatorState>? navigatorKey;

  /// 通知サービス（未注入なら通知タップ配線は行わない）。
  final ElectionNotificationService? notificationService;

  /// 解決済み route の受け手（通常は [NotificationTapRouter.handle]）。
  final void Function(ResolvedNotificationRoute route)? onNotificationRoute;

  @override
  State<ElectionGameApp> createState() => _ElectionGameAppState();
}

class _ElectionGameAppState extends State<ElectionGameApp> {
  double _textScale = TextScaleSetting.normalScale;
  final TextScaleRepository _textScaleRepo = const TextScaleRepository();
  ThemeModeSetting _themeMode = ThemeModeSetting.system;
  final ThemeModeRepository _themeRepo = const ThemeModeRepository();
  SoundSettings _soundSettings = SoundSettings.defaults;
  final SoundSettingsRepository _soundRepo = const SoundSettingsRepository();
  ReduceMotionSetting _reduceMotion = ReduceMotionSetting.system;
  final ReduceMotionRepository _reduceMotionRepo =
      const SharedPreferencesReduceMotionRepository();

  @override
  void initState() {
    super.initState();
    _loadTextScale();
    _loadThemeMode();
    _loadSoundSettings();
    _loadReduceMotion();
    _initNotifications();
  }

  /// 通知タップ経路の配線（Navigator 準備後＝初回フレーム後に初期化する）。
  ///
  /// 起動タップ（getNotificationAppLaunchDetails）の保留 route は
  /// [ElectionNotificationService.onRouteSelected] の差し替え時に引き渡される。
  void _initNotifications() {
    final service = widget.notificationService;
    if (service == null) return;
    final handler = widget.onNotificationRoute;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (handler != null) service.onRouteSelected = handler;
      unawaited(service.initialize());
    });
  }

  /// 保存された動きの削減設定を読み込む（未保存/不正値は system）。
  Future<void> _loadReduceMotion() async {
    final saved = await _reduceMotionRepo.load();
    if (mounted) {
      setState(() => _reduceMotion = saved ?? ReduceMotionSetting.system);
    }
  }

  /// 動きの削減設定を変更し、永続化する。
  Future<void> _changeReduceMotion(ReduceMotionSetting setting) async {
    await _reduceMotionRepo.save(setting);
    if (mounted) {
      setState(() => _reduceMotion = setting);
    }
  }

  /// 保存されたサウンド設定を読み込む（未保存/不正値は既定値）。
  Future<void> _loadSoundSettings() async {
    final saved = await _soundRepo.load();
    if (mounted) {
      setState(() => _soundSettings = saved);
    }
  }

  /// サウンド設定を変更し、永続化する。
  Future<void> _changeSoundSettings(SoundSettings settings) async {
    await _soundRepo.save(settings);
    if (mounted) {
      setState(() => _soundSettings = settings);
    }
  }

  /// 保存されたテーマモードを読み込む（未保存/不正値は system）。
  Future<void> _loadThemeMode() async {
    final saved = await _themeRepo.loadThemeMode();
    if (mounted) {
      setState(() => _themeMode = saved ?? ThemeModeSetting.system);
    }
  }

  /// テーマモードを変更し、永続化する。
  Future<void> _changeThemeMode(ThemeModeSetting mode) async {
    await _themeRepo.saveThemeMode(mode);
    if (mounted) {
      setState(() => _themeMode = mode);
    }
  }

  /// 保存された文字サイズ倍率を読み込む（未保存/不正値は1.0）。
  Future<void> _loadTextScale() async {
    final saved = await _textScaleRepo.loadScale();
    if (mounted) {
      setState(() => _textScale = TextScaleSetting.normalized(saved));
    }
  }

  /// 文字サイズを変更し、永続化する。
  Future<void> _changeTextScale(double scale) async {
    await _textScaleRepo.saveScale(scale);
    if (mounted) {
      setState(() => _textScale = scale);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '選挙体験RPG — 天照町',
      navigatorKey: widget.navigatorKey,
      theme: RetroTheme.lightThemeData,
      darkTheme: RetroTheme.themeData,
      themeMode: _themeMode.toThemeMode(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) => MediaQuery(
        data: applyReduceMotion(
          MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(_textScale),
          ),
          _reduceMotion,
        ),
        child: child ?? const SizedBox.shrink(),
      ),
      home: AppLockGate(
        unlockedBuilder: (context) => GameScreen(
          textScale: _textScale,
          onScaleChanged: _changeTextScale,
          themeMode: _themeMode,
          onThemeModeChanged: _changeThemeMode,
          soundSettings: _soundSettings,
          onSoundSettingsChanged: _changeSoundSettings,
          reduceMotion: _reduceMotion,
          onReduceMotionChanged: _changeReduceMotion,
        ),
      ),
    );
  }
}
