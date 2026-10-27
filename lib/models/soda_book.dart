class SodaDocument {
  const SodaDocument({required this.master, required this.detail});

  final Map<String, dynamic> master;
  final List<Map<String, dynamic>> detail;

  factory SodaDocument.fromJson(dynamic data, {dynamic extra}) {
    if (data is List) {
      final rows = sodaRows(data);
      if (rows.isEmpty) {
        return SodaDocument(master: const {}, detail: _detailRows(null, extra));
      }
      final sameExtra = identical(extra, data);
      if (rows.length == 1) {
        return SodaDocument.fromJson(
          rows.first,
          extra: sameExtra ? null : extra,
        );
      }
      final master = _cleanMaster(_selectMaster(rows));
      if (extra != null && !sameExtra) {
        final fromExtra = _detailRows(null, extra);
        if (fromExtra.isNotEmpty) {
          return SodaDocument(master: master, detail: fromExtra);
        }
      }
      return SodaDocument(
        master: master,
        detail: _detailRows([
          for (final row in rows)
            if (!(_looksLikeMaster(row) && !_looksLikeDetail(row))) row,
        ], null),
      );
    }
    if (data is! Map) {
      return SodaDocument(master: const {}, detail: _detailRows(null, extra));
    }
    final map = Map<String, dynamic>.from(data);
    final nested = sodaField(map, 'data');
    if (!identical(nested, map) &&
        nested is Map &&
        sodaField(map, 'master') == null &&
        (sodaField(nested, 'master') != null ||
            sodaFieldLoose(nested, 'voucheR_NO') != null ||
            sodaFieldLoose(nested, 'traN_ID') != null)) {
      return SodaDocument.fromJson(nested, extra: extra);
    }
    final masterValue = sodaField(map, 'master');
    final detailValue =
        sodaField(map, 'detail') ??
        sodaField(map, 'details') ??
        sodaField(map, 'lines');
    if (masterValue != null) {
      return SodaDocument(
        master: _cleanMaster(_masterMap(masterValue)),
        detail: _detailRows(detailValue, extra),
      );
    }
    final master = Map<String, dynamic>.from(map);
    for (final key in master.keys.toList()) {
      final lower = key.toString().toLowerCase();
      if (lower == 'detail' || lower == 'details' || lower == 'lines') {
        master.remove(key);
      }
    }
    return SodaDocument(
      master: master,
      detail: _detailRows(detailValue, extra),
    );
  }

  static Map<String, dynamic> _masterMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    final rows = sodaRows(value);
    if (rows.isEmpty) return {};
    final master = _selectMaster(rows);
    if (master.isNotEmpty) return master;
    return rows.first;
  }

  static Map<String, dynamic> _selectMaster(List<Map<String, dynamic>> rows) {
    for (final row in rows) {
      if (_looksLikeMaster(row) && !_looksLikeDetail(row)) return row;
    }
    for (final row in rows) {
      if (_looksLikeMaster(row)) return row;
    }
    if (rows.length == 1) return rows.first;
    return {};
  }

  static Map<String, dynamic> _cleanMaster(Map<String, dynamic> master) {
    final copy = Map<String, dynamic>.from(master);
    for (final key in copy.keys.toList()) {
      final lower = key.toLowerCase();
      if (lower == 'detail' || lower == 'details' || lower == 'lines') {
        copy.remove(key);
      }
    }
    return copy;
  }

  static bool _looksLikeMaster(Map<String, dynamic> row) {
    return sodaFieldLoose(row, 'voucheR_NO') != null ||
        sodaFieldLoose(row, 'selleR_CODE') != null ||
        sodaFieldLoose(row, 'buyeR_CODE') != null ||
        sodaFieldLoose(row, 'sbF_TYPE') != null ||
        sodaFieldLoose(row, 'sodA_TYPE') != null ||
        sodaFieldLoose(row, 'v_DATE') != null;
  }

  static bool _looksLikeDetail(Map<String, dynamic> row) {
    return sodaFieldLoose(row, 'iteM_CODE') != null ||
        sodaFieldLoose(row, 'dT_CODE') != null ||
        sodaFieldLoose(row, 'dT_DESC') != null ||
        sodaFieldLoose(row, 'qty') != null ||
        sodaFieldLoose(row, 'qtY2') != null ||
        sodaFieldLoose(row, 'rate') != null ||
        sodaFieldLoose(row, 'amt') != null ||
        sodaFieldLoose(row, 'baL_QTY') != null;
  }

  static List<Map<String, dynamic>> _detailRows(
    dynamic detailValue,
    dynamic extra,
  ) {
    final rows = sodaRows(detailValue);
    if (rows.isNotEmpty) return _detailOnly(rows);
    if (extra == null || identical(extra, detailValue)) {
      return _detailOnly(rows);
    }
    return _detailOnly(sodaRows(extra));
  }

  static List<Map<String, dynamic>> _detailOnly(
    List<Map<String, dynamic>> rows,
  ) {
    final seen = <String>{};
    final result = <Map<String, dynamic>>[];
    for (final row in rows) {
      if (_looksLikeMaster(row) && !_looksLikeDetail(row)) continue;
      final code = sodaCode(sodaFieldLoose(row, 'dT_CODE'));
      if (code != null && code != '0' && !seen.add(code)) continue;
      result.add(row);
    }
    return result;
  }
}

class SodaOption {
  const SodaOption({
    required this.code,
    required this.name,
    this.raw = const {},
  });

  final String code;
  final String name;
  final Map<String, dynamic> raw;

  static List<SodaOption> listFrom(dynamic data) {
    final options = <SodaOption>[];
    final seen = <String>{};
    if (data is List) {
      for (final row in data) {
        final option = _fromRow(row);
        if (option == null || !seen.add(option.code)) continue;
        options.add(option);
      }
      return options;
    }
    for (final row in sodaRows(data)) {
      final option = _fromRow(row);
      if (option == null || !seen.add(option.code)) continue;
      options.add(option);
    }
    return options;
  }

  static SodaOption? _fromRow(dynamic row) {
    if (row is Map) {
      final map = Map<String, dynamic>.from(row);
      final code = _code(map);
      final name = _name(map);
      if (code.isEmpty && name.isEmpty) return null;
      final value = code.isEmpty ? name : code;
      return SodaOption(
        code: value,
        name: name.isEmpty ? value : name,
        raw: map,
      );
    }
    final text = sodaCode(row);
    if (text == null) return null;
    return SodaOption(code: text, name: text);
  }

  static String _code(Map<String, dynamic> json) {
    // Parties / KeyValue lookups: key = PartyCode, value = PartyName.
    final keyCode = sodaCode(sodaFieldLoose(json, 'key'));
    if (keyCode != null && !_isFieldLabel(keyCode)) return keyCode;
    for (final key in const [
      'customerKey',
      'custKey',
      'partyCode',
      'partyKey',
      'sellerCode',
      'itemCode',
      'unitCode',
      'currCode',
      'typeCode',
      'statusCode',
      'code',
      'id',
    ]) {
      final text = sodaCode(sodaFieldLoose(json, key));
      if (text != null && !_isFieldLabel(text)) return text;
    }
    for (final entry in json.entries) {
      final key = entry.key.toLowerCase().replaceAll('_', '');
      if (key.contains('name') ||
          key.contains('desc') ||
          key.contains('title') ||
          key == 'value') {
        continue;
      }
      if (key.endsWith('code') || key.endsWith('id') || key.endsWith('key')) {
        final text = sodaCode(entry.value);
        if (text != null && !_isFieldLabel(text)) return text;
      }
    }
    return '';
  }

  static String _name(Map<String, dynamic> json) {
    for (final key in const [
      'customerName',
      'custName',
      'partyName',
      'accountName',
      'accName',
      'cName',
      'name',
      'description',
      'title',
      'text',
      'value',
    ]) {
      final text = _displayText(sodaFieldLoose(json, key));
      if (text != null) return text;
    }
    for (final entry in json.entries) {
      final key = entry.key.toLowerCase().replaceAll('_', '');
      if (_skipDisplayKey(key)) continue;
      if (!key.contains('name') &&
          !key.contains('desc') &&
          !key.contains('title')) {
        continue;
      }
      final text = _displayText(entry.value);
      if (text != null) return text;
    }
    final code = _code(json);
    for (final entry in json.entries) {
      final key = entry.key.toLowerCase().replaceAll('_', '');
      if (_skipDisplayKey(key) ||
          key.endsWith('key') ||
          key.endsWith('code') ||
          key.endsWith('id') ||
          key == 'disc' ||
          key == 'commission') {
        continue;
      }
      final text = _displayText(entry.value);
      if (text != null && text != code) return text;
    }
    return '';
  }

  static String? _displayText(dynamic value) {
    if (value == null || value is Map || value is List) return null;
    final text = value.toString().trim();
    if (text.isEmpty || _isFieldLabel(text)) return null;
    return text;
  }

  static bool _isFieldLabel(String text) {
    final compact = text.toLowerCase().replaceAll('_', '').replaceAll(' ', '');
    return compact == 'customerkey' || compact == 'customername';
  }

  static bool _skipDisplayKey(String key) {
    return key.contains('computer') ||
        key.contains('user') ||
        key.contains('file') ||
        key.contains('menu') ||
        key.contains('postal') ||
        key.contains('machine');
  }
}

dynamic sodaField(Map<dynamic, dynamic> json, String key) {
  final lower = key.toLowerCase();
  for (final entry in json.entries) {
    if (entry.key.toString().toLowerCase() == lower) return entry.value;
  }
  return null;
}

dynamic sodaFieldLoose(Map<dynamic, dynamic> json, String key) {
  final exact = sodaField(json, key);
  if (exact != null) return exact;
  final wanted = key.toLowerCase().replaceAll('_', '');
  for (final entry in json.entries) {
    final name = entry.key.toString().toLowerCase().replaceAll('_', '');
    if (name == wanted) return entry.value;
  }
  return null;
}

void sodaSetField(Map<String, dynamic> json, String key, dynamic value) {
  String? existing;
  final wanted = key.toLowerCase().replaceAll('_', '');
  for (final current in json.keys) {
    if (current.toLowerCase() == key.toLowerCase()) {
      existing = current;
      break;
    }
  }
  if (existing == null) {
    for (final current in json.keys) {
      final name = current.toLowerCase().replaceAll('_', '');
      if (name == wanted) {
        existing = current;
        break;
      }
    }
  }
  if (existing != null && existing != key) json.remove(existing);
  json[key] = value;
}

List<Map<String, dynamic>> sodaRows(dynamic data) {
  if (data is List) {
    return [
      for (final row in data)
        if (row is Map) Map<String, dynamic>.from(row),
    ];
  }
  if (data is! Map) return const [];
  final map = Map<String, dynamic>.from(data);
  for (final key in const ['data', 'detail', 'details', 'items', 'rows']) {
    final value = sodaField(map, key);
    if (value is List) {
      final rows = sodaRows(value);
      if (rows.isNotEmpty) return rows;
    }
  }
  for (final value in map.values) {
    if (value is List) {
      final rows = sodaRows(value);
      if (rows.isNotEmpty) return rows;
    }
  }
  return const [];
}

String? sodaCode(dynamic value) {
  if (value == null) return null;
  if (value is num) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  final parsed = num.tryParse(text);
  if (parsed != null && parsed == parsed.roundToDouble()) {
    return parsed.toInt().toString();
  }
  return text;
}

int? sodaActCode(Map<String, dynamic> json) {
  for (final key in const [
    'accountCode',
    'accCode',
    'actCode',
    'aCT_CODE',
    'sacT_CODE',
    'bacT_CODE',
  ]) {
    final parsed = int.tryParse(sodaCode(sodaFieldLoose(json, key)) ?? '');
    if (parsed != null && parsed != 0) return parsed;
  }
  for (final entry in json.entries) {
    final key = entry.key.toLowerCase().replaceAll('_', '');
    if (key == 'accountcode' || key == 'acccode') {
      final parsed = int.tryParse(sodaCode(entry.value) ?? '');
      if (parsed != null && parsed != 0) return parsed;
    }
    if (!key.contains('act')) continue;
    if (!key.contains('code') && !key.endsWith('id')) continue;
    final parsed = int.tryParse(sodaCode(entry.value) ?? '');
    if (parsed != null && parsed != 0) return parsed;
  }
  return null;
}
