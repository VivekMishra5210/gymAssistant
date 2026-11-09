import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../time/clock.dart';
import '../time/dates.dart';

/// SPEC §9 schema, version 1.
const _schemaV1 = [
  '''CREATE TABLE split_entry (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    position INTEGER NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('workout','rest')),
    name TEXT NOT NULL)''',
  '''CREATE TABLE exercise (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    muscle_group TEXT,
    is_archived INTEGER NOT NULL DEFAULT 0)''',
  '''CREATE TABLE plan_exercise (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    split_entry_id INTEGER NOT NULL REFERENCES split_entry(id) ON DELETE CASCADE,
    exercise_id INTEGER NOT NULL REFERENCES exercise(id),
    position INTEGER NOT NULL,
    sets INTEGER NOT NULL CHECK (sets BETWEEN 1 AND 10),
    rest_seconds INTEGER NOT NULL CHECK (rest_seconds BETWEEN 15 AND 600))''',
  '''CREATE TABLE app_state (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    pointer_position INTEGER NOT NULL DEFAULT 1,
    pointer_since TEXT NOT NULL,
    rest_ends_at INTEGER,
    rest_next_label TEXT,
    streak_grace_days INTEGER NOT NULL DEFAULT 1,
    keep_screen_on INTEGER NOT NULL DEFAULT 1,
    sound_on INTEGER NOT NULL DEFAULT 1,
    vibration_on INTEGER NOT NULL DEFAULT 1,
    default_rest_sec INTEGER NOT NULL DEFAULT 90)''',
  '''CREATE TABLE workout_session (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,
    split_entry_id INTEGER,
    split_entry_name TEXT NOT NULL,
    started_at INTEGER NOT NULL,
    ended_at INTEGER,
    status TEXT NOT NULL CHECK (status IN ('in_progress','completed','ended_early')),
    end_reason TEXT)''',
  '''CREATE TABLE session_exercise (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id INTEGER NOT NULL REFERENCES workout_session(id) ON DELETE CASCADE,
    exercise_id INTEGER,
    exercise_name TEXT NOT NULL,
    position INTEGER NOT NULL,
    planned_sets INTEGER NOT NULL,
    rest_seconds INTEGER NOT NULL)''',
  '''CREATE TABLE set_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_exercise_id INTEGER NOT NULL REFERENCES session_exercise(id) ON DELETE CASCADE,
    set_number INTEGER NOT NULL,
    weight_kg REAL NOT NULL CHECK (weight_kg >= 0),
    reps INTEGER NOT NULL CHECK (reps >= 1),
    completed_at INTEGER NOT NULL,
    UNIQUE (session_exercise_id, set_number))''',
  'CREATE TABLE rest_day_log (date TEXT PRIMARY KEY)',
  'CREATE INDEX idx_session_date ON workout_session(date)',
  'CREATE INDEX idx_setlog_lookup ON set_log(session_exercise_id, set_number)',
  // Only one in_progress session at a time (SPEC §9).
  "CREATE UNIQUE INDEX idx_one_in_progress ON workout_session(status) WHERE status = 'in_progress'",
];

/// v2: BMI — height in app_state, body weight log.
const _schemaV2 = [
  'ALTER TABLE app_state ADD COLUMN height_cm REAL',
  '''CREATE TABLE body_weight (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,
    weight_kg REAL NOT NULL CHECK (weight_kg > 0),
    logged_at INTEGER NOT NULL)''',
];

/// v3: several named splits (college / exams / home); one is active.
/// Each split remembers its own cycle position while it isn't active.
/// FKs are on during upgrades, so the added FK column must default to NULL.
const _schemaV3 = [
  '''CREATE TABLE split (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    pointer_position INTEGER NOT NULL DEFAULT 1)''',
  "INSERT INTO split (id, name) VALUES (1, 'My split')",
  'ALTER TABLE split_entry ADD COLUMN split_id INTEGER REFERENCES split(id) ON DELETE CASCADE',
  'UPDATE split_entry SET split_id = 1',
  'ALTER TABLE app_state ADD COLUMN active_split_id INTEGER',
  'UPDATE app_state SET active_split_id = 1',
];

Future<Database> openAppDatabase(Clock clock) async {
  final path = p.join(await getDatabasesPath(), 'gym_assistant.db');
  return openDatabase(
    path,
    version: 3,
    onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    onCreate: (db, _) async {
      for (final sql in [..._schemaV1, ..._schemaV2, ..._schemaV3]) {
        await db.execute(sql);
      }
      await _seed(db, dateKey(clock.now()));
    },
    onUpgrade: (db, from, to) async {
      if (from < 2) {
        for (final sql in _schemaV2) {
          await db.execute(sql);
        }
      }
      if (from < 3) {
        for (final sql in _schemaV3) {
          await db.execute(sql);
        }
      }
    },
  );
}

Future<void> _seed(DatabaseExecutor db, String today) async {
  await db.insert('split', {
    'id': 1,
    'name': 'My split',
  }, conflictAlgorithm: ConflictAlgorithm.ignore);
  await db.insert('app_state', {
    'id': 1,
    'pointer_since': today,
    'active_split_id': 1,
  });
}

/// Settings → Reset. History: sessions, sets, rest days, weigh-ins.
/// Everything: also split, exercises, height and settings (like a fresh install).
Future<void> resetData(
  Database db, {
  required bool everything,
  required String today,
}) => db.transaction((txn) async {
  await txn.delete('workout_session'); // cascades session_exercise, set_log
  await txn.delete('rest_day_log');
  await txn.delete('body_weight');
  if (everything) {
    await txn.delete('plan_exercise');
    await txn.delete('split_entry');
    await txn.delete('split');
    await txn.delete('exercise');
    await txn.delete('app_state');
    await _seed(txn, today);
  } else {
    await txn.update('app_state', {
      'rest_ends_at': null,
      'rest_next_label': null,
    }, where: 'id = 1');
  }
});
