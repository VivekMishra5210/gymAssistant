import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/notifications/rest_notifier.dart';
import '../../core/time/clock.dart';
import '../../core/time/dates.dart';
import '../../data/repositories/state_repository.dart';
import '../widgets/common.dart';
import 'exercises_screen.dart';
import 'splits_screen.dart';

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

  /// Wipe test data: pick what, then confirm once more. Can't be undone.
  Future<void> _reset() async {
    final state = _state;
    final notifier = context.read<RestNotifier>();
    final today = dateKey(context.read<Clock>().now());
    final everything = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Reset data'),
        content: const Text(
          'History only: deletes workouts, sets, rest days and weigh-ins. '
          'Keeps your split, exercises and settings.\n\n'
          'Everything: also deletes your split, exercises, height and '
          'settings, like a fresh install.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('History only'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Everything'),
          ),
        ],
      ),
    );
    if (everything == null || !mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(everything ? 'Delete everything?' : 'Delete all history?'),
        content: const Text("This can't be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await notifier.cancel().catchError(
      (Object _) {},
    ); // drop a pending rest alert
    await state.reset(everything: everything, today: today);
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _export() async {
    final today = dateKey(context.read<Clock>().now());
    try {
      if (await _state.exportBackup(today) && mounted) {
        showSnack(context, 'Backup saved');
      }
    } catch (e) {
      if (mounted) showSnack(context, 'Backup failed: $e');
    }
  }

  /// Replaces everything with the picked backup, then the app restarts.
  Future<void> _restore() async {
    final state = _state;
    final notifier = context.read<RestNotifier>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Restore a backup?'),
        content: const Text(
          'Everything on this phone is replaced by the backup you pick. '
          'The app restarts after.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Pick backup'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await notifier.cancel().catchError((Object _) {});
      await state.restoreBackup(); // restarts the app on success
    } on FormatException catch (e) {
      if (mounted) showSnack(context, e.message);
    } catch (e) {
      if (mounted) showSnack(context, 'Restore failed: $e');
    }
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
                  title: const Text('Splits'),
                  subtitle: const Text('Pick the split you follow, edit days'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _push(const SplitsScreen()),
                ),
                ListTile(
                  minTileHeight: 56,
                  leading: const Icon(Icons.fitness_center),
                  title: const Text('Exercises'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _push(const ExercisesScreen()),
                ),
                const Divider(),
                const ListTile(
                  title: Text('Streak grace days'),
                  subtitle: Text('Missed days allowed in a row'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: SegmentedButton<int>(
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
                const Divider(),
                ListTile(
                  minTileHeight: 56,
                  leading: const Icon(Icons.upload_file),
                  title: const Text('Export backup'),
                  subtitle: const Text(
                    'Save all your data to Drive, Downloads…',
                  ),
                  onTap: _export,
                ),
                ListTile(
                  minTileHeight: 56,
                  leading: const Icon(Icons.settings_backup_restore),
                  title: const Text('Restore backup'),
                  subtitle: const Text(
                    'Replace this phone\'s data with a backup',
                  ),
                  onTap: _restore,
                ),
                const Divider(),
                ListTile(
                  minTileHeight: 56,
                  leading: const Icon(
                    Icons.delete_forever,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Reset data',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  subtitle: const Text(
                    'Start over: history only or everything',
                  ),
                  onTap: _reset,
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
