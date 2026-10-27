import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/features/about/domain/about_info.dart';
import 'package:election_game/features/about/presentation/about_app_keys.dart';
import 'package:election_game/features/about/presentation/about_screen.dart';

class ClipboardCapture {
  String? text;
}

void main() {
  final info = AboutInfo(
    appName: 'テストアプリ',
    version: '9.9.9',
    contactEmail: 'test@example.com',
    privacyPolicyUrl: 'https://example.com/privacy',
    tagline: 'テスト用タグライン',
  );

  /// Clipboard の platform channel をテスト内に模擬する。
  void mockClipboard(WidgetTester tester, ClipboardCapture capture) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          final args = call.arguments as Map<Object?, Object?>;
          capture.text = args['text'] as String?;
          return null;
        }
        return null;
      },
    );
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: AboutScreen(
          info: info,
          // ダイアログ退避経路を検証するため、外部起動は必ず失敗させる。
          urlOpener: (_) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('アプリ名と注入した version が表示される', (tester) async {
    await pumpScreen(tester);
    expect(find.text('テストアプリ'), findsOneWidget);
    expect(find.text('v9.9.9'), findsOneWidget);
    expect(find.text('テスト用タグライン'), findsOneWidget);
  });

  testWidgets('OSSライセンス タップで LicensePage へ遷移する', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.byKey(AboutAppKeys.aboutLicenseTile));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('プライバシー タップで URL を含むダイアログが出る', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.byKey(AboutAppKeys.aboutPrivacyTile));
    await tester.pumpAndSettle();
    expect(find.byKey(AboutAppKeys.aboutPrivacyDialog), findsOneWidget);
    expect(find.text('https://example.com/privacy'), findsOneWidget);
  });

  testWidgets('プライバシーURLのコピーでクリップボードに反映され SnackBar が出る', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.byKey(AboutAppKeys.aboutPrivacyTile));
    await tester.pumpAndSettle();
    final captured = ClipboardCapture();
    mockClipboard(tester, captured);
    await tester.tap(find.byKey(AboutAppKeys.aboutPrivacyCopyButton));
    await tester.pumpAndSettle();
    expect(captured.text, 'https://example.com/privacy');
    expect(find.byKey(AboutAppKeys.aboutSnackBar), findsOneWidget);
  });

  testWidgets('問い合わせ タップでメールアドレスを含むダイアログが出る', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.byKey(AboutAppKeys.aboutContactTile));
    await tester.pumpAndSettle();
    expect(find.byKey(AboutAppKeys.aboutContactDialog), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);
  });

  testWidgets('メールアドレスのコピーでクリップボードに反映され SnackBar が出る', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.byKey(AboutAppKeys.aboutContactTile));
    await tester.pumpAndSettle();
    final captured = ClipboardCapture();
    mockClipboard(tester, captured);
    await tester.tap(find.byKey(AboutAppKeys.aboutContactCopyButton));
    await tester.pumpAndSettle();
    expect(captured.text, 'test@example.com');
    expect(find.byKey(AboutAppKeys.aboutSnackBar), findsOneWidget);
  });
}
