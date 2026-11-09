import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/split_entry.dart';
import '../../data/repositories/plan_repository.dart';
import '../../logic/cycle_service.dart';
import '../widgets/common.dart';
import 'workout_editor_screen.dart';

const _maxEntries = 14; // SPEC §4

/// SPEC §5.7 Split Editor: add / rename / delete / reorder, set next up.
class SplitEditorScreen extends StatefulWidget {
  const SplitEditorScreen({super.key, this.splitId, this.title = 'Split'});

  /// Null = the split being followed (onboarding).
  final int? splitId;
  final String title;

  @override
  State<SplitEditorScreen> createState() => _SplitEditorScreenState();
}

class _SplitEditorScreenState extends State<SplitEditorScreen> {
  List<SplitEntry>? _entries;
  int _nextUp = 1;
  late int _splitId;
  bool _active = true;

  CycleService get _cycle => context.read<CycleService>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cycle = _cycle;
    final plan = context.read<PlanRepository>();
    final activeId = await cycle.activeSplitId();
    final id = widget.splitId ?? activeId;
    final entries = await plan.entries(splitId: id);
    final pos = await cycle.position(id);
    if (mounted) {
      setState(() {
        _splitId = id;
        _active = id == activeId;
        _entries = entries;
        _nextUp = clampPosition(pos, entries.length);
      });
    }
  }

  Future<void> _edit(Future<void> Function(PlanRepository) change) async {
    await _cycle.editSplit(_splitId, change);
    await _load();
  }

  Future<void> _addWorkout() async {
    final r = await promptText(
      context,
      title: 'New workout',
      labels: const ['Name (e.g. Back + Biceps)'],
    );
    if (r != null) await _edit((p) => p.addEntry(_splitId, EntryType.workout, r[0]));
  }

  Future<void> _rename(SplitEntry e) async {
    final r = await promptText(
      context,
      title: 'Rename',
      labels: const ['Name'],
      initial: [e.name],
    );
    if (r != null) await _edit((p) => p.renameEntry(e.id, r[0]));
  }

  Future<void> _delete(SplitEntry e) async {
    final entries = _entries!;
    if (!e.isRest && entries.where((x) => !x.isRest).length == 1) {
      return showSnack(context, 'Keep at least one workout');
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${e.name}"?'),
        content: const Text('Past workouts stay in your history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await _edit((p) => p.deleteEntry(e.id));
  }

  Future<void> _reorder(int from, int to) async {
    final list = [..._entries!];
    list.insert(to, list.removeAt(from));
    setState(() => _entries = list); // move now, save after
    await _edit((p) => p.reorderEntries([for (final e in list) e.id]));
  }

  Future<void> _setNextUp(SplitEntry e) async {
    await _cycle.setNextUp(_splitId, e.position);
    await _load();
  }

  Future<void> _open(SplitEntry e) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => WorkoutEditorScreen(entry: e)));
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    final full = entries == null || entries.length >= _maxEntries; // also blocks taps before load
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: entries == null
          ? const Center(child: CircularProgressIndicator())
          : entries.isEmpty
          ? const Center(
              child: Text(
                'Add a Workout to begin',
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
            )
          : ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: entries.length,
              onReorderItem: _reorder,
              itemBuilder: (context, i) => _tile(entries[i], i),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
                  onPressed: full ? null : _addWorkout,
                  icon: const Icon(Icons.fitness_center),
                  label: const Text('Add Workout'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 56),
                  ),
                  onPressed: full
                      ? null
                      : () => _edit((p) => p.addEntry(_splitId, EntryType.rest, 'Rest')),
                  icon: const Icon(Icons.bedtime),
                  label: const Text('Add Rest'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(SplitEntry e, int i) {
    final next = e.position == _nextUp;
    return ListTile(
      key: ValueKey(e.id),
      minTileHeight: 64,
      leading: Icon(e.isRest ? Icons.bedtime : Icons.fitness_center),
      title: Text('${e.position}. ${e.name}'),
      subtitle: next
          ? Text(
              _active ? 'Next up' : 'Resumes here',
              style: const TextStyle(color: Colors.greenAccent),
            )
          : null,
      onTap: e.isRest ? null : () => _open(e),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<String>(
            onSelected: (v) => switch (v) {
              'rename' => _rename(e),
              'next' => _setNextUp(e),
              _ => _delete(e),
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'rename', child: Text('Rename')),
              if (!next)
                const PopupMenuItem(value: 'next', child: Text('Set next up')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
          ReorderableDragStartListener(
            index: i,
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Icon(Icons.drag_handle),
            ),
          ),
        ],
      ),
    );
  }
}
