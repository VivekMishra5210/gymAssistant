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

Future<Database> openAppDatabase(Clock clock) async {
  final path = p.join(await getDatabasesPath(), 'gym_assistant.db');
  return openDatabase(
    path,
    version: 1,
    onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    onCreate: (db, _) async {
      for (final sql in _schemaV1) {
        await db.execute(sql);
      }
      await _seed(db, dateKey(clock.now()));
    },
    onUpgrade: (db, from, to) async {
      // Schema changes go here as `if (from < 2) { ... }` steps.
    },
  );
}

Future<void> _seed(Database db, String today) =>
    db.insert('app_state', {'id': 1, 'pointer_since': today});
