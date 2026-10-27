import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/features/about/domain/about_info.dart';
import 'package:election_game/features/about/domain/external_url_opener.dart';
import 'package:election_game/features/about/presentation/about_app_keys.dart';
import 'package:election_game/features/about/presentation/about_screen.dart';

/// 「アプリについて」の外部リンク導線（url_launcher 抽象越し）の試練。
///
/// 実網・実ブラウザは撃たない。`urlOpener` にフェイクを注入し、
/// 「どの URI が渡されたか」「失敗時に従来のコピー導線へ退避するか」を検証する。
void main() {
  final info = AboutInfo(
    appName: 'テストアプリ',
    version: '9.9.9',
    contactEmail: 'test@example.com',
    privacyPolicyUrl: 'https://example.com/privacy',
    tagline: 'テスト用タグライン',
  );

  Future<void> pumpWith(
    WidgetTester tester, {
    required ExternalUrlOpener opener,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: AboutScreen(info: info, urlOpener: opener)),
    );
    await tester.pumpAndSettle();
  }

  group('ExternalUrlOpener 純粋ヘルパ', () {
    test('externalUri は前後の空白を除去した URI を返す', () {
      expect(
        externalUri('  https://www.yoppala.in/privacy  '),
        Uri.parse('https://www.yoppala.in/privacy'),
      );
    });

    test('externalUri はスキーム無し・空・空白のみに null を返す', () {
      expect(externalUri('yoppala.in/privacy'), isNull);
      expect(externalUri(''), isNull);
      expect(externalUri('   '), isNull);
    });

    test('mailtoUri はメールアドレスを mailto: へ変換する（空白除去）', () {
      expect(
        mailtoUri(' horie.shunta@gmail.com '),
        Uri.parse('mailto:horie.shunta@gmail.com'),
      );
    });
  });

  group('プライバシーポリシーの外部遷移', () {
    testWidgets('タップでポリシーURLがランチャーへ渡り、ダイアログは開かない',
        (tester) async {
      final opened = <Uri>[];
      await pumpWith(tester, opener: (uri) async {
        opened.add(uri);
        return true;
      });

      await tester.tap(find.byKey(AboutAppKeys.aboutPrivacyTile));
      await tester.pumpAndSettle();

      expect(opened, [Uri.parse('https://example.com/privacy')]);
      expect(find.byKey(AboutAppKeys.aboutPrivacyDialog), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('ランチャーが false を返したら従来のコピーダイアログへ退避する',
        (tester) async {
      await pumpWith(tester, opener: (_) async => false);

      await tester.tap(find.byKey(AboutAppKeys.aboutPrivacyTile));
      await tester.pumpAndSettle();

      expect(find.byKey(AboutAppKeys.aboutPrivacyDialog), findsOneWidget);
      expect(find.text('https://example.com/privacy'), findsOneWidget);
      expect(find.byKey(AboutAppKeys.aboutPrivacyCopyButton), findsOneWidget);
    });

    testWidgets('ランチャーが例外を投げても画面は壊れずダイアログへ退避する',
        (tester) async {
      await pumpWith(
        tester,
        opener: (_) async => throw StateError('no browser'),
      );

      await tester.tap(find.byKey(AboutAppKeys.aboutPrivacyTile));
      await tester.pumpAndSettle();

      expect(find.byKey(AboutAppKeys.aboutPrivacyDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('問い合わせの外部遷移', () {
    testWidgets('タップで mailto: URI がランチャーへ渡り、ダイアログは開かない',
        (tester) async {
      final opened = <Uri>[];
      await pumpWith(tester, opener: (uri) async {
        opened.add(uri);
        return true;
      });

      await tester.tap(find.byKey(AboutAppKeys.aboutContactTile));
      await tester.pumpAndSettle();

      expect(opened, [Uri.parse('mailto:test@example.com')]);
      expect(find.byKey(AboutAppKeys.aboutContactDialog), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('ランチャーが false を返したら問い合わせダイアログへ退避する',
        (tester) async {
      await pumpWith(tester, opener: (_) async => false);

      await tester.tap(find.byKey(AboutAppKeys.aboutContactTile));
      await tester.pumpAndSettle();

      expect(find.byKey(AboutAppKeys.aboutContactDialog), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.byKey(AboutAppKeys.aboutContactCopyButton), findsOneWidget);
    });

    testWidgets('ランチャーが例外を投げてもクラッシュせずダイアログへ退避する',
        (tester) async {
      await pumpWith(
        tester,
        opener: (_) async => throw StateError('no mail app'),
      );

      await tester.tap(find.byKey(AboutAppKeys.aboutContactTile));
      await tester.pumpAndSettle();

      expect(find.byKey(AboutAppKeys.aboutContactDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('既定のパラメータ', () {
    testWidgets('urlOpener を省略した既定コンストラクタでも画面が描画される',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: AboutScreen(info: info)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(AboutAppKeys.aboutScreen), findsOneWidget);
      expect(find.byKey(AboutAppKeys.aboutPrivacyTile), findsOneWidget);
      expect(find.byKey(AboutAppKeys.aboutContactTile), findsOneWidget);
    });
  });
}
