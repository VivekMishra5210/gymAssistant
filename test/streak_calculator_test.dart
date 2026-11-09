import 'package:flutter_test/flutter_test.dart';
import 'package:gym_assistant/logic/streak_calculator.dart';

String day(int d) => '2026-01-${d.toString().padLeft(2, '0')}';

Streak run({
  List<int> workouts = const [],
  List<int> rests = const [],
  required int today,
  int grace = 1,
}) => computeStreak(
  workoutDays: {for (final d in workouts) day(d)},
  restDays: {for (final d in rests) day(d)},
  grace: grace,
  today: day(today),
);

void main() {
  test('consecutive days', () {
    expect(run(workouts: [1, 2, 3], today: 3).current, 3);
  });

  test('1 missed day survives (grace 1)', () {
    expect(run(workouts: [1, 3], today: 3).current, 2);
  });

  test('2 missed days in a row break it', () {
    expect(run(workouts: [1, 4], today: 4).current, 1);
  });

  test('planned rest days are neutral', () {
    final s = run(workouts: [1, 4], rests: [2, 3], today: 4);
    expect(s.current, 2); // rest days don't add
    expect(run(workouts: [1, 4], rests: [2, 3], today: 4, grace: 0).current, 2);
  });

  test('today with no workout yet does not break the streak', () {
    expect(run(workouts: [1, 2], today: 3).current, 2);
    expect(run(workouts: [1, 2], today: 3, grace: 0).current, 2);
  });

  test('best streak over history', () {
    final s = run(workouts: [1, 2, 3, 4, 5, 8, 9], today: 9);
    expect(s.current, 2);
    expect(s.best, 5);
  });

  test('grace 0: one miss breaks', () {
    expect(run(workouts: [1, 3], today: 3, grace: 0).current, 1);
  });

  test('grace 2: two misses survive, three break', () {
    expect(run(workouts: [1, 4], today: 4, grace: 2).current, 2);
    expect(run(workouts: [1, 5], today: 5, grace: 2).current, 1);
  });

  test('no workouts yet', () {
    final s = run(today: 5);
    expect((s.current, s.best), (0, 0));
  });
}
