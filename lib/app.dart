import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/time/clock.dart';
import 'logic/cycle_service.dart';
import 'ui/dashboard/dashboard_screen.dart';

class GymApp extends StatelessWidget {
  const GymApp({super.key, required this.clock, required this.cycle});

  final Clock clock;
  final CycleService cycle;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<Clock>.value(value: clock),
        Provider<CycleService>.value(value: cycle),
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
        home: const DashboardScreen(),
      ),
    );
  }
}
