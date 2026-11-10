/// One exercise in a workout plan.
class PlanExercise {
  const PlanExercise(
    this.name,
    this.sets,
    this.restSeconds, {
    this.timed = false,
  });

  final String name;
  final int sets;
  final int restSeconds;

  /// Cardio: each set logs minutes instead of kg × reps.
  final bool timed;
}
