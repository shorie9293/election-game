import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/features/reminder/domain/notification_route_resolver.dart';
import 'package:election_game/features/reminder/infrastructure/election_notification_service.dart';
import 'package:election_game/features/reminder/presentation/notification_tap_router.dart';

/// Navigator の push を実測する観測者。
class _RecordingNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushed = <Route<dynamic>>[];
  final List<Route<dynamic>> popped = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popped.add(route);
    super.didPop(route, previousRoute);
  }
}

final Map<String, NotificationRoutePageBuilder> _fakeBuilders =
    <String, NotificationRoutePageBuilder>{
  NotificationRoutes.reminder: (_) =>
      const Scaffold(body: Text('reminder-page')),
  NotificationRoutes.archive: (_) => const Scaffold(
        body: Text('archive-page'),
      ),
};

Future<_RecordingNavigatorObserver> _pumpApp(
  WidgetTester tester,
  GlobalKey<NavigatorState> navigatorKey,
) async {
  final observer = _RecordingNavigatorObserver();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: <NavigatorObserver>[observer],
      home: const Scaffold(body: Text('home-page')),
    ),
  );
  await tester.pumpAndSettle();
  // 初期 route の push を除外して数える。
  observer.pushed.clear();
  return observer;
}

void main() {
  group('NotificationTapRouter.handle', () {
    testWidgets('null は何も push しない', (tester) async {
      final key = GlobalKey<NavigatorState>();
      final observer = await _pumpApp(tester, key);
      final router = NotificationTapRouter(
        navigatorKey: key,
        pageBuilders: _fakeBuilders,
      );

      expect(router.handle(null), isFalse);
      await tester.pumpAndSettle();

      expect(observer.pushed, isEmpty);
      expect(key.currentState!.canPop(), isFalse);
    });

    testWidgets('未知 route は何も push しない', (tester) async {
      final key = GlobalKey<NavigatorState>();
      final observer = await _pumpApp(tester, key);
      final router = NotificationTapRouter(
        navigatorKey: key,
        pageBuilders: _fakeBuilders,
      );

      expect(
        router.handle(const ResolvedNotificationRoute(route: 'settings')),
        isFalse,
      );
      await tester.pumpAndSettle();

      expect(observer.pushed, isEmpty);
    });

    testWidgets('reminder は画面を push する', (tester) async {
      final key = GlobalKey<NavigatorState>();
      final observer = await _pumpApp(tester, key);
      final router = NotificationTapRouter(
        navigatorKey: key,
        pageBuilders: _fakeBuilders,
      );

      expect(
        router.handle(const ResolvedNotificationRoute(
          route: NotificationRoutes.reminder,
        )),
        isTrue,
      );
      await tester.pumpAndSettle();

      expect(observer.pushed, hasLength(1));
      expect(find.text('reminder-page'), findsOneWidget);
      expect(observer.pushed.single.settings.name, 'notification/reminder');
    });

    testWidgets('archive は画面を push し id を引き回す', (tester) async {
      final key = GlobalKey<NavigatorState>();
      final observer = await _pumpApp(tester, key);
      ResolvedNotificationRoute? received;
      final router = NotificationTapRouter(
        navigatorKey: key,
        pageBuilders: <String, NotificationRoutePageBuilder>{
          NotificationRoutes.archive: (route) {
            received = route;
            return const Scaffold(body: Text('archive-page'));
          },
        },
      );

      expect(
        router.handle(const ResolvedNotificationRoute(
          route: NotificationRoutes.archive,
          id: '2026-10-28',
        )),
        isTrue,
      );
      await tester.pumpAndSettle();

      expect(observer.pushed, hasLength(1));
      expect(find.text('archive-page'), findsOneWidget);
      expect(received?.id, '2026-10-28');
    });

    testWidgets('game は push せずに Navigator の根へ戻す', (tester) async {
      final key = GlobalKey<NavigatorState>();
      final observer = await _pumpApp(tester, key);
      final router = NotificationTapRouter(
        navigatorKey: key,
        pageBuilders: _fakeBuilders,
      );
      router.handle(
        const ResolvedNotificationRoute(route: NotificationRoutes.reminder),
      );
      await tester.pumpAndSettle();
      expect(observer.pushed, hasLength(1));

      observer.pushed.clear();
      expect(
        router.handle(
          const ResolvedNotificationRoute(route: NotificationRoutes.game),
        ),
        isTrue,
      );
      await tester.pumpAndSettle();

      expect(observer.pushed, isEmpty);
      expect(key.currentState!.canPop(), isFalse);
      expect(find.text('home-page'), findsOneWidget);
    });

    testWidgets('Navigator 未準備なら false を返し落ちない', (tester) async {
      final key = GlobalKey<NavigatorState>();
      final router = NotificationTapRouter(
        navigatorKey: key,
        pageBuilders: _fakeBuilders,
      );

      expect(
        router.handle(const ResolvedNotificationRoute(
          route: NotificationRoutes.reminder,
        )),
        isFalse,
      );
    });
  });

  group('route 対応表と resolver 許可集合の一致', () {
    test('既定対応表のキーは許可 route の部分集合で、game と合わせて全網羅する', () {
      final keys = NotificationTapRouter.defaultPageBuilders.keys.toSet();

      expect(keys.difference(NotificationTapRouter.allowedRoutes), isEmpty);
      expect(
        keys.union(<String>{NotificationRoutes.game}),
        NotificationTapRouter.allowedRoutes,
      );
      expect(
        NotificationTapRouter.allowedRoutes,
        ElectionNotificationService.allowedRoutes,
      );
    });

    test('対応表の route は resolver で解決できる', () {
      for (final route in NotificationTapRouter.defaultPageBuilders.keys) {
        final payload = NotificationRouteResolver.buildPayload(route);
        final resolved = NotificationRouteResolver.resolve(
          payload,
          allowedRoutes: NotificationTapRouter.allowedRoutes,
        );
        expect(resolved?.route, route);
      }
    });
  });

  group('ElectionNotificationService の保留 route', () {
    test('未配線の payload は pendingRoute に積まれ、1度だけ取り出せる', () {
      final service = ElectionNotificationService();
      service.handlePayload(
        NotificationRouteResolver.buildPayload(NotificationRoutes.archive),
      );

      final first = service.consumePendingRoute();
      expect(first, isNotNull);
      expect(first!.route, NotificationRoutes.archive);
      expect(service.consumePendingRoute(), isNull);
    });

    test('破損・未知 payload は pendingRoute に積まれない', () {
      final service = ElectionNotificationService();
      service.handlePayload('not-json');
      service.handlePayload(null);
      service.handlePayload('{"route":"unknown"}');

      expect(service.consumePendingRoute(), isNull);
    });

    test('配線済みなら handler へ1度だけ引き渡し、pending は残らない', () {
      final received = <ResolvedNotificationRoute>[];
      final service = ElectionNotificationService(
        onRouteSelected: received.add,
      );

      service.handlePayload(
        NotificationRouteResolver.buildPayload(NotificationRoutes.reminder),
      );

      expect(received, hasLength(1));
      expect(received.single.route, NotificationRoutes.reminder);
      expect(service.consumePendingRoute(), isNull);
    });

    test('配線が後から差し込まれても保留 route を取りこぼさない', () {
      final received = <ResolvedNotificationRoute>[];
      final service = ElectionNotificationService();
      service.handlePayload(
        NotificationRouteResolver.buildPayload(NotificationRoutes.game),
      );
      expect(received, isEmpty);

      service.onRouteSelected = received.add;

      expect(received, hasLength(1));
      expect(received.single.route, NotificationRoutes.game);
      expect(service.consumePendingRoute(), isNull);
    });
  });

  group('通知タップ → 画面遷移の結線', () {
    testWidgets('payload 解決 → router が画面を push し、pending は消費される',
        (tester) async {
      final key = GlobalKey<NavigatorState>();
      final observer = await _pumpApp(tester, key);
      final router = NotificationTapRouter(
        navigatorKey: key,
        pageBuilders: _fakeBuilders,
      );
      final service = ElectionNotificationService(
        onRouteSelected: router.handle,
      );

      service.handlePayload(NotificationRouteResolver.buildPayload(
        NotificationRoutes.archive,
        id: 'e-1',
      ));
      await tester.pumpAndSettle();

      expect(observer.pushed, hasLength(1));
      expect(find.text('archive-page'), findsOneWidget);
      expect(service.consumePendingRoute(), isNull);
    });
  });
}
