import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:election_game/features/about/domain/about_info.dart';
import 'package:election_game/features/about/presentation/about_app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';

/// アプリについて画面（バージョン・OSSライセンス・プライバシー・問い合わせ）。
class AboutScreen extends StatelessWidget {
  final AboutInfo info;

  const AboutScreen({super.key, this.info = kAboutInfo});

  void _copy(BuildContext context, String text) {
    try {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            key: AboutAppKeys.aboutSnackBar,
            content: Text('コピーしました: $text'),
          ),
        );
    } catch (_) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            key: AboutAppKeys.aboutSnackBar,
            content: const Text('コピーに失敗しました'),
          ),
        );
    }
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        key: AboutAppKeys.aboutPrivacyDialog,
        backgroundColor: RetroPalette.panelBg,
        title: const Text('プライバシーポリシー'),
        content: Text(info.privacyPolicyUrl),
        actions: [
          TextButton(
            key: AboutAppKeys.aboutPrivacyCopyButton,
            onPressed: () => _copy(context, info.privacyPolicyUrl),
            child: const Text('コピー'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showContact(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        key: AboutAppKeys.aboutContactDialog,
        backgroundColor: RetroPalette.panelBg,
        title: const Text('問い合わせ'),
        content: Text(info.contactEmail),
        actions: [
          TextButton(
            key: AboutAppKeys.aboutContactCopyButton,
            onPressed: () => _copy(context, info.contactEmail),
            child: const Text('コピー'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: AboutAppKeys.aboutScreen,
      backgroundColor: RetroPalette.bgDark,
      appBar: AppBar(title: const Text('アプリについて')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            info.appName,
            style: const TextStyle(
              color: RetroPalette.gold,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'v${info.version}',
            style: const TextStyle(color: RetroPalette.textNormal),
          ),
          const SizedBox(height: 8),
          Text(
            info.tagline,
            style:
                const TextStyle(color: RetroPalette.textNormal, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ListTile(
            key: AboutAppKeys.aboutLicenseTile,
            leading:
                const Icon(Icons.description, color: RetroPalette.textAccent),
            title: const Text(
              'OSSライセンス',
              style: TextStyle(color: RetroPalette.textNormal),
            ),
            onTap: () => showLicensePage(
              context: context,
              applicationName: info.appName,
              applicationVersion: info.version,
            ),
          ),
          ListTile(
            key: AboutAppKeys.aboutPrivacyTile,
            leading:
                const Icon(Icons.privacy_tip, color: RetroPalette.textAccent),
            title: const Text(
              'プライバシーポリシー',
              style: TextStyle(color: RetroPalette.textNormal),
            ),
            onTap: () => _showPrivacyPolicy(context),
          ),
          ListTile(
            key: AboutAppKeys.aboutContactTile,
            leading:
                const Icon(Icons.mail_outline, color: RetroPalette.textAccent),
            title: const Text(
              '問い合わせ',
              style: TextStyle(color: RetroPalette.textNormal),
            ),
            onTap: () => _showContact(context),
          ),
        ],
      ),
    );
  }
}
