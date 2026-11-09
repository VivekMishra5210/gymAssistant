import 'package:sqflite/sqflite.dart';

import '../../core/time/dates.dart';
import '../models/plan_exercise.dart';
import '../models/split_entry.dart';
import 'plan_repository.dart';
import 'state_repository.dart';

/// A session as stored, with its plan snapshot and logged sets.
class LoadedSession {
  LoadedSession({
    required this.id,
    required this.name,
    required this.date,
    required this.startedAt,
    required this.sessionExerciseIds,
    required this.exerciseIds,
    required this.exercises,
    required this.logs,
  });

  final int id;
  final String name;
  final String date;
  final DateTime startedAt;
  final List<int> sessionExerciseIds; // by exercise index
  final List<int?> exerciseIds; // by exercise index
  final List<PlanExercise> exercises;
  final List<({int ex, int set, double weight, int reps})> logs; // 0-based
}

/// History: sessions, their snapshot and set logs.
class SessionRepository {
  SessionRepository(this._db);

  final Database _db;

  Future<int?> inProgressId() async {
    final r = await _db.query(
      'workout_session',
      columns: ['id'],
      where: "status = 'in_progress'",
    );
    return r.isEmpty ? null : r.first['id'] as int;
  }

  /// Duration of the latest finished session started on [date], or null.
  Future<Duration?> finishedDurationOn(String date) async {
    final r = await _db.rawQuery(
      '''
      SELECT started_at, ended_at FROM workout_session
      WHERE date = ? AND status != 'in_progress'
      ORDER BY ended_at DESC LIMIT 1''',
      [date],
    );
    if (r.isEmpty) return null;
    return Duration(
      milliseconds:
          (r.first['ended_at'] as int) - (r.first['started_at'] as int),
    );
  }

  Future<int> setsDone(int sessionId) async =>
      Sqflite.firstIntValue(
        await _db.rawQuery(
          '''
        SELECT COUNT(*) FROM set_log sl
        JOIN session_exercise se ON se.id = sl.session_exercise_id
        WHERE se.session_id = ?''',
          [sessionId],
        ),
      ) ??
      0;

  /// Start Workout: session row + snapshot of the plan, in one transaction.
  Future<int> start({
    required SplitEntry entry,
    required List<PlannedExercise> exercises,
    required DateTime now,
  }) => _db.transaction((txn) async {
    final id = await txn.insert('workout_session', {
      'date': dateKey(now),
      'split_entry_id': entry.id,
      'split_entry_name': entry.name,
      'started_at': now.millisecondsSinceEpoch,
      'status': 'in_progress',
    });
    for (var i = 0; i < exercises.length; i++) {
      final x = exercises[i];
      await txn.insert('session_exercise', {
        'session_id': id,
        'exercise_id': x.exerciseId,
        'exercise_name': x.plan.name,
        'position': i + 1,
        'planned_sets': x.plan.sets,
        'rest_seconds': x.plan.restSeconds,
      });
    }
    return id;
  });

  Future<LoadedSession> load(int id) async {
    final s = (await _db.query(
      'workout_session',
      where: 'id = ?',
      whereArgs: [id],
    )).single;
    final ses = await _db.query(
      'session_exercise',
      where: 'session_id = ?',
      whereArgs: [id],
      orderBy: 'position',
    );
    final logs = await _db.rawQuery(
      '''
      SELECT se.position, sl.set_number, sl.weight_kg, sl.reps
      FROM set_log sl JOIN session_exercise se ON se.id = sl.session_exercise_id
      WHERE se.session_id = ?''',
      [id],
    );
    return LoadedSession(
      id: id,
      name: s['split_entry_name'] as String,
      date: s['date'] as String,
      startedAt: DateTime.fromMillisecondsSinceEpoch(s['started_at'] as int),
      sessionExerciseIds: [for (final r in ses) r['id'] as int],
      exerciseIds: [for (final r in ses) r['exercise_id'] as int?],
      exercises: [
        for (final r in ses)
          PlanExercise(
            r['exercise_name'] as String,
            r['planned_sets'] as int,
            r['rest_seconds'] as int,
          ),
      ],
      logs: [
        for (final r in logs)
          (
            ex: (r['position'] as int) - 1,
            set: (r['set_number'] as int) - 1,
            weight: (r['weight_kg'] as num).toDouble(),
            reps: r['reps'] as int,
          ),
      ],
    );
  }

  /// Pre-fill (SPEC §9): last weight/reps for this exercise + set number,
  /// else the exercise's most recent set of any number.
  Future<({double weight, int reps})?> lastSet(
    int exerciseId,
    int setNumber,
  ) async {
    const base = '''
      SELECT sl.weight_kg, sl.reps FROM set_log sl
      JOIN session_exercise se ON se.id = sl.session_exercise_id
      WHERE se.exercise_id = ?''';
    var r = await _db.rawQuery(
      '$base AND sl.set_number = ? ORDER BY sl.completed_at DESC LIMIT 1',
      [exerciseId, setNumber],
    );
    if (r.isEmpty) {
      r = await _db.rawQuery('$base ORDER BY sl.completed_at DESC LIMIT 1', [
        exerciseId,
      ]);
    }
    if (r.isEmpty) return null;
    return (
      weight: (r.first['weight_kg'] as num).toDouble(),
      reps: r.first['reps'] as int,
    );
  }

  /// Insert a set, or update weight/reps of an already logged one (keeps its time).
  Future<void> saveSet(
    int sessionExerciseId,
    int setNumber,
    double kg,
    int reps,
    DateTime at,
  ) => _db.rawInsert(
    '''
        INSERT INTO set_log (session_exercise_id, set_number, weight_kg, reps, completed_at)
        VALUES (?, ?, ?, ?, ?)
        ON CONFLICT (session_exercise_id, set_number)
        DO UPDATE SET weight_kg = excluded.weight_kg, reps = excluded.reps''',
    [sessionExerciseId, setNumber, kg, reps, at.millisecondsSinceEpoch],
  );

  Future<void> deleteSet(int sessionExerciseId, int setNumber) => _db.delete(
    'set_log',
    where: 'session_exercise_id = ? AND set_number = ?',
    whereArgs: [sessionExerciseId, setNumber],
  );

  /// Finish (completed / ended_early) + advance the pointer + clear rest, atomically.
  Future<void> finish({
    required int sessionId,
    required String status,
    required DateTime endedAt,
    required String? reason,
    required Pointer pointer,
  }) => _db.transaction((txn) async {
    await txn.update(
      'workout_session',
      {
        'status': status,
        'ended_at': endedAt.millisecondsSinceEpoch,
        'end_reason': reason,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
    await txn.update('app_state', {
      'pointer_position': pointer.position,
      'pointer_since': pointer.since,
      'rest_ends_at': null,
      'rest_next_label': null,
    }, where: 'id = 1');
  });
}
