import 'package:flutter_test/flutter_test.dart';
import 'package:gym_assistant/core/time/clock.dart';
import 'package:gym_assistant/data/models/plan_exercise.dart';
import 'package:gym_assistant/logic/rest_timer_controller.dart';
import 'package:gym_assistant/logic/workout_controller.dart';

const plan = [
  PlanExercise('Lat Pulldown', 2, 120),
  PlanExercise('Barbell Curl', 2, 90),
];

void main() {
  group('restAfter (SPEC §4/§7)', () {
    test('between sets uses the current exercise rest', () {
      expect(restAfter(plan, 0, 0), const Duration(seconds: 120));
      expect(restAfter(plan, 1, 0), const Duration(seconds: 90));
    });

    test('after the last set uses the next exercise rest', () {
      expect(restAfter(plan, 0, 1), const Duration(seconds: 90));
    });

    test('last set of the last exercise has no rest', () {
      expect(restAfter(plan, 1, 1), isNull);
    });
  });

  group('RestTimerController', () {
    late FakeClock clock;
    late RestTimerController rest;

    setUp(() {
      clock = FakeClock(DateTime(2026, 1, 1, 10));
      rest = RestTimerController(clock);
    });

    test('remaining comes from the end time, not a countdown', () {
      rest.start(const Duration(seconds: 120), 'Set 2 · Lat Pulldown');
      clock.advance(const Duration(seconds: 50));
      expect(rest.remaining, const Duration(seconds: 70));
      clock.advance(const Duration(minutes: 10));
      expect(rest.remaining, Duration.zero);
    });

    test('+15s extends, −15s shortens and never goes before now', () {
      rest.start(const Duration(seconds: 20), 'x');
      rest.adjust(const Duration(seconds: 15));
      expect(rest.remaining, const Duration(seconds: 35));
      rest.adjust(const Duration(seconds: -15));
      rest.adjust(const Duration(seconds: -15));
      expect(rest.remaining, const Duration(seconds: 5));
      rest.adjust(const Duration(seconds: -15));
      expect(rest.remaining, Duration.zero);
      expect(rest.endsAt, clock.now());
    });

    test('resume after the end time → finished once, then cleared', () {
      rest.start(const Duration(seconds: 60), 'x');
      clock.advance(const Duration(seconds: 30));
      expect(rest.takeFinished(), isFalse);
      clock.advance(const Duration(minutes: 5)); // phone was locked
      expect(rest.takeFinished(), isTrue);
      expect(rest.takeFinished(), isFalse);
      expect(rest.isResting, isFalse);
    });

    test('skip clears the rest', () {
      rest.start(const Duration(seconds: 60), 'x');
      rest.skip();
      expect(rest.isResting, isFalse);
      expect(rest.takeFinished(), isFalse);
    });
  });

  group('WorkoutController', () {
    late FakeClock clock;
    late WorkoutController w;

    void fill(int ex, int set) {
      w.setWeight(ex, set, 60);
      w.setReps(ex, set, 10);
    }

    setUp(() {
      clock = FakeClock(DateTime(2026, 1, 1, 10));
      w = WorkoutController(clock, plan, name: 'Test');
    });

    test('✓ is disabled until weight and reps are filled', () {
      expect(w.canTick(0, 0), isFalse);
      w.setWeight(0, 0, 0); // bodyweight is allowed
      expect(w.canTick(0, 0), isFalse);
      w.setReps(0, 0, 8);
      expect(w.canTick(0, 0), isTrue);
    });

    test('only the active set can be ticked', () {
      fill(0, 1);
      expect(w.canTick(0, 1), isFalse);
    });

    test('ticking starts rest with the next label; early tick restarts it', () {
      fill(0, 0);
      w.tick(0, 0);
      expect(w.rest.remaining, const Duration(seconds: 120));
      expect(w.rest.nextLabel, 'Set 2 · Lat Pulldown');

      clock.advance(const Duration(seconds: 30));
      fill(0, 1);
      w.tick(0, 1);
      expect(w.rest.remaining, const Duration(seconds: 90));
      expect(w.rest.nextLabel, 'Barbell Curl');
      expect(w.restOverText, 'Next exercise: Barbell Curl (2 sets)');
    });

    test('undo does not restart the timer', () {
      fill(0, 0);
      w.tick(0, 0);
      clock.advance(const Duration(seconds: 40));
      w.undo(0, 0);
      expect(w.rest.remaining, const Duration(seconds: 80));
      expect(w.active, (ex: 0, set: 0));
    });

    test('last set of the last exercise completes the session with no rest', () {
      for (var e = 0; e < 2; e++) {
        for (var s = 0; s < 2; s++) {
          fill(e, s);
          w.tick(e, s);
        }
      }
      expect(w.completed, isTrue);
      expect(w.rest.isResting, isFalse);
      expect(w.volume, 4 * 60 * 10);
    });

    test('weight and reps never go below 0', () {
      w.bumpWeight(0, 0, -2.5);
      w.bumpReps(0, 0, -1);
      expect(w.entry(0, 0).weight, 0);
      expect(w.entry(0, 0).reps, 0);
    });
  });
}
