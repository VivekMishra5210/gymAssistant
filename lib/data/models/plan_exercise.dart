/// One exercise in a workout plan. M2 adds ids and DB mapping.
class PlanExercise {
  const PlanExercise(this.name, this.sets, this.restSeconds);

  final String name;
  final int sets;
  final int restSeconds;
}
