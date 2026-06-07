import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';

void main() {
  group('Job enum', () {
    test('全ての職業が定義されている', () {
      expect(Job.values.length, 10);
      expect(Job.values, contains(Job.farmer));
      expect(Job.values, contains(Job.fisher));
      expect(Job.values, contains(Job.carpenter));
      expect(Job.values, contains(Job.merchant));
      expect(Job.values, contains(Job.teacher));
      expect(Job.values, contains(Job.doctor));
      expect(Job.values, contains(Job.official));
      expect(Job.values, contains(Job.artisan));
      expect(Job.values, contains(Job.student));
      expect(Job.values, contains(Job.unemployed));
    });

    test('Jobに日本語表示がある', () {
      expect(Job.farmer.label, '農家');
      expect(Job.fisher.label, '漁師');
      expect(Job.carpenter.label, '大工');
      expect(Job.merchant.label, '商人');
      expect(Job.teacher.label, '教師');
      expect(Job.doctor.label, '医者');
      expect(Job.official.label, '役人');
      expect(Job.artisan.label, '職人');
      expect(Job.student.label, '学生');
      expect(Job.unemployed.label, '無職');
    });
  });

  group('Concern enum', () {
    test('全ての関心事が定義されている', () {
      expect(Concern.values.length, 8);
      expect(Concern.values, contains(Concern.agriculture));
      expect(Concern.values, contains(Concern.economy));
      expect(Concern.values, contains(Concern.education));
      expect(Concern.values, contains(Concern.employment));
      expect(Concern.values, contains(Concern.environment));
      expect(Concern.values, contains(Concern.healthcare));
      expect(Concern.values, contains(Concern.safety));
      expect(Concern.values, contains(Concern.tax));
    });

    test('Concernに日本語表示がある', () {
      expect(Concern.agriculture.label, '農業政策');
      expect(Concern.economy.label, '経済政策');
      expect(Concern.education.label, '教育政策');
      expect(Concern.employment.label, '雇用政策');
      expect(Concern.environment.label, '環境政策');
      expect(Concern.healthcare.label, '医療政策');
      expect(Concern.safety.label, '治安政策');
      expect(Concern.tax.label, '税制');
    });
  });

  group('LifeParamKeys', () {
    test('全てのライフパラメータキーが定義されている', () {
      expect(LifeParamKeys.all.length, 6);
      expect(LifeParamKeys.all, contains('lifeCost'));
      expect(LifeParamKeys.all, contains('healthcare'));
      expect(LifeParamKeys.all, contains('education'));
      expect(LifeParamKeys.all, contains('employment'));
      expect(LifeParamKeys.all, contains('environment'));
      expect(LifeParamKeys.all, contains('safety'));
    });

    test('日本語表示が取得できる', () {
      expect(LifeParamKeys.label('lifeCost'), '💰 生活費');
      expect(LifeParamKeys.label('healthcare'), '🏥 医療');
      expect(LifeParamKeys.label('education'), '🏫 教育');
      expect(LifeParamKeys.label('employment'), '🏭 仕事');
      expect(LifeParamKeys.label('environment'), '🌳 環境');
      expect(LifeParamKeys.label('safety'), '🚔 治安');
    });

    test('未知のキーは空文字を返す', () {
      expect(LifeParamKeys.label('unknown'), '');
    });
  });

  group('Citizen model', () {
    test('Citizenを生成できる', () {
      final citizen = Citizen(
        name: 'テスト市民',
        job: Job.farmer,
        concerns: [Concern.agriculture, Concern.environment],
        lifeParams: {
          'lifeCost': 40,
          'healthcare': 50,
          'education': 50,
          'employment': 50,
          'environment': 70,
          'safety': 50,
        },
      );

      expect(citizen.name, 'テスト市民');
      expect(citizen.job, Job.farmer);
      expect(citizen.concerns.length, 2);
      expect(citizen.lifeParams['environment'], 70);
    });

    test('Citizen.initialで職業ごとの初期値が設定される', () {
      final farmer = Citizen.initial(Job.farmer);
      expect(farmer.lifeParams['environment'], 70);
      expect(farmer.lifeParams['lifeCost'], 40);
      expect(farmer.concerns, contains(Concern.agriculture));
      expect(farmer.concerns, contains(Concern.environment));

      final doctor = Citizen.initial(Job.doctor);
      expect(doctor.lifeParams['healthcare'], 75);
      expect(doctor.lifeParams['lifeCost'], 55);
      expect(doctor.concerns, contains(Concern.healthcare));
      expect(doctor.concerns, contains(Concern.healthcare));

      final merchant = Citizen.initial(Job.merchant);
      expect(merchant.lifeParams['employment'], 60);
      expect(merchant.concerns, contains(Concern.economy));

      final teacher = Citizen.initial(Job.teacher);
      expect(teacher.lifeParams['education'], 70);
      expect(teacher.concerns, contains(Concern.education));

      final unemployed = Citizen.initial(Job.unemployed);
      expect(unemployed.lifeParams['lifeCost'], 30);
      expect(unemployed.lifeParams['employment'], 20);
    });

    test('copyWithで一部パラメータを変更できる', () {
      final citizen = Citizen.initial(Job.farmer);
      final updated = citizen.copyWith(name: '新しい名前');
      expect(updated.name, '新しい名前');
      expect(updated.job, Job.farmer);
      expect(updated.lifeParams['environment'], 70);
    });

    test('toJson/fromJsonでシリアライズ/デシリアライズできる', () {
      final citizen = Citizen.initial(Job.doctor).copyWith(name: '医者です');
      final json = citizen.toJson();
      final restored = Citizen.fromJson(json);

      expect(restored.name, '医者です');
      expect(restored.job, Job.doctor);
      expect(restored.lifeParams['healthcare'], 75);
      expect(restored.lifeParams['lifeCost'], 55);
    });

    test('equatableで等価性が正しく判定される', () {
      final a = Citizen.initial(Job.farmer).copyWith(name: '田中');
      final b = Citizen.initial(Job.farmer).copyWith(name: '田中');
      final c = Citizen.initial(Job.doctor).copyWith(name: '田中');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('applyPolicyEffectsでライフパラメータが変化する', () {
      final citizen = Citizen.initial(Job.farmer).copyWith(name: 'テスト');
      final effects = <String, int>{
        'environment': 10,
        'lifeCost': -10,
        'healthcare': 5,
      };

      final updated = citizen.applyPolicyEffects(effects);
      expect(updated.lifeParams['environment'], 80); // 70 + 10
      expect(updated.lifeParams['lifeCost'], 30);    // 40 - 10
      expect(updated.lifeParams['healthcare'], 55);  // 50 + 5
    });

    test('applyPolicyEffectsで値は0〜100の範囲にクランプされる', () {
      final citizen = Citizen.initial(Job.farmer).copyWith(name: 'テスト');
      
      final effects = <String, int>{'environment': 100};
      final updated = citizen.applyPolicyEffects(effects);
      expect(updated.lifeParams['environment'], 100);

      final effects2 = <String, int>{'environment': -100};
      final updated2 = citizen.applyPolicyEffects(effects2);
      expect(updated2.lifeParams['environment'], 0);
    });
  });
}
