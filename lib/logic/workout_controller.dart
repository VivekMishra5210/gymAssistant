import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../core/notifications/rest_notifier.dart';
import '../core/time/clock.dart';
import '../data/models/plan_exercise.dart';
import 'rest_timer_controller.dart';

enum SessionEnd { completed, endedEarly }

/// Where the controller persists what happens. Indexes are 0-based.
abstract class WorkoutStore {
  Future<void> saveSet(int ex, int set, double kg, int reps, DateTime at);
  Future<void> deleteSet(int ex, int set);
  Future<void> saveRest(DateTime? endsAt, String? label);
  Future<void> finish(SessionEnd end, DateTime at, String? reason);
}

/// In-memory default (tests).
class NoStore implements WorkoutStore {
  const NoStore();

  @override
  Future<void> saveSet(
    int ex,
    int set,
    double kg,
    int reps,
    DateTime at,
  ) async {}
  @override
  Future<void> deleteSet(int ex, int set) async {}
  @override
  Future<void> saveRest(DateTime? endsAt, String? label) async {}
  @override
  Future<void> finish(SessionEnd end, DateTime at, String? reason) async {}
}

class SetEntry {
  double? weight;
  int? reps;
  bool done = false;

  bool get filled => weight != null && reps != null && reps! > 0;
}

class ExerciseProgress {
  ExerciseProgress(this.plan)
    : sets = List.generate(
        plan.sets,
        (_) => SetEntry()..weight = plan.timed ? 0 : null, // cardio: no kg
      );

  final PlanExercise plan;
  final List<SetEntry> sets;

  int get doneCount => sets.where((s) => s.done).length;
}

typedef SetPos = ({int ex, int set});

/// Active session state (SPEC §5.3). Persists through [store].
class WorkoutController extends ChangeNotifier {
  WorkoutController(
    this._clock,
    this.plan, {
    required this.name,
    DateTime? startedAt,
    this.store = const NoStore(),
    this.alerts = const NoAlerts(),
    this.vibrate = true,
    this.sound = false,
    this.keepScreenOn = false,
  }) : exercises = [for (final p in plan) ExerciseProgress(p)],
       startedAt = startedAt ?? _clock.now(),
       rest = RestTimerController(_clock) {
    rest.addListener(_onRest);
  }

  final Clock _clock;
  final String name;
  final List<PlanExercise> plan;
  final List<ExerciseProgress> exercises;
  final DateTime startedAt;
  final RestTimerController rest;
  final WorkoutStore store;
  final RestAlerts alerts;
  // Settings, read at session open.
  final bool vibrate;
  final bool sound;
  final bool keepScreenOn;
  bool completed = false;
  bool _busy = false;

  void _onRest() {
    store
        .saveRest(rest.endsAt, rest.nextLabel)
        .catchError((Object e) => debugPrint('saving rest failed: $e'));
    // Any rest change (start, ±15, skip, end, popup shown) re-arms or clears
    // the notification. A past end time is never scheduled.
    final end = rest.endsAt;
    (end != null && end.isAfter(_clock.now())
            ? alerts.schedule(end, 'Next: ${rest.nextLabel}')
            : alerts.cancel())
        .catchError((Object e) => debugPrint('rest notification failed: $e'));
    notifyListeners();
  }

  @override
  void dispose() {
    rest.removeListener(_onRest);
    rest.dispose();
    super.dispose();
  }

  Duration get elapsed => _clock.now().difference(startedAt);

  /// First set not done yet, in plan order. Null when everything is done.
  SetPos? get active {
    for (var e = 0; e < exercises.length; e++) {
      final sets = exercises[e].sets;
      for (var s = 0; s < sets.length; s++) {
        if (!sets[s].done) return (ex: e, set: s);
      }
    }
    return null;
  }

  int get setsDone => exercises.fold(0, (n, e) => n + e.doneCount);
  int get setsTotal => exercises.fold(0, (n, e) => n + e.sets.length);
  int get setsLeft => setsTotal - setsDone;

  double get volume => exercises
      .expand((e) => e.sets)
      .where((s) => s.done)
      .fold(0.0, (v, s) => v + s.weight! * s.reps!);

  SetEntry entry(int ex, int set) => exercises[ex].sets[set];

  /// Restore a logged set or a pre-fill value, without saving.
  void load(int ex, int set, {double? weight, int? reps, bool done = false}) {
    final s = entry(ex, set);
    s
      ..weight = weight
      ..reps = reps
      ..done = done;
  }

  Future<void> setWeight(int ex, int set, double? kg) async {
    final s = entry(ex, set);
    if (kg == null && s.done) return; // a done set keeps its values
    s.weight = kg == null ? null : math.max(0, kg);
    notifyListeners();
    if (s.done) await store.saveSet(ex, set, s.weight!, s.reps!, _clock.now());
  }

  Future<void> setReps(int ex, int set, int? reps) async {
    final s = entry(ex, set);
    if (s.done && (reps == null || reps < 1)) return; // logged sets need ≥1 rep
    s.reps = reps == null ? null : math.max(0, reps);
    notifyListeners();
    if (s.done) await store.saveSet(ex, set, s.weight!, s.reps!, _clock.now());
  }

  Future<void> bumpWeight(int ex, int set, double delta) =>
      setWeight(ex, set, (entry(ex, set).weight ?? 0) + delta);

  Future<void> bumpReps(int ex, int set, int delta) =>
      setReps(ex, set, (entry(ex, set).reps ?? 0) + delta);

  bool canTick(int ex, int set) {
    final a = active;
    return a != null && a.ex == ex && a.set == set && entry(ex, set).filled;
  }

  /// ✓ on the active set: saves it and starts (or restarts) the rest timer.
  Future<void> tick(int ex, int set) async {
    if (_busy || !canTick(ex, set)) return;
    _busy = true;
    try {
      final s = entry(ex, set);
      final at = _clock.now();
      await store.saveSet(ex, set, s.weight!, s.reps!, at);
      s.done = true;
      // Pre-fill fallback (SPEC §9): empty later sets of this exercise copy this one.
      for (final later in exercises[ex].sets.skip(set + 1)) {
        if (!later.done && later.weight == null && later.reps == null) {
          later
            ..weight = s.weight
            ..reps = s.reps;
        }
      }
      final next = active;
      if (next == null) {
        await complete();
      } else {
        final d = restAfter(plan, ex, set);
        if (d == null) {
          rest.skip();
        } else {
          rest.start(d, _label(next));
        }
      }
      notifyListeners();
    } finally {
      _busy = false;
    }
  }

  /// Long-press → undo. Does not touch the rest timer.
  Future<void> undo(int ex, int set) async {
    await store.deleteSet(ex, set);
    entry(ex, set).done = false;
    notifyListeners();
  }

  /// All sets done → completed. Also used if the app died right after the last ✓.
  Future<void> complete() async {
    rest.skip();
    await store.finish(SessionEnd.completed, _clock.now(), null);
    completed = true;
    notifyListeners();
  }

  /// End Workout with sets left (SPEC §5.5).
  Future<void> end(String reason) async {
    rest.skip();
    await store.finish(SessionEnd.endedEarly, _clock.now(), reason);
  }

  /// Rest panel: "Set 3 · Lat Pulldown" or "Barbell Curl".
  String _label(SetPos p) {
    final n = exercises[p.ex].plan.name;
    return p.set == 0 ? n : 'Set ${p.set + 1} · $n';
  }

  /// Rest-over popup line (SPEC §5.4), from the current active set.
  String get restOverText {
    final p = active;
    if (p == null) return '';
    final e = exercises[p.ex].plan;
    return p.set == 0
        ? 'Next exercise: ${e.name} (${e.sets} sets)'
        : 'Set ${p.set + 1} of ${e.name}';
  }
}
