import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/plan_repository.dart';
import '../../logic/cycle_service.dart';
import '../../logic/stats.dart';
import '../widgets/line_chart.dart';

String _n(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

/// One exercise: PRs, last session and a chart over time.
class ExerciseProgressScreen extends StatelessWidget {
  const ExerciseProgressScreen(this.exercise, {super.key});

  final ExerciseRow exercise;

  @override
  Widget build(BuildContext context) {
    final timed = exercise.timed;
    return Scaffold(
      appBar: AppBar(title: Text(exercise.name)),
      body: FutureBuilder(
        future: context.read<CycleService>().exerciseHistory(exercise.id),
        builder: (context, snap) {
          final all = snap.data;
          if (all == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (all.isEmpty) {
            return const Center(
              child: Text(
                'No logged sets yet',
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
            );
          }
          final values = [for (final s in all) sessionValue(s, timed: timed)];
          final last = all.last;
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Row(children: _records(all, values)),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timed
                            ? 'Minutes per session'
                            : 'Heaviest set per session',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      LineChart(
                        values: values,
                        firstLabel: all.first.date,
                        lastLabel: last.date,
                        unit: timed ? 'm' : 'kg',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last session · ${last.date}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (var i = 0; i < last.sets.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            'Set ${i + 1}:  ${_set(last.sets[i])}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${all.length} sessions logged',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          );
        },
      ),
    );
  }

  String _set(ExerciseSet s) =>
      exercise.timed ? '${s.reps} min' : '${_n(s.weight)} kg × ${s.reps}';

  List<Widget> _records(List<ExerciseSession> all, List<double> values) {
    if (exercise.timed) {
      return [
        _Record('Longest', '${_n(values.reduce((a, b) => a > b ? a : b))} min'),
        _Record('Total', '${_n(values.reduce((a, b) => a + b))} min'),
      ];
    }
    final best = bestSet(all)!;
    return [
      _Record('Best set', _set(best.set), best.date),
      _Record('Est. 1RM', '${_n(bestOneRepMax(all)!)} kg'),
    ];
  }
}

class _Record extends StatelessWidget {
  const _Record(this.label, this.value, [this.sub]);

  final String label;
  final String value;
  final String? sub;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.amberAccent,
              ),
            ),
            if (sub != null)
              Text(sub!, style: const TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    ),
  );
}
