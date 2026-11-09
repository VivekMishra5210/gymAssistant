import '../core/time/clock.dart';
import '../core/time/dates.dart';
import '../data/models/plan_exercise.dart';
import '../data/models/split_entry.dart';
import '../data/repositories/plan_repository.dart';
import '../data/repositories/session_repository.dart';
import '../data/repositories/state_repository.dart';
import 'streak_calculator.dart';
import 'workout_controller.dart';

// ===== Pure cycle rules (SPEC §6). Positions are 1-based. =====

int advance(int position, int count) => position % count + 1;

/// After entries were deleted: keep the pointer in range.
int clampPosition(int position, int count) =>
    position < 1 ? 1 : (position > count ? count : position);

/// On open/resume: consume rest entries whose day has passed (one per day).
/// A workout entry is never skipped; it just waits and applies from today.
({Pointer pointer, List<String> restDates}) catchUp(
  List<SplitEntry> entries,
  Pointer p,
  String today,
) {
  var pos = clampPosition(p.position, entries.length);
  var since = p.since;
  final restDates = <String>[];
  while (entries[pos - 1].isRest && since.compareTo(today) < 0) {
    restDates.add(since);
    pos = advance(pos, entries.length);
    since = addDays(since, 1);
  }
  if (!entries[pos - 1].isRest && since.compareTo(today) < 0) since = today;
  return (pointer: (position: pos, since: since), restDates: restDates);
}

/// Session finished (completed or ended early) on [sessionDate] D → next entry from D+1.
Pointer afterFinish(int count, Pointer p, String sessionDate) => (
  position: advance(clampPosition(p.position, count), count),
  since: addDays(sessionDate, 1),
);

/// "Train anyway": skip consecutive rest entries without logging them.
Pointer trainAnyway(List<SplitEntry> entries, Pointer p, String today) {
  var pos = clampPosition(p.position, entries.length);
  for (var i = 0; i < entries.length && entries[pos - 1].isRest; i++) {
    pos = advance(pos, entries.length);
  }
  return (position: pos, since: today);
}

enum TodayState { inProgress, doneToday, restDay, workoutDue }

TodayState todayState({
  required bool inProgress,
  required bool doneToday,
  required bool restEntry,
}) {
  if (inProgress) return TodayState.inProgress;
  if (doneToday) return TodayState.doneToday;
  if (restEntry) return TodayState.restDay;
  return TodayState.workoutDue;
}

// ===== Orchestration with the repositories =====

class TodayInfo {
  TodayInfo({
    required this.state,
    required this.current,
    required this.nextWorkout,
    required this.exercises,
    required this.sessionId,
    required this.setsDone,
    required this.doneDuration,
  });

  final TodayState state;
  final SplitEntry current; // entry at the pointer
  final SplitEntry nextWorkout; // first workout entry from the pointer on
  final List<PlanExercise> exercises; // of [current]
  final int? sessionId; // in-progress session
  final int setsDone;
  final Duration? doneDuration;
}

class History {
  History({
    required this.days,
    required this.restDays,
    required this.total,
    required this.streak,
  });

  final Map<String, String> days; // date → completed | ended_early
  final Set<String> restDays;
  final int total;
  final Streak streak;
}

class CycleService {
  CycleService(this._clock, this._plan, this._state, this._sessions);

  final Clock _clock;
  final PlanRepository _plan;
  final StateRepository _state;
  final SessionRepository _sessions;

  String get _today => dateKey(_clock.now());

  /// Run on app open/resume: rest catch-up, then what the Today card shows.
  Future<TodayInfo> refresh() async {
    final today = _today;
    final entries = await _plan.entries();
    final before = await _state.pointer();
    final r = catchUp(entries, before, today);
    if (r.pointer != before || r.restDates.isNotEmpty) {
      await _state.applyCatchUp(r.pointer, r.restDates);
    }
    final current = entries[r.pointer.position - 1];
    final inProgress = await _sessions.inProgressId();
    final done = await _sessions.finishedDurationOn(today);
    return TodayInfo(
      state: todayState(
        inProgress: inProgress != null,
        doneToday: done != null,
        restEntry: current.isRest,
      ),
      current: current,
      nextWorkout: entries[trainAnyway(entries, r.pointer, today).position - 1],
      exercises: current.isRest
          ? const []
          : [for (final x in await _plan.exercises(current.id)) x.plan],
      sessionId: inProgress,
      setsDone: inProgress == null ? 0 : await _sessions.setsDone(inProgress),
      doneDuration: done,
    );
  }

  /// Calendar dots + streak row (SPEC §5.2, §8).
  Future<History> history() async {
    final days = await _sessions.finishedDays();
    final rest = await _state.restDays();
    return History(
      days: days,
      restDays: rest,
      total: await _sessions.finishedCount(),
      streak: computeStreak(
        workoutDays: days.keys.toSet(),
        restDays: rest,
        grace: await _state.graceDays(),
        today: _today,
      ),
    );
  }

  Future<List<DaySession>> day(String date) => _sessions.sessionsOn(date);

  /// Start Workout / Train anyway / Start next anyway. Returns the session id
  /// (the running one if a session is already in progress).
  Future<int> start() async {
    final running = await _sessions.inProgressId();
    if (running != null) return running;
    final entries = await _plan.entries();
    var p = await _state.pointer();
    if (entries[clampPosition(p.position, entries.length) - 1].isRest) {
      p = trainAnyway(entries, p, _today);
      await _state.setPointer(p);
    }
    final entry = entries[clampPosition(p.position, entries.length) - 1];
    final exercises = await _plan.exercises(entry.id);
    if (exercises.isEmpty) throw StateError('${entry.name} has no exercises');
    return _sessions.start(
      entry: entry,
      exercises: exercises,
      now: _clock.now(),
    );
  }

  /// Build the controller for a session: logged sets, pre-fill, saved rest.
  Future<WorkoutController> open(int sessionId) async {
    final s = await _sessions.load(sessionId);
    final w = WorkoutController(
      _clock,
      s.exercises,
      name: s.name,
      startedAt: s.startedAt,
      store: _DbStore(this, s),
    );
    for (final l in s.logs) {
      w.load(l.ex, l.set, weight: l.weight, reps: l.reps, done: true);
    }
    for (var e = 0; e < s.exercises.length; e++) {
      final exerciseId = s.exerciseIds[e];
      if (exerciseId == null) continue;
      for (var i = 0; i < s.exercises[e].sets; i++) {
        if (w.entry(e, i).done) continue;
        final last = await _sessions.lastSet(exerciseId, i + 1);
        if (last != null) w.load(e, i, weight: last.weight, reps: last.reps);
      }
    }
    final rest = await _state.rest();
    if (rest.endsAt != null) w.rest.restore(rest.endsAt!, rest.label);
    return w;
  }
}

class _DbStore implements WorkoutStore {
  _DbStore(this._c, this._s);

  final CycleService _c;
  final LoadedSession _s;

  @override
  Future<void> saveSet(int ex, int set, double kg, int reps, DateTime at) =>
      _c._sessions.saveSet(_s.sessionExerciseIds[ex], set + 1, kg, reps, at);

  @override
  Future<void> deleteSet(int ex, int set) =>
      _c._sessions.deleteSet(_s.sessionExerciseIds[ex], set + 1);

  @override
  Future<void> saveRest(DateTime? endsAt, String? label) =>
      _c._state.setRest(endsAt, label);

  @override
  Future<void> finish(SessionEnd end, DateTime at, String? reason) async {
    final count = (await _c._plan.entries()).length;
    final pointer = afterFinish(count, await _c._state.pointer(), _s.date);
    await _c._sessions.finish(
      sessionId: _s.id,
      status: end == SessionEnd.completed ? 'completed' : 'ended_early',
      endedAt: at,
      reason: reason,
      pointer: pointer,
    );
  }
}
