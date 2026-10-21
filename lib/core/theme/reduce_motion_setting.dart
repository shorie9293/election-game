import 'package:flutter/material.dart';

/// 動きの削減（Reduce Motion）設定
///
/// - [system] 端末の「視差効果を減らす」等の設定に従う。
/// - [off] 利用者が明示的に動きを有効化する（端末設定より優先）。
/// - [on] 利用者が明示的に動きを減らす（端末設定より優先）。
///
/// `off` が存在する理由: 端末側で動きが抑制されていても、
/// このアプリだけはアニメーションを楽しみたい利用者を尊重するため。
enum ReduceMotionSetting {
  system('system', 'システムに従う', Icons.brightness_auto_outlined),
  off('off', '動きを有効', Icons.animation),
  on('on', '動きを減らす', Icons.motion_photos_off_outlined);

  const ReduceMotionSetting(this.storageKey, this.label, this.icon);

  /// SharedPreferences に保存する識別子
  final String storageKey;

  /// 画面表示用ラベル
  final String label;

  /// 選択肢表示用アイコン
  final IconData icon;

  /// 保存キーから復元する。未保存(null)/不正値は [system] 扱い。
  static ReduceMotionSetting fromStorageKey(String? key) {
    for (final setting in ReduceMotionSetting.values) {
      if (setting.storageKey == key) return setting;
    }
    return ReduceMotionSetting.system;
  }

  /// 選択順に巡回する（system→off→on→system）。
  ReduceMotionSetting get next {
    final index = ReduceMotionSetting.values.indexOf(this);
    return ReduceMotionSetting
        .values[(index + 1) % ReduceMotionSetting.values.length];
  }

  /// 明示的な強制値。system は null（端末設定に委ねる）。
  bool? get forceDisableAnimations {
    switch (this) {
      case ReduceMotionSetting.system:
        return null;
      case ReduceMotionSetting.off:
        return false;
      case ReduceMotionSetting.on:
        return true;
    }
  }
}

/// [setting] を MediaQueryData に反映する。
///
/// 強制値が無い（[ReduceMotionSetting.system]）場合は [data] をそのまま返し、
/// 端末設定を尊重する。強制値がある場合のみ `disableAnimations` を上書きする。
MediaQueryData applyReduceMotion(
  MediaQueryData data,
  ReduceMotionSetting setting,
) {
  final forced = setting.forceDisableAnimations;
  if (forced == null) return data;
  return data.copyWith(disableAnimations: forced);
}
