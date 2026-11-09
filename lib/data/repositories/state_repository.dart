import 'package:sqflite/sqflite.dart';

/// Cycle pointer (SPEC §6): 1-based position + the date it applies from.
typedef Pointer = ({int position, String since});

/// SPEC §5.7 settings, stored in app_state.
typedef Settings = ({
  int graceDays,
  bool keepScreenOn,
  bool sound,
  bool vibration,
  int defaultRest,
});

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

  Future<Set<String>> restDays() async => {
    for (final r in await _db.query('rest_day_log')) r['date'] as String,
  };

  Future<int> graceDays() async => (await _row())['streak_grace_days'] as int;

  Future<Settings> settings() async {
    final r = await _row();
    return (
      graceDays: r['streak_grace_days'] as int,
      keepScreenOn: r['keep_screen_on'] == 1,
      sound: r['sound_on'] == 1,
      vibration: r['vibration_on'] == 1,
      defaultRest: r['default_rest_sec'] as int,
    );
  }

  Future<void> saveSettings(Settings s) => _db.update('app_state', {
    'streak_grace_days': s.graceDays,
    'keep_screen_on': s.keepScreenOn ? 1 : 0,
    'sound_on': s.sound ? 1 : 0,
    'vibration_on': s.vibration ? 1 : 0,
    'default_rest_sec': s.defaultRest,
  }, where: 'id = 1');

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
