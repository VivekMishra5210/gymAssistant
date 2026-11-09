import '../core/time/dates.dart';

/// One finished session (completed or ended early).
typedef SessionStat = ({
  String date,
  Duration duration,
  double volume,
  int sets,
});

class PeriodStats {
  const PeriodStats({
    required this.workouts,
    required this.total,
    required this.sets,
    required this.volume,
    required this.days,
  });

  final int workouts;
  final Duration total;
  final int sets;
  final double volume; // Σ weight × reps, kg
  final int days; // calendar days in the period, rest days included

  Duration get avgPerWorkout =>
      workouts == 0 ? Duration.zero : total ~/ workouts;
  Duration get avgPerDay => days == 0 ? Duration.zero : total ~/ days;
}

/// Sessions with [from] ≤ date ≤ [to] (inclusive 'yyyy-mm-dd').
PeriodStats periodStats(List<SessionStat> all, String from, String to) {
  final inRange = all.where(
    (s) => s.date.compareTo(from) >= 0 && s.date.compareTo(to) <= 0,
  );
  return PeriodStats(
    workouts: inRange.length,
    total: inRange.fold(Duration.zero, (t, s) => t + s.duration),
    sets: inRange.fold(0, (n, s) => n + s.sets),
    volume: inRange.fold(0.0, (v, s) => v + s.volume),
    days: from.compareTo(to) > 0 ? 0 : daysBetween(from, to) + 1,
  );
}

/// Calendar days from [a] to [b] (UTC math, so DST can't shift it).
int daysBetween(String a, String b) {
  final x = parseDateKey(a), y = parseDateKey(b);
  return DateTime.utc(
    y.year,
    y.month,
    y.day,
  ).difference(DateTime.utc(x.year, x.month, x.day)).inDays;
}

/// Monday of [today]'s week (the calendar starts on Monday).
String weekStart(String today) =>
    addDays(today, 1 - parseDateKey(today).weekday);

String monthStart(String today) => '${today.substring(0, 8)}01';

// ===== BMI =====

double bmi(double weightKg, double heightCm) {
  final m = heightCm / 100;
  return weightKg / (m * m);
}

/// WHO adult categories.
String bmiCategory(double bmi) => bmi < 18.5
    ? 'Underweight'
    : bmi < 25
    ? 'Normal'
    : bmi < 30
    ? 'Overweight'
    : 'Obese';
