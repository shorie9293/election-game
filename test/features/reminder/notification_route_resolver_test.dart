import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/features/reminder/domain/notification_route_resolver.dart';

void main() {
  const allowed = NotificationRoutes.all;

  group('NotificationRouteResolver.resolve', () {
    test('正常な payload を解決する（route のみ）', () {
      final resolved = NotificationRouteResolver.resolve(
        '{"route":"game"}',
        allowedRoutes: allowed,
      );

      expect(resolved, isNotNull);
      expect(resolved!.route, NotificationRoutes.game);
      expect(resolved.id, isNull);
    });

    test('正常な payload を解決する（route + id）', () {
      final resolved = NotificationRouteResolver.resolve(
        '{"route":"archive","id":"2026-10-28"}',
        allowedRoutes: allowed,
      );

      expect(resolved, const ResolvedNotificationRoute(
        route: NotificationRoutes.archive,
        id: '2026-10-28',
      ));
    });

    test('null payload は null', () {
      expect(
        NotificationRouteResolver.resolve(null, allowedRoutes: allowed),
        isNull,
      );
    });

    test('空文字・空白のみは null', () {
      expect(
        NotificationRouteResolver.resolve('', allowedRoutes: allowed),
        isNull,
      );
      expect(
        NotificationRouteResolver.resolve('   ', allowedRoutes: allowed),
        isNull,
      );
    });

    test('JSON として破損した payload は null', () {
      expect(
        NotificationRouteResolver.resolve('game', allowedRoutes: allowed),
        isNull,
      );
      expect(
        NotificationRouteResolver.resolve('{"route":', allowedRoutes: allowed),
        isNull,
      );
    });

    test('JSON だが object でない payload は null', () {
      expect(
        NotificationRouteResolver.resolve('["game"]', allowedRoutes: allowed),
        isNull,
      );
      expect(
        NotificationRouteResolver.resolve('"game"', allowedRoutes: allowed),
        isNull,
      );
    });

    test('route キーが無い／文字列でない／空の payload は null', () {
      expect(
        NotificationRouteResolver.resolve('{}', allowedRoutes: allowed),
        isNull,
      );
      expect(
        NotificationRouteResolver.resolve('{"route":1}', allowedRoutes: allowed),
        isNull,
      );
      expect(
        NotificationRouteResolver.resolve('{"route":""}', allowedRoutes: allowed),
        isNull,
      );
      expect(
        NotificationRouteResolver.resolve(
          '{"route":"   "}',
          allowedRoutes: allowed,
        ),
        isNull,
      );
    });

    test('許可されていない route は null', () {
      expect(
        NotificationRouteResolver.resolve(
          '{"route":"settings"}',
          allowedRoutes: allowed,
        ),
        isNull,
      );
      expect(
        NotificationRouteResolver.resolve(
          '{"route":"archive"}',
          allowedRoutes: const {NotificationRoutes.game},
        ),
        isNull,
      );
    });

    test('id が文字列でない payload は null', () {
      expect(
        NotificationRouteResolver.resolve(
          '{"route":"game","id":42}',
          allowedRoutes: allowed,
        ),
        isNull,
      );
    });

    test('id が空文字なら null に正規化される', () {
      final resolved = NotificationRouteResolver.resolve(
        '{"route":"game","id":"  "}',
        allowedRoutes: allowed,
      );

      expect(resolved, const ResolvedNotificationRoute(
        route: NotificationRoutes.game,
      ));
    });

    test('前後の空白を含む payload も解決する', () {
      final resolved = NotificationRouteResolver.resolve(
        '  {"route":"reminder"}  ',
        allowedRoutes: allowed,
      );

      expect(resolved?.route, NotificationRoutes.reminder);
    });
  });

  group('NotificationRouteResolver.buildPayload', () {
    test('id 無しは route のみの JSON になる', () {
      final payload = NotificationRouteResolver.buildPayload(
        NotificationRoutes.game,
      );

      expect(payload, '{"route":"game"}');
    });

    test('id 有りは route と id の JSON になる', () {
      final payload = NotificationRouteResolver.buildPayload(
        NotificationRoutes.archive,
        id: 'election-7',
      );

      expect(payload, '{"route":"archive","id":"election-7"}');
    });

    test('buildPayload → resolve の往復で値が保たれる', () {
      for (final route in NotificationRoutes.all) {
        final payload = NotificationRouteResolver.buildPayload(route, id: 'x1');
        expect(
          NotificationRouteResolver.resolve(payload, allowedRoutes: allowed),
          ResolvedNotificationRoute(route: route, id: 'x1'),
        );
      }
    });
  });

  group('ResolvedNotificationRoute', () {
    test('同じ route と id は等価（hashCode も一致）', () {
      const a = ResolvedNotificationRoute(route: 'game', id: '1');
      const b = ResolvedNotificationRoute(route: 'game', id: '1');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('route か id が違えば非等価', () {
      expect(
        const ResolvedNotificationRoute(route: 'game'),
        isNot(const ResolvedNotificationRoute(route: 'archive')),
      );
      expect(
        const ResolvedNotificationRoute(route: 'game', id: '1'),
        isNot(const ResolvedNotificationRoute(route: 'game', id: '2')),
      );
    });

    test('toString に route と id が現れる', () {
      expect(
        const ResolvedNotificationRoute(route: 'game', id: '9').toString(),
        contains('game'),
      );
    });
  });
}
