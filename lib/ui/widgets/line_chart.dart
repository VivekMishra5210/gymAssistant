import 'package:flutter/material.dart';

/// Simple line chart: one value per point, oldest first.
/// Shows min/max on the left and the first/last label underneath.
class LineChart extends StatelessWidget {
  const LineChart({
    super.key,
    required this.values,
    required this.firstLabel,
    required this.lastLabel,
    this.unit = '',
    this.color = Colors.greenAccent,
  });

  final List<double> values;
  final String firstLabel;
  final String lastLabel;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const label = TextStyle(fontSize: 13, color: Colors.white60);
    return Column(
      children: [
        SizedBox(
          height: 180,
          width: double.infinity,
          child: CustomPaint(painter: _Painter(values, unit, color)),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const SizedBox(width: 44),
            Text(firstLabel, style: label),
            const Spacer(),
            Text(lastLabel, style: label),
          ],
        ),
      ],
    );
  }
}

class _Painter extends CustomPainter {
  _Painter(this.values, this.unit, this.color);

  final List<double> values;
  final String unit;
  final Color color;

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  void _text(Canvas c, String s, Offset at) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: const TextStyle(fontSize: 12, color: Colors.white60),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 44);
    tp.paint(c, at - Offset(0, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const left = 44.0, pad = 8.0;
    var lo = values.reduce((a, b) => a < b ? a : b);
    var hi = values.reduce((a, b) => a > b ? a : b);
    if (hi == lo) {
      lo -= 1;
      hi += 1;
    }
    final w = size.width - left - pad, h = size.height - 2 * pad;
    Offset at(int i) => Offset(
      left + (values.length == 1 ? w / 2 : w * i / (values.length - 1)),
      pad + h * (1 - (values[i] - lo) / (hi - lo)),
    );

    final grid = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1;
    canvas
      ..drawLine(Offset(left, pad), Offset(size.width, pad), grid)
      ..drawLine(Offset(left, pad + h), Offset(size.width, pad + h), grid);
    _text(canvas, '${_fmt(hi)}$unit', const Offset(0, pad));
    _text(canvas, '${_fmt(lo)}$unit', Offset(0, pad + h));

    final line = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(path, line);
    final dot = Paint()..color = color;
    for (var i = 0; i < values.length; i++) {
      canvas.drawCircle(at(i), 4, dot);
    }
  }

  @override
  bool shouldRepaint(_Painter old) =>
      old.values != values || old.unit != unit || old.color != color;
}
