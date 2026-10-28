/// 「アプリについて」画面に表示する静的情報。
///
/// Dart の制約上、const コンストラクタは本体を持てないため、
/// 検証つきの非constコンストラクタと、検証済みリテラル専用の
/// 内部用 const コンストラクタを分けている。
class AboutInfo {
  final String appName;
  final String version;
  final String contactEmail;
  final String privacyPolicyUrl;
  final String tagline;

  /// 空文字の項目は ArgumentError（不変条件）。
  AboutInfo({
    required this.appName,
    required this.version,
    required this.contactEmail,
    required this.privacyPolicyUrl,
    required this.tagline,
  }) {
    if (appName.isEmpty) {
      throw ArgumentError.value(appName, 'appName', '空文字は禁止');
    }
    if (version.isEmpty) {
      throw ArgumentError.value(version, 'version', '空文字は禁止');
    }
    if (contactEmail.isEmpty) {
      throw ArgumentError.value(contactEmail, 'contactEmail', '空文字は禁止');
    }
    if (privacyPolicyUrl.isEmpty) {
      throw ArgumentError.value(privacyPolicyUrl, 'privacyPolicyUrl', '空文字は禁止');
    }
    if (tagline.isEmpty) {
      throw ArgumentError.value(tagline, 'tagline', '空文字は禁止');
    }
  }

  /// 検証済みリテラル専用（[kAboutInfo] のみ内部使用）。
  const AboutInfo._({
    required this.appName,
    required this.version,
    required this.contactEmail,
    required this.privacyPolicyUrl,
    required this.tagline,
  });
}

/// 既定値。version は pubspec.yaml の version と同期を保つこと
/// （test/features/about/about_version_sync_test.dart が検証する）。
const kAboutInfo = AboutInfo._(
  appName: '選挙ゲーム',
  version: '1.0.34+41',
  contactEmail: 'horie.shunta@gmail.com',
  privacyPolicyUrl: 'https://www.yoppala.in/privacy',
  tagline: '選挙を遊びながら政治の仕組みを学ぶ、生活シミュレーション。',
);
