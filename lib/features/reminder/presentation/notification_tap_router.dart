import 'package:flutter/material.dart';

import 'package:election_game/domain/repositories/election_archive_repository.dart';
import 'package:election_game/features/archive/presentation/election_archive_screen.dart';
import 'package:election_game/features/reminder/domain/notification_route_resolver.dart';
import 'package:election_game/features/reminder/presentation/election_reminder_settings_screen.dart';

/// route から遷移先画面を組み立てる関数。
typedef NotificationRoutePageBuilder = Widget Function(
  ResolvedNotificationRoute route,
);

/// 通知タップの遷移先 router（薄い層）。
///
/// [navigatorKey] の Navigator を push / popUntil するだけで、
/// 状態は一切持たない。未知 route・Navigator 未準備は何もしない。
class NotificationTapRouter {
  NotificationTapRouter({
    required GlobalKey<NavigatorState> navigatorKey,
    Map<String, NotificationRoutePageBuilder>? pageBuilders,
  })  : _navigatorKey = navigatorKey,
        _pageBuilders = pageBuilders ?? defaultPageBuilders;

  /// 既定の route → 画面 対応表。
  ///
  /// [NotificationRoutes.game] は Navigator の根（本編）へ戻すため
  /// 画面を push しないので、ここには含めない。
  static final Map<String, NotificationRoutePageBuilder> defaultPageBuilders =
      <String, NotificationRoutePageBuilder>{
    NotificationRoutes.reminder: (_) => const ElectionReminderSettingsScreen(),
    NotificationRoutes.archive: (_) => const ElectionArchiveScreen(
      entries: <Never>[],
      repository: SharedPreferencesElectionArchiveRepository(),
    ),
  };

  /// resolver に渡す許可 route（対応表と一致していなければならない）。
  static const Set<String> allowedRoutes = NotificationRoutes.all;

  final GlobalKey<NavigatorState> _navigatorKey;
  final Map<String, NotificationRoutePageBuilder> _pageBuilders;

  /// [route] へ遷移する。遷移したら true、何もしなければ false。
  bool handle(ResolvedNotificationRoute? route) {
    if (route == null) return false;
    if (!allowedRoutes.contains(route.route)) return false;

    final navigator = _navigatorKey.currentState;
    if (navigator == null) return false;

    final builder = _pageBuilders[route.route];
    if (builder == null) {
      if (route.route == NotificationRoutes.game) {
        // 本編は Navigator の根。積まずに根まで戻す。
        navigator.popUntil((r) => r.isFirst);
        return true;
      }
      return false;
    }

    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => builder(route),
        settings: RouteSettings(name: 'notification/${route.route}'),
      ),
    );
    return true;
  }
}
