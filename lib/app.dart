import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/notifications/rest_notifier.dart';
import 'core/time/clock.dart';
import 'data/repositories/plan_repository.dart';
import 'data/repositories/state_repository.dart';
import 'logic/cycle_service.dart';
import 'ui/dashboard/dashboard_screen.dart';

class GymApp extends StatelessWidget {
  const GymApp({
    super.key,
    required this.clock,
    required this.cycle,
    required this.plan,
    required this.state,
    required this.notifier,
    this.openWorkout = false,
  });

  final Clock clock;
  final CycleService cycle;
  final PlanRepository plan;
  final StateRepository state;
  final RestNotifier notifier;
  final bool openWorkout; // launched by tapping the rest notification

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<Clock>.value(value: clock),
        Provider<CycleService>.value(value: cycle),
        Provider<PlanRepository>.value(value: plan),
        Provider<StateRepository>.value(value: state),
        Provider<RestNotifier>.value(value: notifier),
      ],
      child: MaterialApp(
        title: 'Gym Assistant',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.greenAccent,
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: Colors.black,
          materialTapTargetSize: MaterialTapTargetSize.padded,
        ),
        home: DashboardScreen(openWorkout: openWorkout),
      ),
    );
  }
}
