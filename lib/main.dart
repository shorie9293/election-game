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
import 'package:election_game/core/sound/sound_settings.dart';
import 'package:election_game/core/sound/sound_settings_repository.dart';
import 'package:election_game/screens/game_screen.dart';

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

  runApp(
    const ErrorBoundary(
      child: ElectionGameApp(),
    ),
  );
}

class ElectionGameApp extends StatefulWidget {
  const ElectionGameApp({super.key});

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

  @override
  void initState() {
    super.initState();
    _loadTextScale();
    _loadThemeMode();
    _loadSoundSettings();
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
      theme: RetroTheme.lightThemeData,
      darkTheme: RetroTheme.themeData,
      themeMode: _themeMode.toThemeMode(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(_textScale),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
      home: GameScreen(
        textScale: _textScale,
        onScaleChanged: _changeTextScale,
        themeMode: _themeMode,
        onThemeModeChanged: _changeThemeMode,
        soundSettings: _soundSettings,
        onSoundSettingsChanged: _changeSoundSettings,
      ),
    );
  }
}
