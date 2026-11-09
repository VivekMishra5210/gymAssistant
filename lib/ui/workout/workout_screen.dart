import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../logic/workout_controller.dart';
import 'rest_over_dialog.dart';

String _mmss(Duration d) {
  final secs = (d.inMilliseconds + 999) ~/ 1000; // round up: 0:01 until it's really over
  final h = secs ~/ 3600, m = (secs % 3600) ~/ 60, s = secs % 60;
  final ss = s.toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$ss' : '$m:$ss';
}

String _kg(double v) => v.toStringAsFixed(1);

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen>
    with WidgetsBindingObserver {
  Timer? _ticker;
  bool _popupOpen = false;
  final Set<int> _opened = {};

  WorkoutController get _w => context.read<WorkoutController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Only redraws; remaining time always comes from the stored end time.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _onTick();
  }

  void _onTick() {
    if (!mounted) return;
    if (_w.rest.takeFinished() && !_popupOpen) {
      _popupOpen = true;
      showRestOver(context, _w.restOverText)
          .whenComplete(() => _popupOpen = false);
    }
    setState(() {});
  }

  Future<void> _tick(int ex, int set) async {
    _w.tick(ex, set);
    if (_w.completed) await _finish();
  }

  Future<void> _finish() async {
    final w = _w;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: const Text('Workout complete 🎉'),
        content: Text('Duration: ${_mmss(w.elapsed)}\n'
            'Sets: ${w.setsDone}\n'
            'Volume: ${w.volume.toStringAsFixed(0)} kg'),
        actions: [
          FilledButton(
              onPressed: () => Navigator.of(c).pop(), child: const Text('Done')),
        ],
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  /// shortcut: simple confirm; reason chips + second confirm come with the DB in M2.
  Future<void> _confirmEnd() async {
    final w = _w;
    if (w.setsLeft == 0) return _finish();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('End workout now?'),
        content: Text('You have ${w.setsLeft} sets left.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(c).pop(false),
              child: const Text('Keep going')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('End Workout'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      w.end();
      Navigator.of(context).pop();
    }
  }

  Future<void> _editNumber(int ex, int set, {required bool weight}) async {
    final e = _w.entry(ex, set);
    final current = weight ? e.weight : e.reps;
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _NumberDialog(
        weight: weight,
        initial: current == null
            ? ''
            : weight
                ? _kg(current as double)
                : '$current',
      ),
    );
    if (result == null || !mounted) return;
    final text = result.trim().replaceAll(',', '.');
    if (weight) {
      final v = double.tryParse(text);
      if (text.isEmpty || (v != null && v <= 1000)) _w.setWeight(ex, set, v);
    } else {
      final v = int.tryParse(text);
      if (text.isEmpty || (v != null && v <= 1000)) _w.setReps(ex, set, v);
    }
  }

  Future<void> _doneSetMenu(int ex, int set) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
              leading: const Icon(Icons.fitness_center),
              title: const Text('Edit weight'),
              onTap: () => Navigator.of(c).pop('w')),
          ListTile(
              leading: const Icon(Icons.repeat),
              title: const Text('Edit reps'),
              onTap: () => Navigator.of(c).pop('r')),
          ListTile(
              leading: const Icon(Icons.undo),
              title: const Text('Undo this set'),
              onTap: () => Navigator.of(c).pop('u')),
        ]),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'w':
        await _editNumber(ex, set, weight: true);
      case 'r':
        await _editNumber(ex, set, weight: false);
      case 'u':
        _w.undo(ex, set);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = context.watch<WorkoutController>();
    final active = w.active;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmEnd();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(w.name),
            Text(_mmss(w.elapsed),
                style: const TextStyle(fontSize: 16, color: Colors.white70)),
          ]),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.red, minimumSize: const Size(48, 48)),
                onPressed: _confirmEnd,
                child: const Text('End Workout'),
              ),
            ),
          ],
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: w.exercises.length,
          itemBuilder: (_, i) {
            final open = i == active?.ex || _opened.contains(i);
            return _ExerciseCard(
              index: i,
              open: open,
              onToggle: () => setState(
                  () => _opened.contains(i) ? _opened.remove(i) : _opened.add(i)),
              onTick: _tick,
              onEdit: _editNumber,
              onDoneMenu: _doneSetMenu,
            );
          },
        ),
        // Not const: it must rebuild on every 1 s tick to redraw the countdown.
        bottomNavigationBar: w.rest.isResting ? _RestPanel(w) : null,
      ),
    );
  }
}

/// Owns its text controller so it's disposed only after the close animation ends.
class _NumberDialog extends StatefulWidget {
  const _NumberDialog({required this.weight, required this.initial});

  final bool weight;
  final String initial;

  @override
  State<_NumberDialog> createState() => _NumberDialogState();
}

class _NumberDialogState extends State<_NumberDialog> {
  late final _ctrl = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weight = widget.weight;
    return AlertDialog(
      title: Text(weight ? 'Weight (kg)' : 'Reps'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        keyboardType: TextInputType.numberWithOptions(decimal: weight),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
              RegExp(weight ? r'[0-9.,]' : r'[0-9]')),
        ],
        style: const TextStyle(fontSize: 28),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.of(context).pop(_ctrl.text),
            child: const Text('OK')),
      ],
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.index,
    required this.open,
    required this.onToggle,
    required this.onTick,
    required this.onEdit,
    required this.onDoneMenu,
  });

  final int index;
  final bool open;
  final VoidCallback onToggle;
  final Future<void> Function(int ex, int set) onTick;
  final Future<void> Function(int ex, int set, {required bool weight}) onEdit;
  final Future<void> Function(int ex, int set) onDoneMenu;

  @override
  Widget build(BuildContext context) {
    final w = context.watch<WorkoutController>();
    final e = w.exercises[index];
    final allDone = e.doneCount == e.sets.length;
    return Card(
      child: Column(children: [
        ListTile(
          minTileHeight: 56,
          title: Text(e.plan.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          trailing: Text('${e.doneCount}/${e.sets.length} sets',
              style: TextStyle(
                  fontSize: 16, color: allDone ? Colors.greenAccent : null)),
          onTap: onToggle,
        ),
        if (open)
          for (var s = 0; s < e.sets.length; s++)
            _SetRow(
              ex: index,
              set: s,
              onTick: onTick,
              onEdit: onEdit,
              onDoneMenu: onDoneMenu,
            ),
      ]),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.ex,
    required this.set,
    required this.onTick,
    required this.onEdit,
    required this.onDoneMenu,
  });

  final int ex;
  final int set;
  final Future<void> Function(int ex, int set) onTick;
  final Future<void> Function(int ex, int set, {required bool weight}) onEdit;
  final Future<void> Function(int ex, int set) onDoneMenu;

  @override
  Widget build(BuildContext context) {
    final w = context.watch<WorkoutController>();
    final s = w.entry(ex, set);
    final isActive = w.active == (ex: ex, set: set);
    final editable = !s.done;
    return InkWell(
      onLongPress: s.done ? () => onDoneMenu(ex, set) : null,
      child: Container(
        color: isActive ? Colors.white10 : null,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(children: [
          SizedBox(
            width: 52,
            child: Text('Set ${set + 1}',
                style: const TextStyle(fontSize: 16, color: Colors.white70)),
          ),
          Expanded(
            child: Column(children: [
              _Stepper(
                text: s.weight == null ? '– kg' : '${_kg(s.weight!)} kg',
                onMinus: editable ? () => w.bumpWeight(ex, set, -2.5) : null,
                onPlus: editable ? () => w.bumpWeight(ex, set, 2.5) : null,
                onTap: editable ? () => onEdit(ex, set, weight: true) : null,
              ),
              _Stepper(
                text: s.reps == null ? '– reps' : '${s.reps} reps',
                onMinus: editable ? () => w.bumpReps(ex, set, -1) : null,
                onPlus: editable ? () => w.bumpReps(ex, set, 1) : null,
                onTap: editable ? () => onEdit(ex, set, weight: false) : null,
              ),
            ]),
          ),
          const SizedBox(width: 8),
          SizedBox.square(
            dimension: 64,
            child: s.done
                ? const Icon(Icons.check_circle,
                    color: Colors.greenAccent, size: 48)
                : IconButton.filled(
                    iconSize: 36,
                    onPressed: w.canTick(ex, set) ? () => onTick(ex, set) : null,
                    icon: const Icon(Icons.check),
                  ),
          ),
        ]),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.text,
    required this.onMinus,
    required this.onPlus,
    required this.onTap,
  });

  final String text;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      IconButton(
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          onPressed: onMinus,
          icon: const Icon(Icons.remove)),
      Expanded(
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: Center(
                child: Text(text,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w600))),
          ),
        ),
      ),
      IconButton(
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          onPressed: onPlus,
          icon: const Icon(Icons.add)),
    ]);
  }
}

class _RestPanel extends StatelessWidget {
  const _RestPanel(this.w);

  final WorkoutController w;

  @override
  Widget build(BuildContext context) {
    final rest = w.rest;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              SizedBox.square(
                dimension: 110,
                child: Stack(fit: StackFit.expand, children: [
                  CircularProgressIndicator(
                      value: rest.progress, strokeWidth: 8),
                  Center(
                      child: Text(_mmss(rest.remaining),
                          style: const TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold))),
                ]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text('Next: ${rest.nextLabel ?? ''}',
                    style: const TextStyle(fontSize: 20)),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              for (final (label, action) in [
                ('−15s', () => rest.adjust(const Duration(seconds: -15))),
                ('+15s', () => rest.adjust(const Duration(seconds: 15))),
                ('Skip rest', rest.skip),
              ])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: SizedBox(
                      height: 56,
                      child: FilledButton.tonal(
                          onPressed: action,
                          child: Text(label, style: const TextStyle(fontSize: 18))),
                    ),
                  ),
                ),
            ]),
          ]),
        ),
      ),
    );
  }
}
