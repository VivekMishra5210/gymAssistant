import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/state_repository.dart';
import '../widgets/common.dart';
import 'exercises_screen.dart';
import 'split_editor_screen.dart';

/// SPEC §5.7. Each change saves right away.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Settings? _s;

  StateRepository get _state => context.read<StateRepository>();

  @override
  void initState() {
    super.initState();
    _state.settings().then((s) {
      if (mounted) setState(() => _s = s);
    });
  }

  void _save(Settings s) {
    setState(() => _s = s);
    _state.saveSettings(s);
  }

  void _push(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final s = _s;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ListTile(
                  minTileHeight: 56,
                  leading: const Icon(Icons.calendar_view_week),
                  title: const Text('Split'),
                  subtitle: const Text('Workout & rest days, exercises'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _push(const SplitEditorScreen()),
                ),
                ListTile(
                  minTileHeight: 56,
                  leading: const Icon(Icons.fitness_center),
                  title: const Text('Exercises'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _push(const ExercisesScreen()),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Streak grace days'),
                  subtitle: const Text('Missed days allowed in a row'),
                  trailing: SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: [
                      for (var g = 0; g <= 3; g++)
                        ButtonSegment(value: g, label: Text('$g')),
                    ],
                    selected: {s.graceDays},
                    onSelectionChanged: (v) => _save((
                      graceDays: v.single,
                      keepScreenOn: s.keepScreenOn,
                      sound: s.sound,
                      vibration: s.vibration,
                      defaultRest: s.defaultRest,
                    )),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Keep screen on during workout'),
                  value: s.keepScreenOn,
                  onChanged: (v) => _save((
                    graceDays: s.graceDays,
                    keepScreenOn: v,
                    sound: s.sound,
                    vibration: s.vibration,
                    defaultRest: s.defaultRest,
                  )),
                ),
                SwitchListTile(
                  title: const Text('Sound on rest end'),
                  value: s.sound,
                  onChanged: (v) => _save((
                    graceDays: s.graceDays,
                    keepScreenOn: s.keepScreenOn,
                    sound: v,
                    vibration: s.vibration,
                    defaultRest: s.defaultRest,
                  )),
                ),
                SwitchListTile(
                  title: const Text('Vibration'),
                  value: s.vibration,
                  onChanged: (v) => _save((
                    graceDays: s.graceDays,
                    keepScreenOn: s.keepScreenOn,
                    sound: s.sound,
                    vibration: v,
                    defaultRest: s.defaultRest,
                  )),
                ),
                ListTile(
                  title: const Text('Default rest'),
                  subtitle: const Text('For newly added exercises'),
                  trailing: Stepper48(
                    label: '',
                    value: mmss(s.defaultRest),
                    onMinus: s.defaultRest > 15
                        ? () => _save(_rest(s, s.defaultRest - 15))
                        : null,
                    onPlus: s.defaultRest < 600
                        ? () => _save(_rest(s, s.defaultRest + 15))
                        : null,
                  ),
                ),
              ],
            ),
    );
  }

  static Settings _rest(Settings s, int rest) => (
    graceDays: s.graceDays,
    keepScreenOn: s.keepScreenOn,
    sound: s.sound,
    vibration: s.vibration,
    defaultRest: rest,
  );
}
