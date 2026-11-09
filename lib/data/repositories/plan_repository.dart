import 'package:sqflite/sqflite.dart';

import '../models/plan_exercise.dart';
import '../models/split_entry.dart';

/// [id] is the plan_exercise row; [exerciseId] the exercise it points to.
typedef PlannedExercise = ({int id, int exerciseId, PlanExercise plan});

typedef ExerciseRow = ({int id, String name, String? muscleGroup});

/// The plan: split entries, their exercises, and the exercise list.
const _activeId = '(SELECT active_split_id FROM app_state WHERE id = 1)';

class PlanRepository {
  PlanRepository(this._db);

  final Database _db;

  /// Days of [splitId], or of the active split when null.
  Future<List<SplitEntry>> entries({int? splitId}) async => (await _db.query(
    'split_entry',
    where: splitId == null ? 'split_id = $_activeId' : 'split_id = ?',
    whereArgs: splitId == null ? null : [splitId],
    orderBy: 'position',
  )).map(SplitEntry.fromRow).toList();

  Future<List<PlannedExercise>> exercises(int splitEntryId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT pe.id, pe.exercise_id, e.name, pe.sets, pe.rest_seconds
      FROM plan_exercise pe JOIN exercise e ON e.id = pe.exercise_id
      WHERE pe.split_entry_id = ? ORDER BY pe.position''',
      [splitEntryId],
    );
    return [
      for (final r in rows)
        (
          id: r['id'] as int,
          exerciseId: r['exercise_id'] as int,
          plan: PlanExercise(
            r['name'] as String,
            r['sets'] as int,
            r['rest_seconds'] as int,
          ),
        ),
    ];
  }

  // ===== Splits (college, exams, home…) =====

  Future<int> activeSplitId() async => ((await _db.rawQuery(
    'SELECT $_activeId AS id',
  )).single['id'] as int);

  /// Every split with its number of days, oldest first.
  Future<List<({int id, String name, int days})>> splits() async => [
    for (final r in await _db.rawQuery('''
      SELECT s.id, s.name, COUNT(e.id) AS days
      FROM split s LEFT JOIN split_entry e ON e.split_id = s.id
      GROUP BY s.id ORDER BY s.id'''))
      (id: r['id'] as int, name: r['name'] as String, days: r['days'] as int),
  ];

  Future<String> splitName(int id) async => (await _db.query(
    'split',
    where: 'id = ?',
    whereArgs: [id],
  )).single['name'] as String;

  Future<int> addSplit(String name) => _db.insert('split', {'name': name});

  Future<void> renameSplit(int id, String name) =>
      _db.update('split', {'name': name}, where: 'id = ?', whereArgs: [id]);

  /// Its days and their exercises cascade; past sessions are untouched.
  Future<void> deleteSplit(int id) =>
      _db.delete('split', where: 'id = ?', whereArgs: [id]);

  /// Saved cycle position of a split that isn't active.
  Future<int> splitPointer(int id) async => (await _db.query(
    'split',
    where: 'id = ?',
    whereArgs: [id],
  )).single['pointer_position'] as int;

  Future<void> setSplitPointer(int id, int position) => _db.update(
    'split',
    {'pointer_position': position},
    where: 'id = ?',
    whereArgs: [id],
  );

  // ===== Split entries =====

  /// Onboarding: replace the active (workout-less) split's days with [entries].
  Future<void> createSplit(List<(EntryType, String)> entries) async {
    final splitId = await activeSplitId();
    await _db.transaction((txn) async {
      await txn.delete(
        'split_entry',
        where: 'split_id = ?',
        whereArgs: [splitId],
      );
      for (var i = 0; i < entries.length; i++) {
        await txn.insert('split_entry', {
          'split_id': splitId,
          'position': i + 1,
          'type': entries[i].$1.name,
          'name': entries[i].$2,
        });
      }
    });
  }

  Future<void> addEntry(int splitId, EntryType type, String name) async {
    final count = (await entries(splitId: splitId)).length;
    await _db.insert('split_entry', {
      'split_id': splitId,
      'position': count + 1,
      'type': type.name,
      'name': name,
    });
  }

  Future<void> renameEntry(int id, String name) => _db.update(
    'split_entry',
    {'name': name},
    where: 'id = ?',
    whereArgs: [id],
  );

  /// Its plan_exercise rows cascade; past sessions keep their copied names.
  Future<void> deleteEntry(int id) => _db.transaction((txn) async {
    final splitId = (await txn.query(
      'split_entry',
      where: 'id = ?',
      whereArgs: [id],
    )).single['split_id'];
    await txn.delete('split_entry', where: 'id = ?', whereArgs: [id]);
    await _renumber(txn, 'split_entry', [
      for (final r in await txn.query(
        'split_entry',
        where: 'split_id = ?',
        whereArgs: [splitId],
        orderBy: 'position',
      ))
        r['id'] as int,
    ]);
  });

  Future<void> reorderEntries(List<int> ids) =>
      _db.transaction((txn) => _renumber(txn, 'split_entry', ids));

  // ===== Exercises of one workout entry =====

  Future<void> addPlanExercise(
    int splitEntryId,
    int exerciseId,
    int sets,
    int restSeconds,
  ) async {
    final count = (await exercises(splitEntryId)).length;
    await _db.insert('plan_exercise', {
      'split_entry_id': splitEntryId,
      'exercise_id': exerciseId,
      'position': count + 1,
      'sets': sets,
      'rest_seconds': restSeconds,
    });
  }

  Future<void> updatePlanExercise(int id, int sets, int restSeconds) =>
      _db.update(
        'plan_exercise',
        {'sets': sets, 'rest_seconds': restSeconds},
        where: 'id = ?',
        whereArgs: [id],
      );

  Future<void> removePlanExercise(int splitEntryId, int id) =>
      _db.transaction((txn) async {
        await txn.delete('plan_exercise', where: 'id = ?', whereArgs: [id]);
        await _renumber(txn, 'plan_exercise', [
          for (final r in await txn.query(
            'plan_exercise',
            where: 'split_entry_id = ?',
            whereArgs: [splitEntryId],
            orderBy: 'position',
          ))
            r['id'] as int,
        ]);
      });

  Future<void> reorderPlanExercises(List<int> ids) =>
      _db.transaction((txn) => _renumber(txn, 'plan_exercise', ids));

  // ===== Exercise list =====

  Future<List<ExerciseRow>> allExercises() async => [
    for (final r in await _db.query(
      'exercise',
      where: 'is_archived = 0',
      orderBy: 'name COLLATE NOCASE',
    ))
      (
        id: r['id'] as int,
        name: r['name'] as String,
        muscleGroup: r['muscle_group'] as String?,
      ),
  ];

  /// Throws a [DatabaseException] if the name is taken.
  Future<int> createExercise(String name, String? muscleGroup) =>
      _db.insert('exercise', {'name': name, 'muscle_group': muscleGroup});

  /// History keeps the old name (session_exercise copies it).
  Future<void> updateExercise(int id, String name, String? muscleGroup) =>
      _db.update(
        'exercise',
        {'name': name, 'muscle_group': muscleGroup},
        where: 'id = ?',
        whereArgs: [id],
      );

  static Future<void> _renumber(
    Transaction txn,
    String table,
    List<int> ids,
  ) async {
    for (var i = 0; i < ids.length; i++) {
      await txn.update(
        table,
        {'position': i + 1},
        where: 'id = ?',
        whereArgs: [ids[i]],
      );
    }
  }
}
