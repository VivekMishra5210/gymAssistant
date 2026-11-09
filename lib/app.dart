import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/time/clock.dart';
import 'ui/dashboard/dashboard_screen.dart';

class GymApp extends StatelessWidget {
  const GymApp({super.key, this.clock = const SystemClock()});

  final Clock clock;

  @override
  Widget build(BuildContext context) {
    return Provider<Clock>.value(
      value: clock,
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
