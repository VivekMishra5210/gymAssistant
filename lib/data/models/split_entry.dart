enum EntryType { workout, rest }

/// One day in the split cycle (SPEC §3, table split_entry).
class SplitEntry {
  const SplitEntry({
    required this.id,
    required this.position,
    required this.type,
    required this.name,
  });

  factory SplitEntry.fromRow(Map<String, Object?> r) => SplitEntry(
    id: r['id'] as int,
    position: r['position'] as int,
    type: r['type'] == 'rest' ? EntryType.rest : EntryType.workout,
    name: r['name'] as String,
  );

  final int id;
  final int position;
  final EntryType type;
  final String name;

  bool get isRest => type == EntryType.rest;
}
