import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/domain/models/citizen.dart';

void main() {
  group('Citizen', () {
    group('Citizen.initial()', () {
      test('creates a default farmer with correct params', () {
        final citizen = Citizen.initial(Job.farmer);

        expect(citizen.name, '');
        expect(citizen.job, Job.farmer);
        expect(citizen.concerns, ['農業政策', '気候変動']);
        expect(citizen.lifeParams['environment'], 70);
        expect(citizen.lifeParams['lifeCost'], 40);
        expect(citizen.lifeParams['healthcare'], 50);
        expect(citizen.lifeParams['education'], 50);
        expect(citizen.lifeParams['employment'], 50);
        expect(citizen.lifeParams['safety'], 50);
      });

      test('creates a default merchant with correct params', () {
        final citizen = Citizen.initial(Job.merchant);

        expect(citizen.name, '');
        expect(citizen.job, Job.merchant);
        expect(citizen.concerns, ['経済政策', '税制']);
        expect(citizen.lifeParams['employment'], 60);
        expect(citizen.lifeParams['lifeCost'], 50);
      });

      test('creates a default teacher with correct params', () {
        final citizen = Citizen.initial(Job.teacher);

        expect(citizen.name, '');
        expect(citizen.job, Job.teacher);
        expect(citizen.concerns, ['教育政策', '社会保障']);
        expect(citizen.lifeParams['education'], 70);
        expect(citizen.lifeParams['healthcare'], 50);
      });

      test('creates a default student with correct params', () {
        final citizen = Citizen.initial(Job.student);

        expect(citizen.name, '');
        expect(citizen.job, Job.student);
        expect(citizen.concerns, ['教育政策', '雇用政策']);
        expect(citizen.lifeParams['education'], 50);
        expect(citizen.lifeParams['employment'], 40);
      });

      test('creates a default doctor with correct params', () {
        final citizen = Citizen.initial(Job.doctor);

        expect(citizen.name, '');
        expect(citizen.job, Job.doctor);
        expect(citizen.concerns, ['医療政策', '社会保障']);
        expect(citizen.lifeParams['healthcare'], 75);
        expect(citizen.lifeParams['lifeCost'], 55);
      });

      test('creates a default unemployed citizen with correct params', () {
        final citizen = Citizen.initial(Job.unemployed);

        expect(citizen.name, '');
        expect(citizen.job, Job.unemployed);
        expect(citizen.concerns, ['雇用政策', '社会保障']);
        expect(citizen.lifeParams['lifeCost'], 30);
        expect(citizen.lifeParams['employment'], 20);
      });

      test('creates a default fisher with correct params', () {
        final citizen = Citizen.initial(Job.fisher);

        expect(citizen.name, '');
        expect(citizen.job, Job.fisher);
        expect(citizen.concerns, ['生活', '雇用']);
        expect(citizen.lifeParams['lifeCost'], 40);
        expect(citizen.lifeParams['environment'], 55);
      });

      test('creates a default carpenter with correct params', () {
        final citizen = Citizen.initial(Job.carpenter);

        expect(citizen.name, '');
        expect(citizen.job, Job.carpenter);
        expect(citizen.concerns, ['生活', '経済']);
        expect(citizen.lifeParams['lifeCost'], 45);
        expect(citizen.lifeParams['employment'], 50);
      });

      test('creates a default artisan with correct params', () {
        final citizen = Citizen.initial(Job.artisan);

        expect(citizen.name, '');
        expect(citizen.job, Job.artisan);
        expect(citizen.concerns, ['経済', '雇用']);
        expect(citizen.lifeParams['employment'], 55);
        expect(citizen.lifeParams['environment'], 50);
      });

      test('creates a default official with correct params', () {
        final citizen = Citizen.initial(Job.official);

        expect(citizen.name, '');
        expect(citizen.job, Job.official);
        expect(citizen.concerns, ['治安', '教育']);
        expect(citizen.lifeParams['safety'], 60);
        expect(citizen.lifeParams['education'], 55);
      });
    });

    group('Equatable', () {
      test('two identical citizens are equal', () {
        final c1 = Citizen.initial(Job.farmer);
        final c2 = Citizen.initial(Job.farmer);

        expect(c1, equals(c2));
      });

      test('two citizens with different jobs are not equal', () {
        final c1 = Citizen.initial(Job.farmer);
        final c2 = Citizen.initial(Job.teacher);

        expect(c1, isNot(equals(c2)));
      });

      test('two citizens with same values are equal', () {
        final c1 = Citizen(
          name: 'テスト',
          job: Job.doctor,
          concerns: ['医療政策'],
          lifeParams: {'healthcare': 80, 'lifeCost': 50},
        );
        final c2 = Citizen(
          name: 'テスト',
          job: Job.doctor,
          concerns: ['医療政策'],
          lifeParams: {'healthcare': 80, 'lifeCost': 50},
        );

        expect(c1, equals(c2));
      });

      test('citizens with different concerns are not equal', () {
        final c1 = Citizen(
          name: 'テスト',
          job: Job.doctor,
          concerns: ['医療政策'],
          lifeParams: {'healthcare': 80},
        );
        final c2 = Citizen(
          name: 'テスト',
          job: Job.doctor,
          concerns: ['教育政策'],
          lifeParams: {'healthcare': 80},
        );

        expect(c1, isNot(equals(c2)));
      });
    });

    group('toJson / fromJson roundtrip', () {
      test('roundtrips a farmer citizen', () {
        final original = Citizen.initial(Job.farmer);
        final json = original.toJson();
        final restored = Citizen.fromJson(json);

        expect(restored, equals(original));
      });

      test('roundtrips a custom citizen', () {
        final original = Citizen(
          name: '山田太郎',
          job: Job.doctor,
          concerns: ['医療政策', '社会保障', '教育政策'],
          lifeParams: {
            'lifeCost': 60,
            'healthcare': 80,
            'education': 55,
            'employment': 50,
            'environment': 45,
            'safety': 70,
          },
        );
        final json = original.toJson();
        final restored = Citizen.fromJson(json);

        expect(restored, equals(original));
        expect(restored.name, '山田太郎');
        expect(restored.job, Job.doctor);
      });

      test('roundtrips all job types', () {
        for (final job in Job.values) {
          final original = Citizen.initial(job);
          final json = original.toJson();
          final restored = Citizen.fromJson(json);

          expect(restored, equals(original), reason: 'Failed for job: $job');
        }
      });
    });

    group('copyWith', () {
      test('returns a copy with updated name', () {
        final original = Citizen.initial(Job.farmer);
        final updated = original.copyWith(name: '田中');

        expect(updated.name, '田中');
        expect(updated.job, original.job);
        expect(updated.concerns, original.concerns);
        expect(updated.lifeParams, original.lifeParams);
      });

      test('returns a copy with updated job', () {
        final original = Citizen.initial(Job.farmer);
        final updated = original.copyWith(job: Job.doctor);

        expect(updated.job, Job.doctor);
        expect(updated.name, original.name);
      });

      test('returns a copy with updated concerns', () {
        final original = Citizen.initial(Job.farmer);
        final updated = original.copyWith(concerns: ['新しい関心']);

        expect(updated.concerns, ['新しい関心']);
      });

      test('returns a copy with updated lifeParams', () {
        final original = Citizen.initial(Job.farmer);
        final updated = original.copyWith(
          lifeParams: {'lifeCost': 100, 'healthcare': 100},
        );

        expect(updated.lifeParams['lifeCost'], 100);
        expect(updated.lifeParams['healthcare'], 100);
      });

      test('returns same instance if no arguments provided', () {
        final original = Citizen.initial(Job.farmer);
        final updated = original.copyWith();

        expect(updated, equals(original));
      });
    });

    group('props', () {
      test('contains all fields', () {
        final citizen = Citizen.initial(Job.farmer);
        expect(citizen.props.length, 4);
        expect(citizen.props[0], '');
        expect(citizen.props[1], Job.farmer);
        expect(citizen.props[2], ['農業政策', '気候変動']);
        expect(citizen.props[3], isA<Map<String, int>>());
      });
    });
  });
}
