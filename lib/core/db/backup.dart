import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

const _channel = MethodChannel('gym/backup'); // MainActivity.kt

/// Snapshot the database and let the user save it anywhere.
/// Returns false if they cancelled the picker.
Future<bool> exportBackup(Database db, String today) async {
  final tmp = File(p.join(await getDatabasesPath(), 'export.tmp'));
  if (tmp.existsSync()) tmp.deleteSync();
  try {
    // A consistent copy even while the app has the database open.
    await db.execute('VACUUM INTO ?', [tmp.path]);
    return await _channel.invokeMethod<bool>('export', {
          'path': tmp.path,
          'name': 'gym-backup-$today.db',
        }) ??
        false;
  } finally {
    if (tmp.existsSync()) tmp.deleteSync();
  }
}

/// Let the user pick a backup, check it, replace the database and restart
/// the app. Returns false if cancelled; throws [FormatException] if the file
/// isn't a usable backup (the current data is then left untouched).
Future<bool> restoreBackup(Database db) async {
  final tmp = File(p.join(await getDatabasesPath(), 'import.tmp'));
  if (tmp.existsSync()) tmp.deleteSync();
  final picked =
      await _channel.invokeMethod<bool>('import', {'path': tmp.path}) ?? false;
  if (!picked) return false;
  try {
    await _check(tmp.path);
  } catch (_) {
    tmp.deleteSync();
    rethrow;
  }
  final path = db.path;
  await db.close();
  for (final suffix in ['-journal', '-wal', '-shm']) {
    final f = File('$path$suffix');
    if (f.existsSync()) f.deleteSync();
  }
  tmp.renameSync(path); // older backups are upgraded by onUpgrade on reopen
  await _channel.invokeMethod<void>('restart');
  return true;
}

Future<void> _check(String path) async {
  Database? d;
  try {
    d = await openDatabase(path, readOnly: true, singleInstance: false);
    final v = await d.getVersion();
    if (v > dbVersion) {
      throw const FormatException('Backup is from a newer app version');
    }
    final tables = await d.rawQuery(
      "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'app_state'",
    );
    if (v < 1 || tables.isEmpty) throw const FormatException(_notBackup);
  } on DatabaseException {
    throw const FormatException(_notBackup);
  } finally {
    await d?.close();
  }
}

const _notBackup = 'Not a Gym Assistant backup';
