import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/time/clock.dart';
import '../../logic/workout_controller.dart';
import '../workout/workout_screen.dart';

/// shortcut: Phase 1 start screen with one button; the real dashboard comes in M3.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gym Assistant')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            height: 72,
            child: FilledButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider(
                  create: (c) =>
                      WorkoutController(c.read<Clock>(), hardcodedWorkout),
                  child: const WorkoutScreen(),
                ),
              )),
              child: const Text('Start Workout · $hardcodedWorkoutName',
                  style: TextStyle(fontSize: 22)),
            ),
          ),
        ),
      ),
    );
  }
}
