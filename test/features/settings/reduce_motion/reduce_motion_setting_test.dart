import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/core/theme/reduce_motion_setting.dart';

void main() {
  group('ReduceMotionSetting', () {
    test('fromStorageKey: 未知値は system', () {
      expect(
        ReduceMotionSetting.fromStorageKey('unknown_value'),
        ReduceMotionSetting.system,
      );
    });

    test('fromStorageKey: null は system', () {
      expect(ReduceMotionSetting.fromStorageKey(null), ReduceMotionSetting.system);
    });

    test('fromStorageKey: 既知の storageKey を復元する', () {
      expect(ReduceMotionSetting.fromStorageKey('on'), ReduceMotionSetting.on);
      expect(ReduceMotionSetting.fromStorageKey('off'), ReduceMotionSetting.off);
      expect(
        ReduceMotionSetting.fromStorageKey('system'),
        ReduceMotionSetting.system,
      );
    });

    test('next は system→off→on→system と巡回する', () {
      expect(ReduceMotionSetting.system.next, ReduceMotionSetting.off);
      expect(ReduceMotionSetting.off.next, ReduceMotionSetting.on);
      expect(ReduceMotionSetting.on.next, ReduceMotionSetting.system);
    });

    test('forceDisableAnimations: on=true / off=false / system=null', () {
      expect(ReduceMotionSetting.on.forceDisableAnimations, isTrue);
      expect(ReduceMotionSetting.off.forceDisableAnimations, isFalse);
      expect(ReduceMotionSetting.system.forceDisableAnimations, isNull);
    });

    test('applyReduceMotion: system は端末設定をそのまま尊重する', () {
      const data = MediaQueryData(disableAnimations: true);
      final result = applyReduceMotion(data, ReduceMotionSetting.system);
      expect(result.disableAnimations, isTrue);

      const data2 = MediaQueryData(disableAnimations: false);
      expect(
        applyReduceMotion(data2, ReduceMotionSetting.system).disableAnimations,
        isFalse,
      );
    });

    test('applyReduceMotion: on は disableAnimations=true を強制する', () {
      const data = MediaQueryData(disableAnimations: false);
      final result = applyReduceMotion(data, ReduceMotionSetting.on);
      expect(result.disableAnimations, isTrue);
    });

    test('applyReduceMotion: off は disableAnimations=false を強制する', () {
      const data = MediaQueryData(disableAnimations: true);
      final result = applyReduceMotion(data, ReduceMotionSetting.off);
      expect(result.disableAnimations, isFalse);
    });
  });
}
