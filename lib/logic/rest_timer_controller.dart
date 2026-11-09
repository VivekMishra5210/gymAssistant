import 'package:flutter/foundation.dart';

import '../core/time/clock.dart';
import '../data/models/plan_exercise.dart';

/// SPEC §4/§7 rest rule after ticking set [setIndex] of exercise [exIndex].
/// Returns null after the last set of the last exercise (no rest).
Duration? restAfter(List<PlanExercise> plan, int exIndex, int setIndex) {
  final e = plan[exIndex];
  if (setIndex < e.sets - 1) return Duration(seconds: e.restSeconds);
  if (exIndex < plan.length - 1) {
    return Duration(seconds: plan[exIndex + 1].restSeconds);
  }
  return null;
}

/// Rest state is an end time; remaining is always computed from it (SPEC §7).
class RestTimerController extends ChangeNotifier {
  RestTimerController(this._clock);

  final Clock _clock;
  DateTime? _endsAt;
  Duration _total = Duration.zero;
  String? nextLabel;

  DateTime? get endsAt => _endsAt;
  bool get isResting => _endsAt != null;

  Duration get remaining {
    final end = _endsAt;
    if (end == null) return Duration.zero;
    final r = end.difference(_clock.now());
    return r.isNegative ? Duration.zero : r;
  }

  /// 1.0 at the start of rest, 0.0 when it's over.
  double get progress => _total.inMilliseconds == 0
      ? 0
      : (remaining.inMilliseconds / _total.inMilliseconds).clamp(0.0, 1.0);

  void start(Duration duration, String label) {
    _endsAt = _clock.now().add(duration);
    _total = duration;
    nextLabel = label;
    notifyListeners();
  }

  /// ±15s buttons. The end time never goes before now.
  void adjust(Duration delta) {
    final end = _endsAt;
    if (end == null) return;
    final now = _clock.now();
    final moved = end.add(delta);
    _endsAt = moved.isBefore(now) ? now : moved;
    if (remaining > _total) _total = remaining;
    notifyListeners();
  }

  void skip() {
    if (_endsAt == null) return;
    _clear();
    notifyListeners();
  }

  /// True exactly once when the rest has run out (tick or app resume); then clears it.
  bool takeFinished() {
    final end = _endsAt;
    if (end == null || _clock.now().isBefore(end)) return false;
    _clear();
    notifyListeners();
    return true;
  }

  void _clear() {
    _endsAt = null;
    nextLabel = null;
    _total = Duration.zero;
  }
}
