import 'package:sqflite/sqflite.dart';

/// Cycle pointer (SPEC §6): 1-based position + the date it applies from.
typedef Pointer = ({int position, String since});

/// The single app_state row (id = 1).
class StateRepository {
  StateRepository(this._db);

  final Database _db;

  Future<Map<String, Object?>> _row() async =>
      (await _db.query('app_state', where: 'id = 1')).single;

  Future<Pointer> pointer() async {
    final r = await _row();
    return (
      position: r['pointer_position'] as int,
      since: r['pointer_since'] as String,
    );
  }

  Future<void> setPointer(Pointer p) => _db.update('app_state', {
    'pointer_position': p.position,
    'pointer_since': p.since,
  }, where: 'id = 1');

  /// Rest-day catch-up: log the passed rest days and move the pointer together.
  Future<void> applyCatchUp(Pointer p, List<String> restDates) =>
      _db.transaction((txn) async {
        for (final d in restDates) {
          await txn.insert('rest_day_log', {
            'date': d,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        await txn.update('app_state', {
          'pointer_position': p.position,
          'pointer_since': p.since,
        }, where: 'id = 1');
      });

  Future<({DateTime? endsAt, String? label})> rest() async {
    final r = await _row();
    final ms = r['rest_ends_at'] as int?;
    return (
      endsAt: ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms),
      label: r['rest_next_label'] as String?,
    );
  }

  Future<void> setRest(DateTime? endsAt, String? label) => _db.update(
    'app_state',
    {'rest_ends_at': endsAt?.millisecondsSinceEpoch, 'rest_next_label': label},
    where: 'id = 1',
  );
}
