import 'package:flutter/widgets.dart';

/// アプリについて画面の試験用Key。既存 AppKeys は変更しない。
class AboutAppKeys {
  AboutAppKeys._();

  static const aboutScreen = Key('about_screen');
  static const aboutLicenseTile = Key('about_license_tile');
  static const aboutPrivacyTile = Key('about_privacy_tile');
  static const aboutContactTile = Key('about_contact_tile');
  static const aboutPrivacyDialog = Key('about_privacy_dialog');
  static const aboutContactDialog = Key('about_contact_dialog');
  static const aboutPrivacyCopyButton = Key('about_privacy_copy_button');
  static const aboutContactCopyButton = Key('about_contact_copy_button');
  static const aboutSnackBar = Key('about_snack_bar');

  // Home 導線
  static const homeAboutButton = Key('home_about_button');
}
