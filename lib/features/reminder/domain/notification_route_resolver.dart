import 'dart:convert';

/// 通知タップで遷移しうる現世の画面（route）の対応表。
///
/// 通知 payload の `route` はこの集合に含まれる値のみ受理される。
/// 対応表を増やす時は [all] と [NotificationTapRouter] の画面表を同時に更新する。
class NotificationRoutes {
  const NotificationRoutes._();

  /// 本編（ゲーム画面＝Navigator の根）。
  static const String game = 'game';

  /// 通知設定画面。
  static const String reminder = 'reminder';

  /// 選挙アーカイブ画面。
  static const String archive = 'archive';

  /// 受理しうる全 route。
  static const Set<String> all = <String>{game, reminder, archive};
}

/// 通知 payload から解決された遷移先。
///
/// 値等価（route と id の組で同一視する）。
class ResolvedNotificationRoute {
  const ResolvedNotificationRoute({required this.route, this.id});

  /// 遷移先の識別子（[NotificationRoutes] のいずれか）。
  final String route;

  /// 画面内で特定の対象を指す任意の識別子。
  final String? id;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ResolvedNotificationRoute &&
        other.route == route &&
        other.id == id;
  }

  @override
  int get hashCode => Object.hash(route, id);

  @override
  String toString() =>
      'ResolvedNotificationRoute(route: $route, id: $id)';
}

/// 通知 payload（JSON 文字列）と [ResolvedNotificationRoute] の相互変換。
///
/// 純粋層：Flutter にも通知プラグインにも依存しない。
class NotificationRouteResolver {
  const NotificationRouteResolver._();

  /// payload を解決する。未知・null・空・破損・非許可 route は null。
  static ResolvedNotificationRoute? resolve(
    String? payload, {
    required Set<String> allowedRoutes,
  }) {
    if (payload == null) return null;
    final trimmed = payload.trim();
    if (trimmed.isEmpty) return null;

    Object? decoded;
    try {
      decoded = jsonDecode(trimmed);
    } catch (_) {
      return null;
    }
    if (decoded is! Map) return null;

    final rawRoute = decoded['route'];
    if (rawRoute is! String) return null;
    final route = rawRoute.trim();
    if (route.isEmpty) return null;
    if (!allowedRoutes.contains(route)) return null;

    final rawId = decoded['id'];
    if (rawId != null && rawId is! String) return null;
    final id = rawId is String ? rawId.trim() : null;

    return ResolvedNotificationRoute(
      route: route,
      id: (id == null || id.isEmpty) ? null : id,
    );
  }

  /// payload を組み立てる（`{"route":"game"}` / `{"route":"archive","id":"..."}`）。
  static String buildPayload(String route, {String? id}) {
    final map = <String, Object?>{'route': route};
    if (id != null) map['id'] = id;
    return jsonEncode(map);
  }
}
