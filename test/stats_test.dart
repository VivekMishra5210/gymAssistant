import 'package:flutter_test/flutter_test.dart';
import 'package:gym_assistant/logic/stats.dart';

SessionStat s(String date, int minutes, {double volume = 0, int sets = 0}) => (
  date: date,
  duration: Duration(minutes: minutes),
  volume: volume,
  sets: sets,
);

void main() {
  final all = [
    s('2026-11-02', 60, volume: 1000, sets: 10), // Mon, previous week
    s('2026-11-09', 50, volume: 800, sets: 8), // Mon
    s('2026-11-10', 70, volume: 1200, sets: 12), // Tue
  ];

  test('week: Monday to today, averages per workout and per day', () {
    expect(weekStart('2026-11-10'), '2026-11-09');
    expect(weekStart('2026-11-09'), '2026-11-09'); // Monday itself
    expect(weekStart('2026-11-15'), '2026-11-09'); // Sunday
    final w = periodStats(all, '2026-11-09', '2026-11-10');
    expect(w.workouts, 2);
    expect(w.total, const Duration(minutes: 120));
    expect(w.avgPerWorkout, const Duration(minutes: 60));
    expect(w.days, 2);
    expect(w.avgPerDay, const Duration(minutes: 60));
    expect((w.sets, w.volume), (20, 2000.0));
  });

  test('month: rest days count in the per-day average', () {
    expect(monthStart('2026-11-10'), '2026-11-01');
    final m = periodStats(all, '2026-11-01', '2026-11-10');
    expect(m.workouts, 3);
    expect(m.days, 10);
    expect(m.avgPerDay, const Duration(minutes: 18)); // 180 min / 10 days
  });

  test('empty period has zero averages, no division by zero', () {
    final e = periodStats(const [], '2026-11-01', '2026-11-10');
    expect((e.avgPerWorkout, e.avgPerDay), (Duration.zero, Duration.zero));
  });

  test('days across a month and year boundary', () {
    expect(daysBetween('2026-12-30', '2027-01-02'), 3);
  });

  test('BMI value and WHO category', () {
    expect(bmi(70, 175), closeTo(22.86, 0.01));
    expect(bmiCategory(18.4), 'Underweight');
    expect(bmiCategory(18.5), 'Normal');
    expect(bmiCategory(25), 'Overweight');
    expect(bmiCategory(30), 'Obese');
  });

  group('exercise progress', () {
    final history = <ExerciseSession>[
      (
        date: '2026-01-01',
        sets: [(weight: 60, reps: 10), (weight: 70, reps: 6)],
      ),
      (
        date: '2026-01-05',
        sets: [(weight: 70, reps: 8), (weight: 65, reps: 10)],
      ),
    ];

    test('best set: heaviest, more reps breaks a tie', () {
      final b = bestSet(history)!;
      expect((b.set.weight, b.set.reps, b.date), (70.0, 8, '2026-01-05'));
      expect(bestSet([]), isNull);
    });

    test('Epley 1RM; one rep is the weight itself', () {
      expect(oneRepMax(100, 1), 100);
      expect(oneRepMax(100, 30), 200);
      expect(bestOneRepMax(history), closeTo(70 * (1 + 8 / 30), 1e-9));
    });

    test('chart value: heaviest kg, or total minutes for cardio', () {
      expect(sessionValue(history[0], timed: false), 70);
      final run = (
        date: '2026-01-02',
        sets: [(weight: 0.0, reps: 20), (weight: 0.0, reps: 15)],
      );
      expect(sessionValue(run, timed: true), 35);
    });
  });
}
