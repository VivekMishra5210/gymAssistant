import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/notifications/rest_notifier.dart';
import '../../core/time/clock.dart';
import '../../core/time/dates.dart';
import '../../logic/cycle_service.dart';
import '../bmi/bmi_screen.dart';
import '../day_detail/day_detail_screen.dart';
import '../onboarding/onboarding_view.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';
import '../widgets/common.dart';
import '../workout/workout_screen.dart';

String _duration(Duration d) =>
    d.inHours > 0 ? '${d.inHours}h ${d.inMinutes % 60}m' : '${d.inMinutes}m';

typedef _Data = (TodayInfo, History)?; // null → no split yet (onboarding)

/// SPEC §5.2: Today card, streak row, calendar.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.openWorkout = false});

  /// Launched from the rest notification → go straight to the workout.
  final bool openWorkout;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  late Future<_Data> _data;
  late DateTime _focused;
  Timer? _midnight;
  bool _inWorkout = false;
  late final RestNotifier _notifier = context.read<RestNotifier>();

  CycleService get _cycle => context.read<CycleService>();
  Clock get _clock => context.read<Clock>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focused = _clock.now();
    _data = _load();
    _notifier.taps.addListener(_openRunning);
    if (widget.openWorkout) _openRunning();
  }

  /// Notification tapped: open the running workout unless it's already open.
  /// Its screen shows the rest-over popup itself.
  Future<void> _openRunning() async {
    if (_inWorkout) return;
    _reload();
    final id = (await _data)?.$1.sessionId;
    if (id != null && mounted && !_inWorkout) await _go(() async => id);
  }

  @override
  void dispose() {
    _midnight?.cancel();
    _notifier.taps.removeListener(_openRunning);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }

  void _reload() {
    // Block body: an arrow `=> _data = _load()` returns a Future, which setState rejects.
    if (mounted) {
      setState(() {
        _data = _load();
      });
    }
  }

  Future<_Data> _load() async {
    final cycle = _cycle;
    if (!await cycle.hasSplit()) return null;
    final today = await cycle.refresh(); // rest catch-up first, then history
    final history = await cycle.history();
    _armMidnight();
    return (today, history);
  }

  /// Re-run the catch-up at local midnight while the app stays open (SPEC §6).
  void _armMidnight() {
    if (!mounted) return;
    _midnight?.cancel();
    final now = _clock.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    _midnight = Timer(
      next.difference(now) + const Duration(seconds: 1),
      _reload,
    );
  }

  Future<void> _go(Future<int> Function() sessionId) async {
    _inWorkout = true;
    try {
      // SPEC §7: ask at Start Workout; the OS only prompts the first time.
      await _notifier.requestPermissions().catchError(
        (Object e) => debugPrint('notification permission failed: $e'),
      );
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
    } finally {
      _inWorkout = false;
    }
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym Assistant'),
        actions: [
          IconButton(
            tooltip: 'Stats',
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const StatsScreen())),
          ),
          IconButton(
            tooltip: 'BMI',
            icon: const Icon(Icons.monitor_weight),
            onPressed: () =>
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const BmiScreen())),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
              _reload();
            },
          ),
        ],
      ),
      body: FutureBuilder<_Data>(
        future: _data,
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('${snap.error}'));
          // Keep showing old data while a reload runs.
          if (!snap.hasData && snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data;
          if (data == null) return OnboardingView(onDone: _reload);
          final (info, history) = data;
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        info.splitName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.greenAccent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ..._today(info),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _StreakRow(history),
              const SizedBox(height: 8),
              Card(child: _calendar(info, history)),
            ],
          );
        },
      ),
    );
  }

  Widget _calendar(TodayInfo info, History h) {
    final now = _clock.now();
    final todayKey = dateKey(now);
    bool isRest(String key) =>
        h.restDays.contains(key) ||
        (key == todayKey && info.state == TodayState.restDay);

    return TableCalendar<Object>(
      firstDay: DateTime(2020),
      lastDay: DateTime(2100),
      focusedDay: _focused,
      currentDay: now,
      startingDayOfWeek: StartingDayOfWeek.monday,
      availableCalendarFormats: const {CalendarFormat.month: 'Month'},
      headerStyle: const HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
      ),
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        weekendTextStyle: const TextStyle(), // weekends are normal gym days
        todayDecoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        todayTextStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
      onPageChanged: (d) => _focused = d,
      onDaySelected: (selected, focused) {
        _focused = focused;
        final key = dateKey(selected);
        if (!h.days.containsKey(key) && !isRest(key)) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DayDetailScreen(date: key, isRest: isRest(key)),
          ),
        );
      },
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, _) {
          final key = dateKey(day);
          final status = h.days[key];
          if (status != null) {
            return _Dot(
              status == 'completed' ? Colors.greenAccent : Colors.orangeAccent,
            );
          }
          if (isRest(key)) return const _Dot(Colors.grey, hollow: true);
          return null;
        },
      ),
    );
  }

  List<Widget> _today(TodayInfo info) {
    const big = TextStyle(fontSize: 26, fontWeight: FontWeight.bold);
    const sub = TextStyle(fontSize: 18, color: Colors.white70);
    switch (info.state) {
      case TodayState.inProgress:
        return [
          Text('In progress · ${info.current.name}', style: big),
          const SizedBox(height: 8),
          Text(
            '${info.progress!.done}/${info.progress!.total} exercises',
            style: sub,
          ),
          const SizedBox(height: 16),
          _MainButton('Resume', () => _go(() async => info.sessionId!)),
        ];
      case TodayState.doneToday:
        return [
          Text('✓ Done · ${_duration(info.doneDuration!)}', style: big),
          const SizedBox(height: 8),
          Text('Next: ${info.current.name}', style: sub),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          _MainButton('Train anyway', () => _go(_cycle.start)),
        ];
      case TodayState.workoutDue:
        final sets = info.exercises.fold(0, (n, e) => n + e.sets);
        // Rough estimate: ~45 s per set plus the rest after it.
        final est = info.exercises.fold(
          0,
          (s, e) => s + e.sets * (45 + e.restSeconds),
        );
        return [
          Text(
            'Day ${info.current.position} · ${info.current.name}',
            style: big,
          ),
          const SizedBox(height: 8),
          Text(
            '${info.exercises.length} exercises · $sets sets · '
            '~${_duration(Duration(seconds: est))}',
            style: sub,
          ),
          const SizedBox(height: 8),
          for (final e in info.exercises)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(e.name, style: const TextStyle(fontSize: 16)),
              trailing: Text('${e.sets} × ${mmss(e.restSeconds)}'),
            ),
          const SizedBox(height: 8),
          _MainButton('Start Workout', () => _go(_cycle.start)),
        ];
    }
  }
}

class _StreakRow extends StatelessWidget {
  const _StreakRow(this.h);

  final History h;

  @override
  Widget build(BuildContext context) {
    Widget tile(String value, String label) => Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(label, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
    return Row(
      children: [
        tile('🔥 ${h.streak.current}', 'Current'),
        tile('🏆 ${h.streak.best}', 'Best'),
        tile('${h.total}', 'Workouts'),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color, {this.hollow = false});

  final Color color;
  final bool hollow;

  @override
  Widget build(BuildContext context) => Positioned(
    bottom: 5,
    child: Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hollow ? null : color,
        border: hollow ? Border.all(color: color, width: 1.5) : null,
      ),
    ),
  );
}

class _MainButton extends StatelessWidget {
  const _MainButton(this.label, this.onPressed);

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 64,
    child: FilledButton(
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontSize: 22)),
    ),
  );
}
