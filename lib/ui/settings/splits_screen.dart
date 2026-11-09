import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/plan_repository.dart';
import '../../logic/cycle_service.dart';
import '../widgets/common.dart';
import 'split_editor_screen.dart';

typedef _Split = ({int id, String name, int days});

/// Several named splits (e.g. College, Exams, Home). One is followed;
/// tap a split to edit its days.
class SplitsScreen extends StatefulWidget {
  const SplitsScreen({super.key});

  @override
  State<SplitsScreen> createState() => _SplitsScreenState();
}

class _SplitsScreenState extends State<SplitsScreen> {
  List<_Split>? _splits;
  int? _activeId;

  PlanRepository get _plan => context.read<PlanRepository>();
  CycleService get _cycle => context.read<CycleService>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final plan = _plan;
    final splits = await plan.splits();
    final active = await plan.activeSplitId();
    if (mounted) {
      setState(() {
        _splits = splits;
        _activeId = active;
      });
    }
  }

  Future<void> _follow(_Split s) async {
    try {
      await _cycle.followSplit(s.id);
      if (mounted) showSnack(context, 'Now following ${s.name}');
    } on StateError catch (e) {
      if (mounted) showSnack(context, e.message);
    }
    await _load();
  }

  Future<void> _add() async {
    final plan = _plan;
    final r = await promptText(
      context,
      title: 'New split',
      labels: const ['Name (e.g. Home split)'],
    );
    if (r == null) return;
    await plan.addSplit(r[0]);
    await _load();
  }

  Future<void> _rename(_Split s) async {
    final plan = _plan;
    final r = await promptText(
      context,
      title: 'Rename split',
      labels: const ['Name'],
      initial: [s.name],
    );
    if (r == null) return;
    await plan.renameSplit(s.id, r[0]);
    await _load();
  }

  Future<void> _delete(_Split s) async {
    if (s.id == _activeId) {
      return showSnack(context, 'Follow another split before deleting this one');
    }
    final plan = _plan;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Delete "${s.name}"?'),
        content: const Text(
          'Its days and exercise plans are deleted. '
          'Past workouts stay in your history.',
        ),
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
    await plan.deleteSplit(s.id);
    await _load();
  }

  Future<void> _open(_Split s) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SplitEditorScreen(splitId: s.id, title: s.name),
      ),
    );
    await _load(); // day counts may have changed
  }

  @override
  Widget build(BuildContext context) {
    final splits = _splits;
    return Scaffold(
      appBar: AppBar(title: const Text('Splits')),
      body: splits == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: [for (final s in splits) _tile(s)],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('New split'),
      ),
    );
  }

  Widget _tile(_Split s) {
    final active = s.id == _activeId;
    return ListTile(
      minTileHeight: 72,
      leading: IconButton(
        tooltip: active ? 'Following' : 'Follow this split',
        icon: Icon(
          active ? Icons.check_circle : Icons.radio_button_unchecked,
          color: active ? Colors.greenAccent : null,
        ),
        onPressed: active ? null : () => _follow(s),
      ),
      title: Text(s.name, style: const TextStyle(fontSize: 18)),
      subtitle: Text(
        '${s.days} days${active ? ' · Following' : ''}',
        style: TextStyle(color: active ? Colors.greenAccent : null),
      ),
      onTap: () => _open(s),
      trailing: PopupMenuButton<String>(
        onSelected: (v) => switch (v) {
          'follow' => _follow(s),
          'rename' => _rename(s),
          _ => _delete(s),
        },
        itemBuilder: (_) => [
          if (!active)
            const PopupMenuItem(value: 'follow', child: Text('Follow this split')),
          const PopupMenuItem(value: 'rename', child: Text('Rename')),
          if (!active) const PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
    );
  }
}
