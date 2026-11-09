import 'package:flutter_test/flutter_test.dart';
import 'package:gym_assistant/data/models/split_entry.dart';
import 'package:gym_assistant/logic/cycle_service.dart';
import 'package:gym_assistant/ui/onboarding/onboarding_view.dart';

SplitEntry w(int pos, String name) =>
    SplitEntry(id: pos, position: pos, type: EntryType.workout, name: name);
SplitEntry r(int pos) =>
    SplitEntry(id: pos, position: pos, type: EntryType.rest, name: 'Rest');

// A · B · Rest · Rest · Rest
final split = [w(1, 'A'), w(2, 'B'), r(3), r(4), r(5)];

void main() {
  test('advance wraps around', () {
    expect(advance(2, 5), 3);
    expect(advance(5, 5), 1);
  });

  test('3 rest entries consume 3 days', () {
    final c = catchUp(split, (position: 3, since: '2026-01-01'), '2026-01-04');
    expect(c.restDates, ['2026-01-01', '2026-01-02', '2026-01-03']);
    expect(c.pointer, (position: 1, since: '2026-01-04'));
  });

  test(
    'mid rest run: only passed days are consumed, today stays a rest day',
    () {
      final c = catchUp(split, (
        position: 3,
        since: '2026-01-01',
      ), '2026-01-02');
      expect(c.restDates, ['2026-01-01']);
      expect(c.pointer, (position: 4, since: '2026-01-02'));
    },
  );

  test('back after 10 days lands on a workout entry, not skipped past', () {
    final fromWorkout = catchUp(split, (
      position: 2,
      since: '2026-01-01',
    ), '2026-01-11');
    expect(fromWorkout.pointer, (position: 2, since: '2026-01-11'));
    expect(fromWorkout.restDates, isEmpty);

    final fromRest = catchUp(split, (
      position: 5,
      since: '2026-01-01',
    ), '2026-01-11');
    expect(fromRest.restDates, ['2026-01-01']);
    expect(fromRest.pointer, (position: 1, since: '2026-01-11'));
  });

  test('finish on D with next = Rest → the rest applies to D+1', () {
    final p = afterFinish(5, (position: 2, since: '2026-01-01'), '2026-01-01');
    expect(p, (position: 3, since: '2026-01-02'));

    // Still day D: nothing consumed.
    expect(catchUp(split, p, '2026-01-01').pointer, p);
    // D+1 is the rest day.
    final d1 = catchUp(split, p, '2026-01-02');
    expect(d1.restDates, isEmpty);
    expect(split[d1.pointer.position - 1].isRest, isTrue);
    // D+2: the rest day D+1 is logged.
    expect(catchUp(split, p, '2026-01-03').restDates, ['2026-01-02']);
  });

  test('Train anyway skips consecutive rests to the next workout', () {
    final p = trainAnyway(split, (
      position: 3,
      since: '2026-01-02',
    ), '2026-01-02');
    expect(p, (position: 1, since: '2026-01-02'));
    // No rest days get logged afterwards for the skipped entries.
    expect(catchUp(split, p, '2026-01-02').restDates, isEmpty);
  });

  test('Train anyway on a workout entry keeps it', () {
    expect(
      trainAnyway(split, (position: 2, since: '2026-01-05'), '2026-01-02'),
      (position: 2, since: '2026-01-02'),
    );
  });

  test('pointer is clamped after entries are deleted', () {
    expect(clampPosition(7, 5), 5);
    expect(clampPosition(0, 5), 1);
    expect(
      catchUp(
        [w(1, 'A'), w(2, 'B')],
        (position: 4, since: '2026-01-01'),
        '2026-01-01',
      ).pointer.position,
      2,
    );
  });

  test('Today card state priority', () {
    expect(
      todayState(inProgress: true, doneToday: true, restEntry: true),
      TodayState.inProgress,
    );
    expect(
      todayState(inProgress: false, doneToday: true, restEntry: true),
      TodayState.doneToday,
    );
    expect(
      todayState(inProgress: false, doneToday: false, restEntry: true),
      TodayState.restDay,
    );
    expect(
      todayState(inProgress: false, doneToday: false, restEntry: false),
      TodayState.workoutDue,
    );
  });

  test('split edit: pointer follows its entry, else clamps', () {
    // Reorder [1,2,3,4] → [3,1,2,4]: pointer on id 2 (pos 2) moves to pos 3.
    expect(keepPointer([1, 2, 3, 4], 2, [3, 1, 2, 4]), 3);
    // Delete an earlier entry: still on the same entry.
    expect(keepPointer([1, 2, 3, 4], 3, [2, 3, 4]), 2);
    // Delete the pointed entry at the end: clamp to the new last.
    expect(keepPointer([1, 2, 3, 4], 4, [1, 2, 3]), 3);
    // Adding the first entry to an empty split.
    expect(keepPointer([], 1, [7]), 1);
  });

  test('onboarding templates: placeholder names in cycle order', () {
    expect(templateEntries('WWRWWRR').map((e) => e.$2), [
      'Workout 1',
      'Workout 2',
      'Rest',
      'Workout 3',
      'Workout 4',
      'Rest',
      'Rest',
    ]);
    expect(templateEntries(''), isEmpty);
  });
}
