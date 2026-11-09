/// Local calendar dates as 'yyyy-mm-dd' (SPEC §9). These strings sort correctly.
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

DateTime parseDateKey(String key) {
  final p = key.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

/// Calendar-day math (safe across DST changes).
String addDays(String key, int days) {
  final d = parseDateKey(key);
  return dateKey(DateTime(d.year, d.month, d.day + days));
}

String _two(int n) => n.toString().padLeft(2, '0');
