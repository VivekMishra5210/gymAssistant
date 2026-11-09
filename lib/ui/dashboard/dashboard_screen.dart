import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/cycle_service.dart';
import '../workout/workout_screen.dart';

String _restText(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

String _duration(Duration d) =>
    d.inHours > 0 ? '${d.inHours}h ${d.inMinutes % 60}m' : '${d.inMinutes}m';

/// shortcut: minimal Today card (SPEC §6 states); the full dashboard comes in M3.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  late Future<TodayInfo> _info;

  CycleService get _cycle => context.read<CycleService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _info = _cycle.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }

  void _reload() => setState(() => _info = _cycle.refresh());

  Future<void> _go(Future<int> Function() sessionId) async {
    try {
      final w = await _cycle.open(await sessionId());
      if (!mounted) return w.dispose();
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => w,
            child: const WorkoutScreen(),
          ),
        ),
      );
    } on StateError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gym Assistant')),
      body: FutureBuilder<TodayInfo>(
        future: _info,
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('${snap.error}'));
          final info = snap.data;
          if (info == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: _today(info),
          );
        },
      ),
    );
  }

  List<Widget> _today(TodayInfo info) {
    const big = TextStyle(fontSize: 28, fontWeight: FontWeight.bold);
    const sub = TextStyle(fontSize: 18, color: Colors.white70);
    switch (info.state) {
      case TodayState.inProgress:
        return [
          Text('In progress · ${info.current.name}', style: big),
          const SizedBox(height: 8),
          Text('${info.setsDone} sets done', style: sub),
          const SizedBox(height: 24),
          _MainButton('Resume', () => _go(() async => info.sessionId!)),
        ];
      case TodayState.doneToday:
        return [
          Text('✓ Done · ${_duration(info.doneDuration!)}', style: big),
          const SizedBox(height: 8),
          Text('Next: ${info.current.name}', style: sub),
          const SizedBox(height: 24),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () => _go(_cycle.start),
            child: const Text('Start next anyway'),
          ),
        ];
      case TodayState.restDay:
        return [
          const Text('Rest day 😴', style: big),
          const SizedBox(height: 8),
          Text('Next: ${info.nextWorkout.name}', style: sub),
          const SizedBox(height: 24),
          _MainButton('Train anyway', () => _go(_cycle.start)),
        ];
      case TodayState.workoutDue:
        final sets = info.exercises.fold(0, (n, e) => n + e.sets);
        return [
          Text(
            'Day ${info.current.position} · ${info.current.name}',
            style: big,
          ),
          const SizedBox(height: 8),
          Text('${info.exercises.length} exercises · $sets sets', style: sub),
          const SizedBox(height: 12),
          for (final e in info.exercises)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(e.name),
              trailing: Text('${e.sets} × ${_restText(e.restSeconds)}'),
            ),
          const SizedBox(height: 16),
          _MainButton('Start Workout', () => _go(_cycle.start)),
        ];
    }
  }
}

class _MainButton extends StatelessWidget {
  const _MainButton(this.label, this.onPressed);

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 72,
    child: FilledButton(
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontSize: 22)),
    ),
  );
}
