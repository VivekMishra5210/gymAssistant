import 'package:sqflite/sqflite.dart';

import '../models/plan_exercise.dart';
import '../models/split_entry.dart';

typedef PlannedExercise = ({int exerciseId, PlanExercise plan});

/// The plan: split entries and their exercises.
class PlanRepository {
  PlanRepository(this._db);

  final Database _db;

  Future<List<SplitEntry>> entries() async => (await _db.query(
    'split_entry',
    orderBy: 'position',
  )).map(SplitEntry.fromRow).toList();

  Future<List<PlannedExercise>> exercises(int splitEntryId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT pe.exercise_id, e.name, pe.sets, pe.rest_seconds
      FROM plan_exercise pe JOIN exercise e ON e.id = pe.exercise_id
      WHERE pe.split_entry_id = ? ORDER BY pe.position''',
      [splitEntryId],
    );
    return [
      for (final r in rows)
        (
          exerciseId: r['exercise_id'] as int,
          plan: PlanExercise(
            r['name'] as String,
            r['sets'] as int,
            r['rest_seconds'] as int,
          ),
        ),
    ];
  }
}
