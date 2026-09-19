import 'dart:async';
import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:takamagahara_ui/takamagahara_ui.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/core/theme/text_scale_repository.dart';
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

  @override
  void initState() {
    super.initState();
    _loadTextScale();
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
      theme: RetroTheme.themeData,
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
      ),
    );
  }
}
