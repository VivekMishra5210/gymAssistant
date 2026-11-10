import 'package:flutter/material.dart';

/// 90 → "1:30".
String mmss(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

void showSnack(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

/// Dialog with one text field per label. The first field is required.
/// With [options], a choice is shown below and its value appended last.
/// Returns the trimmed values, or null if cancelled.
Future<List<String>?> promptText(
  BuildContext context, {
  required String title,
  required List<String> labels,
  List<String> initial = const [],
  bool number = false,
  List<String> options = const [],
}) => showDialog<List<String>>(
  context: context,
  builder: (_) => _TextDialog(title, labels, initial, number, options),
);

class _TextDialog extends StatefulWidget {
  const _TextDialog(
    this.title,
    this.labels,
    this.initial,
    this.number,
    this.options,
  );

  final String title;
  final List<String> labels;
  final List<String> initial;
  final bool number;
  final List<String> options;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final _ctrls = [
    for (var i = 0; i < widget.labels.length; i++)
      TextEditingController(
        text: i < widget.initial.length ? widget.initial[i] : '',
      ),
  ];

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  late String? _option = widget.options.firstOrNull;

  bool get _valid => _ctrls.first.text.trim().isNotEmpty;

  void _ok() {
    if (_valid) {
      Navigator.pop(context, [for (final c in _ctrls) c.text.trim(), ?_option]);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _ctrls.length; i++)
          TextField(
            controller: _ctrls[i],
            autofocus: i == 0,
            textCapitalization: TextCapitalization.words,
            keyboardType: widget.number
                ? const TextInputType.numberWithOptions(decimal: true)
                : null,
            decoration: InputDecoration(labelText: widget.labels[i]),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _ok(),
          ),
        if (widget.options.isNotEmpty) ...[
          const SizedBox(height: 16),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              for (final o in widget.options)
                ButtonSegment(value: o, label: Text(o)),
            ],
            selected: {_option!},
            onSelectionChanged: (v) => setState(() => _option = v.single),
          ),
        ],
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _valid ? _ok : null, child: const Text('OK')),
    ],
  );
}

/// "label  [−] value [+]" with 48 dp buttons. Null callback = disabled.
class Stepper48 extends StatelessWidget {
  const Stepper48({
    super.key,
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final String value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: const TextStyle(color: Colors.white70)),
      IconButton(
        icon: const Icon(Icons.remove),
        tooltip: '$label −',
        onPressed: onMinus,
      ),
      SizedBox(
        width: 48,
        child: Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.add),
        tooltip: '$label +',
        onPressed: onPlus,
      ),
    ],
  );
}
