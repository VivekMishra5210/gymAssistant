import 'package:flutter_test/flutter_test.dart';
import 'package:gym_assistant/core/notifications/rest_notifier.dart';
import 'package:gym_assistant/core/time/clock.dart';
import 'package:gym_assistant/data/models/plan_exercise.dart';
import 'package:gym_assistant/logic/rest_timer_controller.dart';
import 'package:gym_assistant/logic/workout_controller.dart';

const plan = [
  PlanExercise('Lat Pulldown', 2, 120),
  PlanExercise('Barbell Curl', 2, 90),
];

/// Records what the controller asks to persist.
class RecordingStore implements WorkoutStore {
  final saved = <String>[];
  final deleted = <String>[];
  final finished = <(SessionEnd, String?)>[];

  @override
  Future<void> saveSet(
    int ex,
    int set,
    double kg,
    int reps,
    DateTime at,
  ) async => saved.add('$ex/$set $kg×$reps');
  @override
  Future<void> deleteSet(int ex, int set) async => deleted.add('$ex/$set');
  @override
  Future<void> saveRest(DateTime? endsAt, String? label) async {}
  @override
  Future<void> finish(SessionEnd end, DateTime at, String? reason) async =>
      finished.add((end, reason));
}

/// Records schedule/cancel calls as "HH:MM:SS body" or "cancel".
class RecordingAlerts implements RestAlerts {
  final calls = <String>[];

  @override
  Future<void> schedule(DateTime at, String body) async =>
      calls.add('${at.toIso8601String().substring(11, 19)} $body');
  @override
  Future<void> cancel() async => calls.add('cancel');
}

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

    test('restored end time after an app kill keeps counting from it', () {
      rest.restore(clock.now().add(const Duration(seconds: 45)), 'Set 2 · X');
      expect(rest.remaining, const Duration(seconds: 45));
      rest.restore(clock.now().subtract(const Duration(seconds: 1)), 'x');
      expect(rest.takeFinished(), isTrue);
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
    late RecordingStore store;
    late WorkoutController w;

    Future<void> fill(int ex, int set) async {
      await w.setWeight(ex, set, 60);
      await w.setReps(ex, set, 10);
    }

    setUp(() {
      clock = FakeClock(DateTime(2026, 1, 1, 10));
      store = RecordingStore();
      w = WorkoutController(clock, plan, name: 'Test', store: store);
    });

    test('✓ is disabled until weight and reps are filled', () async {
      expect(w.canTick(0, 0), isFalse);
      await w.setWeight(0, 0, 0); // bodyweight is allowed
      expect(w.canTick(0, 0), isFalse);
      await w.setReps(0, 0, 8);
      expect(w.canTick(0, 0), isTrue);
    });

    test('only the active set can be ticked', () async {
      await fill(0, 1);
      expect(w.canTick(0, 1), isFalse);
    });

    test(
      'ticking saves the set and starts rest; early tick restarts it',
      () async {
        await fill(0, 0);
        await w.tick(0, 0);
        expect(store.saved, ['0/0 60.0×10']);
        expect(w.rest.remaining, const Duration(seconds: 120));
        expect(w.rest.nextLabel, 'Set 2 · Lat Pulldown');

        clock.advance(const Duration(seconds: 30));
        await w.tick(0, 1); // pre-filled from set 1
        expect(w.rest.remaining, const Duration(seconds: 90));
        expect(w.rest.nextLabel, 'Barbell Curl');
        expect(w.restOverText, 'Next exercise: Barbell Curl (2 sets)');
      },
    );

    test(
      'empty later sets copy the ticked set; filled ones are kept',
      () async {
        w.load(0, 1, weight: 55, reps: 8); // pre-filled from history
        await fill(0, 0);
        await w.tick(0, 0);
        expect(w.entry(0, 1).weight, 55);
        expect(w.entry(1, 0).weight, isNull); // other exercise untouched
      },
    );

    test('undo deletes the set and does not restart the timer', () async {
      await fill(0, 0);
      await w.tick(0, 0);
      clock.advance(const Duration(seconds: 40));
      await w.undo(0, 0);
      expect(store.deleted, ['0/0']);
      expect(w.rest.remaining, const Duration(seconds: 80));
      expect(w.active, (ex: 0, set: 0));
    });

    test('editing a logged set saves it; 0 reps is refused', () async {
      await fill(0, 0);
      await w.tick(0, 0);
      await w.setWeight(0, 0, 62.5);
      await w.setReps(0, 0, 0);
      expect(w.entry(0, 0).reps, 10);
      expect(store.saved.last, '0/0 62.5×10');
    });

    test(
      'last set of the last exercise completes the session with no rest',
      () async {
        for (var e = 0; e < 2; e++) {
          for (var s = 0; s < 2; s++) {
            await fill(e, s);
            await w.tick(e, s);
          }
        }
        expect(w.completed, isTrue);
        expect(w.rest.isResting, isFalse);
        expect(store.finished, [(SessionEnd.completed, null)]);
        expect(w.volume, 4 * 60 * 10);
      },
    );

    test('End Workout saves ended early with the reason', () async {
      await fill(0, 0);
      await w.tick(0, 0);
      await w.end('Short on time');
      expect(store.finished, [(SessionEnd.endedEarly, 'Short on time')]);
      expect(w.rest.isResting, isFalse);
    });

    test('weight and reps never go below 0', () async {
      await w.bumpWeight(0, 0, -2.5);
      await w.bumpReps(0, 0, -1);
      expect(w.entry(0, 0).weight, 0);
      expect(w.entry(0, 0).reps, 0);
    });
  });

  test(
    'rest notification: scheduled at the end time, moved, cancelled',
    () async {
      final clock = FakeClock(DateTime(2026, 1, 1, 10));
      final alerts = RecordingAlerts();
      final w = WorkoutController(clock, plan, name: 'Pull', alerts: alerts);
      w.load(0, 0, weight: 50, reps: 10);

      await w.tick(0, 0);
      expect(alerts.calls.last, '10:02:00 Next: Set 2 · Lat Pulldown');

      w.rest.adjust(const Duration(seconds: 15));
      expect(alerts.calls.last, '10:02:15 Next: Set 2 · Lat Pulldown');

      w.rest.skip();
      expect(alerts.calls.last, 'cancel');

      // Rest ran out while away: no past-time schedule, popup clears it once.
      await w.tick(0, 1);
      clock.advance(const Duration(minutes: 5));
      w.rest.restore(w.rest.endsAt!, w.rest.nextLabel);
      expect(alerts.calls.last, 'cancel');
      expect(w.rest.takeFinished(), isTrue);
      expect(alerts.calls.last, 'cancel');
    },
  );

  test('cardio set needs only minutes and logs weight 0', () async {
    final store = RecordingStore();
    final w = WorkoutController(
      FakeClock(DateTime(2026, 1, 1, 10)),
      const [PlanExercise('Treadmill', 2, 60, timed: true)],
      name: 'Cardio',
      store: store,
    );
    expect(w.canTick(0, 0), isFalse);
    await w.bumpReps(0, 0, 5);
    expect(w.canTick(0, 0), isTrue);
    await w.tick(0, 0);
    expect(store.saved, ['0/0 0.0×5']);
    w.dispose();
  });
}
