class LookupItem {
  const LookupItem({
    required this.id,
    required this.name,
    this.raw = const {},
  });

  final int id;
  final String name;
  final Map<String, dynamic> raw;

  factory LookupItem.fromJson(Map<String, dynamic> json) {
    return LookupItem(
      id: _readId(json),
      name: _readName(json),
      raw: json,
    );
  }

  static List<LookupItem> listFrom(dynamic data) {
    final items = <LookupItem>[];
    for (final row in _asRows(data)) {
      final item = LookupItem.fromJson(row);
      if (item.id != 0 || item.name.isNotEmpty) {
        items.add(item);
      }
    }
    return items;
  }

  static List<Map<String, dynamic>> _asRows(dynamic data) {
    if (data == null) return const [];
    if (data is List) {
      return [
        for (final row in data)
          if (row is Map) Map<String, dynamic>.from(row),
      ];
    }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      for (final value in map.values) {
        if (value is List) return _asRows(value);
      }
      return [map];
    }
    return const [];
  }

  static int _readId(Map<String, dynamic> json) {
    for (final entry in json.entries) {
      final key = entry.key.toLowerCase();
      if (key == 'id' || key.endsWith('id') || key.endsWith('_id')) {
        final value = _asInt(entry.value);
        if (value != null) return value;
      }
    }
    for (final value in json.values) {
      final parsed = _asInt(value);
      if (parsed != null) return parsed;
    }
    return 0;
  }

  static String _readName(Map<String, dynamic> json) {
    for (final entry in json.entries) {
      final key = entry.key.toLowerCase();
      if (key.contains('name') &&
          entry.value != null &&
          entry.value.toString().trim().isNotEmpty) {
        return entry.value.toString().trim();
      }
    }

    String? from;
    String? to;
    for (final entry in json.entries) {
      final key = entry.key.toLowerCase();
      if (from == null && (key.contains('from') || key.contains('start'))) {
        from = entry.value?.toString();
      }
      if (to == null &&
          (key.contains('to') || key.contains('end')) &&
          !key.contains('token')) {
        to = entry.value?.toString();
      }
    }
    if (from != null &&
        from.trim().isNotEmpty &&
        to != null &&
        to.trim().isNotEmpty) {
      return 'From ${from.trim()} To ${to.trim()}';
    }

    for (final entry in json.entries) {
      final key = entry.key.toLowerCase();
      if (entry.value is String &&
          entry.value.toString().trim().isNotEmpty &&
          !key.contains('id')) {
        return entry.value.toString().trim();
      }
    }
    return json['id']?.toString() ?? '';
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  @override
  bool operator ==(Object other) =>
      other is LookupItem && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}
