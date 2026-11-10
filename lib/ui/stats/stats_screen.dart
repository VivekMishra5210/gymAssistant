import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/time/clock.dart';
import '../../core/time/dates.dart';
import '../../logic/cycle_service.dart';
import '../../logic/stats.dart';
import '../settings/exercises_screen.dart';

String _dur(Duration d) =>
    d.inHours > 0 ? '${d.inHours}h ${d.inMinutes % 60}m' : '${d.inMinutes}m';

String _kg(double v) => v >= 10000
    ? '${(v / 1000).toStringAsFixed(1)} t'
    : '${v.toStringAsFixed(0)} kg';

/// Gym time, averages, sets and volume: this week, this month, all time.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late final Future<List<SessionStat>> _all = context
      .read<CycleService>()
      .stats();

  @override
  Widget build(BuildContext context) {
    final today = dateKey(context.read<Clock>().now());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ExercisesScreen())),
            icon: const Icon(Icons.emoji_events),
            label: const Text('PRs'),
          ),
        ],
      ),
      body: FutureBuilder<List<SessionStat>>(
        future: _all,
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('${snap.error}'));
          final all = snap.data;
          if (all == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (all.isEmpty) {
            return const Center(
              child: Text(
                'Finish a workout to see stats',
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
            );
          }
          final first = all
              .map((s) => s.date)
              .reduce((a, b) => a.compareTo(b) <= 0 ? a : b);
          // Days before the first workout ever don't count against the average.
          String since(String start) =>
              start.compareTo(first) < 0 ? first : start;
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _Period(
                'This week',
                periodStats(all, since(weekStart(today)), today),
              ),
              _Period(
                'This month',
                periodStats(all, since(monthStart(today)), today),
              ),
              _Period('All time', periodStats(all, first, today)),
            ],
          );
        },
      ),
    );
  }
}

class _Period extends StatelessWidget {
  const _Period(this.title, this.s);

  final String title;
  final PeriodStats s;

  @override
  Widget build(BuildContext context) {
    Widget tile(String value, String label) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(label, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title · ${s.days} days',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                tile(_dur(s.total), 'in the gym'),
                tile('${s.workouts}', 'workouts'),
                tile(_dur(s.avgPerWorkout), 'avg / workout'),
              ],
            ),
            Row(
              children: [
                tile(_dur(s.avgPerDay), 'avg / day'),
                tile('${s.sets}', 'sets'),
                tile(_kg(s.volume), 'volume'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
