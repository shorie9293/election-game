import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/features/about/domain/about_info.dart';

void main() {
  group('AboutInfo', () {
    test('既定の kAboutInfo は妥当な値を持つ', () {
      expect(kAboutInfo.appName, '選挙ゲーム');
      expect(kAboutInfo.version, isNotEmpty);
      expect(kAboutInfo.contactEmail, 'horie.shunta@gmail.com');
      expect(kAboutInfo.privacyPolicyUrl, 'https://yoppala.in/privacy');
      expect(kAboutInfo.tagline, isNotEmpty);
    });

    test('appName の空文字は ArgumentError', () {
      expect(
        () => AboutInfo(
          appName: '',
          version: '1.0.0',
          contactEmail: 'a@b.c',
          privacyPolicyUrl: 'https://example.com',
          tagline: 'tagline',
        ),
        throwsArgumentError,
      );
    });

    test('version の空文字は ArgumentError', () {
      expect(
        () => AboutInfo(
          appName: '選挙ゲーム',
          version: '',
          contactEmail: 'a@b.c',
          privacyPolicyUrl: 'https://example.com',
          tagline: 'tagline',
        ),
        throwsArgumentError,
      );
    });

    test('contactEmail の空文字は ArgumentError', () {
      expect(
        () => AboutInfo(
          appName: '選挙ゲーム',
          version: '1.0.0',
          contactEmail: '',
          privacyPolicyUrl: 'https://example.com',
          tagline: 'tagline',
        ),
        throwsArgumentError,
      );
    });

    test('privacyPolicyUrl の空文字は ArgumentError', () {
      expect(
        () => AboutInfo(
          appName: '選挙ゲーム',
          version: '1.0.0',
          contactEmail: 'a@b.c',
          privacyPolicyUrl: '',
          tagline: 'tagline',
        ),
        throwsArgumentError,
      );
    });

    test('tagline の空文字は ArgumentError', () {
      expect(
        () => AboutInfo(
          appName: '選挙ゲーム',
          version: '1.0.0',
          contactEmail: 'a@b.c',
          privacyPolicyUrl: 'https://example.com',
          tagline: '',
        ),
        throwsArgumentError,
      );
    });
  });
}
