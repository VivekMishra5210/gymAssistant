import '../core/time/dates.dart';

class Streak {
  const Streak(this.current, this.best);

  final int current;
  final int best;
}

/// SPEC §8. Dates are 'yyyy-mm-dd'. Rest days are neutral; more than [grace]
/// missed days in a row break the chain. Today only counts once it's covered.
Streak computeStreak({
  required Set<String> workoutDays,
  required Set<String> restDays,
  required int grace,
  required String today,
}) {
  if (workoutDays.isEmpty) return const Streak(0, 0);
  final first = workoutDays.reduce((a, b) => a.compareTo(b) <= 0 ? a : b);
  bool covered(String d) => workoutDays.contains(d) || restDays.contains(d);

  var current = 0, misses = 0;
  for (
    var d = covered(today) ? today : addDays(today, -1);
    d.compareTo(first) >= 0;
    d = addDays(d, -1)
  ) {
    if (workoutDays.contains(d)) {
      current++;
      misses = 0;
    } else if (restDays.contains(d)) {
      misses = 0;
    } else if (++misses > grace) {
      break;
    }
  }

  // Best: the same chain rules run forward over all history.
  var best = 0, run = 0;
  misses = 0;
  for (var d = first; d.compareTo(today) <= 0; d = addDays(d, 1)) {
    if (workoutDays.contains(d)) {
      run++;
      misses = 0;
      if (run > best) best = run;
    } else if (restDays.contains(d)) {
      misses = 0;
    } else if (++misses > grace) {
      run = 0;
      misses = 0;
    }
  }
  return Streak(current, best);
}
