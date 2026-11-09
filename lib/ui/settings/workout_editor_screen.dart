import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/split_entry.dart';
import '../../data/repositories/plan_repository.dart';
import '../../data/repositories/state_repository.dart';
import '../widgets/common.dart';
import 'exercises_screen.dart';

const _defaultSets = 3;

/// SPEC §5.7 Workout Editor: exercises of one workout entry.
/// Running sessions use their own snapshot, so edits here never touch them.
class WorkoutEditorScreen extends StatefulWidget {
  const WorkoutEditorScreen({super.key, required this.entry});

  final SplitEntry entry;

  @override
  State<WorkoutEditorScreen> createState() => _WorkoutEditorScreenState();
}

class _WorkoutEditorScreenState extends State<WorkoutEditorScreen> {
  List<PlannedExercise>? _items;

  PlanRepository get _plan => context.read<PlanRepository>();
  int get _entryId => widget.entry.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _plan.exercises(_entryId);
    if (mounted) setState(() => _items = items);
  }

  Future<void> _update(PlannedExercise x, {int? sets, int? rest}) async {
    await _plan.updatePlanExercise(
      x.id,
      (sets ?? x.plan.sets).clamp(1, 10),
      (rest ?? x.plan.restSeconds).clamp(15, 600),
    );
    await _load();
  }

  Future<void> _reorder(int from, int to) async {
    final list = [..._items!];
    list.insert(to, list.removeAt(from));
    setState(() => _items = list);
    await _plan.reorderPlanExercises([for (final x in list) x.id]);
    await _load();
  }

  Future<void> _add() async {
    final plan = _plan;
    final defaultRest =
        (await context.read<StateRepository>().settings()).defaultRest;
    final all = await plan.allExercises();
    if (!mounted) return;
    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.7,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                minTileHeight: 56,
                leading: const Icon(Icons.add),
                title: const Text('New exercise'),
                onTap: () async {
                  final id = await createExercise(context);
                  if (id != null && context.mounted) Navigator.pop(context, id);
                },
              ),
              const Divider(),
              for (final e in all)
                ListTile(
                  minTileHeight: 56,
                  title: Text(e.name),
                  subtitle: e.muscleGroup == null ? null : Text(e.muscleGroup!),
                  onTap: () => Navigator.pop(context, e.id),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null) return;
    await plan.addPlanExercise(_entryId, picked, _defaultSets, defaultRest);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      appBar: AppBar(title: Text(widget.entry.name)),
      body: items == null
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
          ? const Center(
              child: Text(
                'No exercises yet',
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
            )
          : ReorderableListView.builder(
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: items.length,
              onReorderItem: _reorder,
              itemBuilder: (context, i) => _card(items[i], i),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Add exercise'),
      ),
    );
  }

  Widget _card(PlannedExercise x, int i) {
    final sets = x.plan.sets, rest = x.plan.restSeconds;
    return Card(
      key: ValueKey(x.id),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    x.plan.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await _plan.removePlanExercise(_entryId, x.id);
                    await _load();
                  },
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
            Wrap(
              children: [
                Stepper48(
                  label: 'Sets',
                  value: '$sets',
                  onMinus: sets > 1 ? () => _update(x, sets: sets - 1) : null,
                  onPlus: sets < 10 ? () => _update(x, sets: sets + 1) : null,
                ),
                Stepper48(
                  label: 'Rest',
                  value: mmss(rest),
                  onMinus: rest > 15 ? () => _update(x, rest: rest - 15) : null,
                  onPlus: rest < 600 ? () => _update(x, rest: rest + 15) : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
