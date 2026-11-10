import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/time/clock.dart';
import '../../core/time/dates.dart';
import '../../data/repositories/state_repository.dart';
import '../../logic/stats.dart';
import '../widgets/common.dart';
import '../widgets/line_chart.dart';

typedef _Data = ({
  double? height,
  List<({int id, String date, double kg})> log,
});

Color _color(String category) => switch (category) {
  'Normal' => Colors.greenAccent,
  'Underweight' || 'Overweight' => Colors.orangeAccent,
  _ => Colors.redAccent,
};

String _num(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

/// Height (saved once) + weigh-in log → BMI with its category.
class BmiScreen extends StatefulWidget {
  const BmiScreen({super.key});

  @override
  State<BmiScreen> createState() => _BmiScreenState();
}

class _BmiScreenState extends State<BmiScreen> {
  _Data? _data;

  StateRepository get _state => context.read<StateRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = _state;
    final data = (height: await state.heightCm(), log: await state.weights());
    if (mounted) setState(() => _data = data);
  }

  /// Number from a dialog, or null if cancelled or out of [min]..[max].
  Future<double?> _ask(
    String title,
    String label,
    double min,
    double max, [
    double? initial,
  ]) async {
    final r = await promptText(
      context,
      title: title,
      labels: [label],
      initial: [if (initial != null) _num(initial)],
      number: true,
    );
    if (r == null) return null;
    final v = double.tryParse(r[0].replaceAll(',', '.'));
    if (v == null || v < min || v > max) {
      if (mounted) {
        showSnack(context, 'Enter a number from ${_num(min)} to ${_num(max)}');
      }
      return null;
    }
    return v;
  }

  Future<void> _setHeight() async {
    final state = _state;
    final cm = await _ask('Your height', 'Height (cm)', 50, 272, _data?.height);
    if (cm == null) return;
    await state.setHeightCm(cm);
    await _load();
  }

  Future<void> _logWeight() async {
    final state = _state;
    final now = context.read<Clock>().now();
    final last = _data?.log.firstOrNull?.kg;
    final kg = await _ask('Log weight', 'Weight (kg)', 20, 400, last);
    if (kg == null) return;
    await state.addWeight(dateKey(now), kg, now);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return Scaffold(
      appBar: AppBar(title: const Text('BMI')),
      body: d == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
              children: [
                _card(d),
                if (d.log.length >= 2) _trend(d.log.reversed.toList()),
                ListTile(
                  minTileHeight: 56,
                  leading: const Icon(Icons.height),
                  title: const Text('Height'),
                  trailing: Text(
                    d.height == null ? 'Set' : '${_num(d.height!)} cm',
                    style: const TextStyle(fontSize: 18),
                  ),
                  onTap: _setHeight,
                ),
                const Divider(),
                if (d.log.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No weigh-ins yet',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ),
                for (final w in d.log)
                  ListTile(
                    minTileHeight: 56,
                    title: Text('${_num(w.kg)} kg'),
                    subtitle: Text(w.date),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (d.height != null)
                          Text(
                            'BMI ${bmi(w.kg, d.height!).toStringAsFixed(1)}',
                          ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await _state.deleteWeight(w.id);
                            await _load();
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _logWeight,
        icon: const Icon(Icons.monitor_weight),
        label: const Text('Log weight'),
      ),
    );
  }

  /// Weigh-ins oldest first, with the change since the first one.
  Widget _trend(List<({int id, String date, double kg})> log) {
    final change = log.last.kg - log.first.kg;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weight trend · ${change >= 0 ? '+' : '−'}${_num(change.abs())} kg',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            LineChart(
              values: [for (final w in log) w.kg],
              firstLabel: log.first.date,
              lastLabel: log.last.date,
              unit: 'kg',
              color: Colors.lightBlueAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(_Data d) {
    final h = d.height, w = d.log.firstOrNull?.kg;
    final String text;
    Widget? value;
    if (h == null) {
      text = 'Set your height to see your BMI';
    } else if (w == null) {
      text = 'Log your weight to see your BMI';
    } else {
      final b = bmi(w, h), cat = bmiCategory(b);
      text = '$cat · ${_num(w)} kg';
      value = Text(
        b.toStringAsFixed(1),
        style: TextStyle(
          fontSize: 56,
          fontWeight: FontWeight.bold,
          color: _color(cat),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ?value,
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
