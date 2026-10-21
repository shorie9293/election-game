import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:election_game/core/theme/reduce_motion_repository.dart';
import 'package:election_game/core/theme/reduce_motion_setting.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesReduceMotionRepository', () {
    late SharedPreferencesReduceMotionRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = const SharedPreferencesReduceMotionRepository();
    });

    test('未保存時は null を返す', () async {
      expect(await repository.load(), isNull);
    });

    test('save → load で roundtrip する', () async {
      await repository.save(ReduceMotionSetting.on);
      expect(await repository.load(), ReduceMotionSetting.on);

      await repository.save(ReduceMotionSetting.off);
      expect(await repository.load(), ReduceMotionSetting.off);

      await repository.save(ReduceMotionSetting.system);
      expect(await repository.load(), ReduceMotionSetting.system);
    });

    test('保存キーは election_reduce_motion', () async {
      await repository.save(ReduceMotionSetting.on);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('election_reduce_motion'), 'on');
    });

    test('不正値が保存されていれば null を返す', () async {
      SharedPreferences.setMockInitialValues({
        'election_reduce_motion': 'invalid_value',
      });
      expect(await repository.load(), isNull);
    });
  });

  group('InMemoryReduceMotionRepository', () {
    test('save で saved/saveCount が更新され、load が復元する', () async {
      final repository = InMemoryReduceMotionRepository();
      expect(await repository.load(), isNull);
      expect(repository.saveCount, 0);

      await repository.save(ReduceMotionSetting.on);
      expect(repository.saved, ReduceMotionSetting.on);
      expect(repository.saveCount, 1);
      expect(await repository.load(), ReduceMotionSetting.on);
    });

    test('初期値付きで生成でき、load がその値を返す', () async {
      final repository =
          InMemoryReduceMotionRepository(ReduceMotionSetting.off);
      expect(await repository.load(), ReduceMotionSetting.off);
    });
  });
}
