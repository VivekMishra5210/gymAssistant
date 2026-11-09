import 'package:flutter/material.dart';

import 'app.dart';
import 'core/db/app_database.dart';
import 'core/time/clock.dart';
import 'data/repositories/plan_repository.dart';
import 'data/repositories/session_repository.dart';
import 'data/repositories/state_repository.dart';
import 'logic/cycle_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const clock = SystemClock();
  final db = await openAppDatabase(clock);
  final cycle = CycleService(
    clock,
    PlanRepository(db),
    StateRepository(db),
    SessionRepository(db),
  );
  runApp(GymApp(clock: clock, cycle: cycle));
}
