import 'package:flutter/material.dart';

import 'app.dart';
import 'core/db/app_database.dart';
import 'core/notifications/rest_notifier.dart';
import 'core/time/clock.dart';
import 'data/repositories/plan_repository.dart';
import 'data/repositories/session_repository.dart';
import 'data/repositories/state_repository.dart';
import 'logic/cycle_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const clock = SystemClock();
  final db = await openAppDatabase(clock);
  final plan = PlanRepository(db);
  final state = StateRepository(db);
  final notifier = RestNotifier();
  final fromNotification = await notifier.init();
  final cycle = CycleService(
    clock,
    plan,
    state,
    SessionRepository(db),
    alerts: notifier,
  );
  runApp(
    GymApp(
      clock: clock,
      cycle: cycle,
      plan: plan,
      state: state,
      notifier: notifier,
      openWorkout: fromNotification,
    ),
  );
}
