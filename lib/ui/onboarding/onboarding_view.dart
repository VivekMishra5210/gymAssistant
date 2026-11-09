import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/split_entry.dart';
import '../../logic/cycle_service.dart';
import '../settings/split_editor_screen.dart';

/// W = workout, R = rest (SPEC §5.1, §3).
const _templates = {
  '6 on / 1 off': 'WWWWWWR',
  '5 on / 2 off': 'WWWWWRR',
  '4 on / 3 off': 'WWRWWRR',
};

/// Placeholder names, no exercises: "Workout 1", …, "Rest".
List<(EntryType, String)> templateEntries(String pattern) {
  var n = 0;
  return [
    for (final c in pattern.split(''))
      c == 'W'
          ? (EntryType.workout, 'Workout ${++n}')
          : (EntryType.rest, 'Rest'),
  ];
}

/// Shown on the dashboard while the split has no workout entry.
class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key, required this.onDone});

  final VoidCallback onDone;

  Future<void> _create(BuildContext context, String pattern) async {
    await context.read<CycleService>().createSplit(templateEntries(pattern));
    if (!context.mounted) return;
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SplitEditorScreen()));
    onDone();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const Text(
        'Create your split',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      const Text(
        'Pick a template, then name your days and add exercises.',
        style: TextStyle(fontSize: 16, color: Colors.white70),
      ),
      const SizedBox(height: 24),
      for (final t in _templates.entries) ...[
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: () => _create(context, t.value),
            child: Text(t.key, style: const TextStyle(fontSize: 20)),
          ),
        ),
        const SizedBox(height: 12),
      ],
      SizedBox(
        height: 56,
        child: OutlinedButton(
          onPressed: () => _create(context, ''),
          child: const Text('Start empty', style: TextStyle(fontSize: 20)),
        ),
      ),
    ],
  );
}
