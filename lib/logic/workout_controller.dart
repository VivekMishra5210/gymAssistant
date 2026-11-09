import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../core/time/clock.dart';
import '../data/models/plan_exercise.dart';
import 'rest_timer_controller.dart';

/// shortcut: hardcoded Phase 1 workout, replaced by the current split entry in M2.
const hardcodedWorkoutName = 'Pull Day';
const hardcodedWorkout = [
  PlanExercise('Lat Pulldown', 4, 120),
  PlanExercise('Seated Row', 4, 120),
  PlanExercise('Barbell Curl', 4, 90),
  PlanExercise('Hammer Curl', 4, 90),
];

class SetEntry {
  double? weight;
  int? reps;
  bool done = false;

  bool get filled => weight != null && reps != null && reps! > 0;
}

class ExerciseProgress {
  ExerciseProgress(this.plan)
      : sets = List.generate(plan.sets, (_) => SetEntry());

  final PlanExercise plan;
  final List<SetEntry> sets;

  int get doneCount => sets.where((s) => s.done).length;
}

typedef SetPos = ({int ex, int set});

/// Active session state (SPEC §5.3). In memory only until M2.
class WorkoutController extends ChangeNotifier {
  WorkoutController(this._clock, this.plan, {this.name = hardcodedWorkoutName})
      : exercises = [for (final p in plan) ExerciseProgress(p)],
        startedAt = _clock.now(),
        rest = RestTimerController(_clock) {
    rest.addListener(notifyListeners);
  }

  final Clock _clock;
  final String name;
  final List<PlanExercise> plan;
  final List<ExerciseProgress> exercises;
  final DateTime startedAt;
  final RestTimerController rest;
  bool completed = false;

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

  void setWeight(int ex, int set, double? kg) {
    final s = entry(ex, set);
    if (kg == null && s.done) return; // a done set keeps its values
    s.weight = kg == null ? null : math.max(0, kg);
    notifyListeners();
  }

  void setReps(int ex, int set, int? reps) {
    final s = entry(ex, set);
    if (reps == null && s.done) return;
    s.reps = reps == null ? null : math.max(0, reps);
    notifyListeners();
  }

  void bumpWeight(int ex, int set, double delta) =>
      setWeight(ex, set, (entry(ex, set).weight ?? 0) + delta);

  void bumpReps(int ex, int set, int delta) =>
      setReps(ex, set, (entry(ex, set).reps ?? 0) + delta);

  bool canTick(int ex, int set) {
    final a = active;
    return a != null && a.ex == ex && a.set == set && entry(ex, set).filled;
  }

  /// ✓ on the active set: saves it and starts (or restarts) the rest timer.
  void tick(int ex, int set) {
    if (!canTick(ex, set)) return;
    entry(ex, set).done = true;
    final next = active;
    if (next == null) {
      completed = true;
      rest.skip();
    } else {
      final d = restAfter(plan, ex, set);
      if (d == null) {
        rest.skip();
      } else {
        rest.start(d, _label(next));
      }
    }
    notifyListeners();
  }

  /// Long-press → undo. Does not touch the rest timer.
  void undo(int ex, int set) {
    entry(ex, set).done = false;
    notifyListeners();
  }

  /// End Workout. Phase 1 has no history, so this only stops the rest.
  void end() => rest.skip();

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
