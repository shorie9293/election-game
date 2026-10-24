import 'package:flutter/material.dart';
import 'package:takamagahara_ui/takamagahara_ui.dart' hide AppKeys;

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/features/crossapp/data/crossapp_link_code_repository.dart';
import 'package:election_game/features/crossapp/domain/election_reward_event.dart';

/// クロスアプリ連携（学びの循環）の設定画面。
///
/// rpg-task のリンク設定と同じコード（tsundoku の user_id）を入力すると、
/// 選挙確定・クイズ完了が共有ストレージ経由で報酬（コイン/EXP/称号）に
/// 変わる。ここでは連携コードの保存・解除のみを行う。
class CrossAppLinkSettingsScreen extends StatefulWidget {
  /// 連携コードの永続化先（試練では差し替え可能）
  final CrossAppLinkCodeRepository repository;

  const CrossAppLinkSettingsScreen({
    super.key,
    this.repository = const SharedPreferencesCrossAppLinkCodeRepository(),
  });

  @override
  State<CrossAppLinkSettingsScreen> createState() =>
      _CrossAppLinkSettingsScreenState();
}

class _CrossAppLinkSettingsScreenState
    extends State<CrossAppLinkSettingsScreen> {
  /// 連携コードの最低文字数（先頭8文字を rpg-task が照合に使うため）
  static const minCodeLength = 8;

  final TextEditingController _controller = TextEditingController();
  String? _savedCode;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    String? code;
    try {
      code = await widget.repository.load();
    } catch (_) {
      code = null;
    }
    if (!mounted) return;
    setState(() {
      _savedCode = code;
      _controller.text = code ?? '';
    });
  }

  Future<void> _save() async {
    final code = normalizeLinkCode(_controller.text);
    if (code.length < minCodeLength) {
      setState(() => _error = '連携コードは8文字以上で入力してください');
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      await widget.repository.save(code);
      if (!mounted) return;
      setState(() {
        _savedCode = code;
        _controller.text = code;
        _busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('連携コードを保存しました')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '連携コードを保存できませんでした';
        _busy = false;
      });
    }
  }

  Future<void> _clear() async {
    setState(() => _busy = true);
    try {
      await widget.repository.clear();
    } catch (_) {
      // 解除失敗は握りつぶす（表示は現状維持）
    }
    if (!mounted) return;
    setState(() {
      _savedCode = null;
      _controller.clear();
      _error = null;
      _busy = false;
    });
  }

  /// 表示用のマスク（先頭8文字＋省略記号）。コード全体は見せない。
  String _maskedCode(String code) => '${exportUserIdFrom(code)}…';

  @override
  Widget build(BuildContext context) {
    final saved = _savedCode;
    return Scaffold(
      backgroundColor: RetroPalette.bgDark,
      appBar: AppBar(
        title: const Text('クロスアプリ連携', key: AppKeys.crossAppLinkTitle),
        backgroundColor: RetroPalette.panelBg,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '「学びの循環」で、選挙とクイズの学びが rpg-task の報酬'
                '（コイン・EXP・称号）に変わります。\n'
                'rpg-task の連携設定と同じコードを入力してください。',
                style: TextStyle(
                  color: RetroPalette.textNormal,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                key: AppKeys.crossAppLinkStatus,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: RetroPalette.panelBg,
                  border: Border.all(
                    color: saved == null
                        ? RetroPalette.panelBorder
                        : RetroPalette.success,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      saved == null ? Icons.link_off : Icons.link,
                      color: saved == null
                          ? RetroPalette.textAccent
                          : RetroPalette.success,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        saved == null
                            ? '未連携（報酬は書き出されません）'
                            : '連携済み：${_maskedCode(saved)}',
                        style: TextStyle(
                          color: saved == null
                              ? RetroPalette.textNormal
                              : RetroPalette.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: AppKeys.crossAppLinkCodeInput,
                controller: _controller,
                style: const TextStyle(color: RetroPalette.textNormal),
                decoration: InputDecoration(
                  labelText: '連携コード',
                  hintText: 'rpg-task の連携設定と同じコード',
                  errorText: _error,
                  errorStyle: const TextStyle(color: RetroPalette.danger),
                  filled: true,
                  fillColor: RetroPalette.panelBg,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    key: AppKeys.crossAppLinkError,
                    style: const TextStyle(color: RetroPalette.danger),
                  ),
                ),
              const SizedBox(height: 16),
              DivineButton(
                key: AppKeys.crossAppLinkSaveButton,
                onPressed: _busy ? null : _save,
                width: double.infinity,
                child: const Text('保存する'),
              ),
              const SizedBox(height: 8),
              DivineButton(
                key: AppKeys.crossAppLinkClearButton,
                onPressed: _busy || saved == null ? null : _clear,
                width: double.infinity,
                child: const Text('連携を解除する'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
