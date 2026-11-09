import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/time/dates.dart';
import '../../data/repositories/session_repository.dart';
import '../../logic/cycle_service.dart';

String _kg(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v';

String _duration(Duration d) =>
    d.inHours > 0 ? '${d.inHours}h ${d.inMinutes % 60}m' : '${d.inMinutes}m';

/// SPEC §5.6: what happened on one day.
class DayDetailScreen extends StatelessWidget {
  const DayDetailScreen({super.key, required this.date, required this.isRest});

  final String date; // yyyy-mm-dd
  final bool isRest;

  @override
  Widget build(BuildContext context) {
    final title = DateFormat('EEE, d MMM yyyy').format(parseDateKey(date));
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<List<DaySession>>(
        future: context.read<CycleService>().day(date),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('${snap.error}'));
          final sessions = snap.data;
          if (sessions == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (sessions.isEmpty) {
            return Center(
              child: Text(
                isRest ? 'Rest day 😴' : 'Nothing logged',
                style: const TextStyle(fontSize: 24),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [for (final s in sessions) _SessionCard(s)],
          );
        },
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard(this.s);

  final DaySession s;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat.Hm();
    final early = s.status == 'ended_early';
    final end = s.endedAt;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              early
                  ? 'Ended early${s.reason == null ? '' : ' · ${s.reason}'}'
                  : 'Completed',
              style: TextStyle(
                fontSize: 16,
                color: early ? Colors.orangeAccent : Colors.greenAccent,
              ),
            ),
            Text(
              end == null
                  ? time.format(s.startedAt)
                  : '${time.format(s.startedAt)}–${time.format(end)}'
                        ' · ${_duration(end.difference(s.startedAt))}',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const Divider(height: 24),
            for (final e in s.exercises) ...[
              Text(
                e.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (e.sets.isEmpty)
                const Text('No sets', style: TextStyle(color: Colors.white54)),
              for (final set in e.sets)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_kg(set.weight)} kg × ${set.reps}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    Text(
                      time.format(set.at),
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
            ],
            Text(
              'Total volume: ${NumberFormat.decimalPattern().format(s.volume.round())} kg',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
