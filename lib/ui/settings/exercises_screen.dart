import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/repositories/plan_repository.dart';
import '../widgets/common.dart';

const _fields = ['Name', 'Muscle group (optional)'];

/// Ask for name + muscle group and create the exercise. Returns its id.
Future<int?> createExercise(BuildContext context) async {
  final plan = context.read<PlanRepository>();
  final r = await promptText(context, title: 'New exercise', labels: _fields);
  if (r == null || !context.mounted) return null;
  try {
    return await plan.createExercise(r[0], r[1].isEmpty ? null : r[1]);
  } on DatabaseException catch (e) {
    if (!e.isUniqueConstraintError()) rethrow;
    if (context.mounted) showSnack(context, '"${r[0]}" already exists');
    return null;
  }
}

/// SPEC §5.7 Exercises: names and muscle groups. Renaming keeps history as-is.
class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  List<ExerciseRow>? _all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await context.read<PlanRepository>().allExercises();
    if (mounted) setState(() => _all = all);
  }

  Future<void> _edit(ExerciseRow e) async {
    final plan = context.read<PlanRepository>();
    final r = await promptText(
      context,
      title: 'Edit exercise',
      labels: _fields,
      initial: [e.name, e.muscleGroup ?? ''],
    );
    if (r == null) return;
    try {
      await plan.updateExercise(e.id, r[0], r[1].isEmpty ? null : r[1]);
    } on DatabaseException catch (err) {
      if (!err.isUniqueConstraintError()) rethrow;
      if (mounted) showSnack(context, '"${r[0]}" already exists');
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final all = _all;
    return Scaffold(
      appBar: AppBar(title: const Text('Exercises')),
      body: all == null
          ? const Center(child: CircularProgressIndicator())
          : all.isEmpty
          ? const Center(
              child: Text(
                'No exercises yet',
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                for (final e in all)
                  ListTile(
                    minTileHeight: 56,
                    title: Text(e.name),
                    subtitle: e.muscleGroup == null
                        ? null
                        : Text(e.muscleGroup!),
                    trailing: const Icon(Icons.edit),
                    onTap: () => _edit(e),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await createExercise(context);
          await _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('New exercise'),
      ),
    );
  }
}
