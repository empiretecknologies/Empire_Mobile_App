class DashboardSummary {
  const DashboardSummary({
    required this.sodaBookFeedingCount,
    required this.deliveryFeedingCount,
    required this.pickedDeliveryCount,
    required this.outstandingBalance,
    this.outstandingBalances = const [],
  });

  final num sodaBookFeedingCount;
  final num deliveryFeedingCount;
  final num pickedDeliveryCount;
  final num outstandingBalance;
  final List<OutstandingBalanceItem> outstandingBalances;

  factory DashboardSummary.fromJson(dynamic data) {
    final map = mapFrom(data);
    return DashboardSummary(
      sodaBookFeedingCount:
          optionalNum(map, const ['sodaBookFeedingCount']) ?? 0,
      deliveryFeedingCount:
          optionalNum(map, const ['deliveryFeedingCount']) ?? 0,
      pickedDeliveryCount: optionalNum(map, const ['pickedDeliveryCount']) ?? 0,
      outstandingBalance: optionalNum(map, const ['outstandingBalance']) ?? 0,
      outstandingBalances: OutstandingBalanceItem.listFrom(
        valueFor(map, const ['outstandingBalances']),
      ),
    );
  }

  static Map<String, dynamic> mapFrom(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  static dynamic valueFor(Map<String, dynamic> json, List<String> keys) {
    final lowered = <String, dynamic>{
      for (final entry in json.entries) entry.key.toLowerCase(): entry.value,
    };
    for (final key in keys) {
      final lower = key.toLowerCase();
      if (lowered.containsKey(lower)) return lowered[lower];
    }
    return null;
  }

  static num? optionalNum(Map<String, dynamic> json, List<String> keys) {
    final value = valueFor(json, keys);
    if (value == null || value == '') return null;
    if (value is num) return value;
    return num.tryParse(value.toString());
  }

  static String readText(Map<String, dynamic> json, List<String> keys) {
    final value = valueFor(json, keys);
    if (value == null) return '';
    return value.toString().trim();
  }

  static List<Map<String, dynamic>> rowsFrom(dynamic data) {
    if (data is List) {
      return [
        for (final row in data)
          if (row is Map) Map<String, dynamic>.from(row),
      ];
    }
    if (data is! Map) return const [];
    final map = Map<String, dynamic>.from(data);
    for (final key in const [
      'data',
      'rows',
      'items',
      'outstandingBalances',
      'balances',
      'cities',
      'report',
    ]) {
      final value = valueFor(map, [key]);
      if (value is List) {
        final rows = rowsFrom(value);
        if (rows.isNotEmpty) return rows;
      }
    }
    for (final value in map.values) {
      if (value is List) {
        final rows = rowsFrom(value);
        if (rows.isNotEmpty) return rows;
      }
    }
    final hasScalar = map.values.any(
      (value) => value != null && value is! Map && value is! List,
    );
    if (hasScalar) return [map];
    return const [];
  }
}

String formatDashboardNumber(num value) {
  final negative = value < 0;
  final digits = value.abs().round().toString();
  final withCommas = digits.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
  return negative ? '-$withCommas' : withCommas;
}

String formatDashboardRs(num value) {
  final amount = formatDashboardNumber(value.abs());
  if (value < 0) return 'Rs. ($amount)';
  return 'Rs. $amount';
}

String formatDashboardDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final day = date.day.toString().padLeft(2, '0');
  return '$day ${months[date.month - 1]} ${date.year}';
}

String formatDashboardDateTime(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '${formatDashboardDate(date)} ${hour.toString().padLeft(2, '0')}:$minute $period';
}

String formatCompactAxis(num value) {
  final abs = value.abs();
  final sign = value < 0 ? '-' : '';
  if (abs >= 1000000000) {
    return '$sign${(abs / 1000000000).toStringAsFixed(abs >= 10000000000 ? 0 : 1)}B';
  }
  if (abs >= 1000000) {
    return '$sign${(abs / 1000000).toStringAsFixed(abs >= 100000000 ? 0 : 1)}M';
  }
  if (abs >= 1000) {
    return '$sign${(abs / 1000).toStringAsFixed(0)}K';
  }
  return formatDashboardNumber(value);
}

String formatDashboardCell(dynamic value) {
  if (value == null || value == '') return '';
  if (value is num) return formatDashboardNumber(value);
  final text = value.toString().trim();
  if (text.isEmpty) return '';
  final parsed = DateTime.tryParse(text);
  if (parsed != null &&
      (text.contains('T') || RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(text))) {
    if (parsed.hour == 0 && parsed.minute == 0 && parsed.second == 0) {
      return formatDashboardDate(parsed);
    }
    return formatDashboardDateTime(parsed);
  }
  return text;
}

class DashboardKpi {
  const DashboardKpi({required this.value, this.details = const []});

  final num value;
  final List<Map<String, dynamic>> details;

  factory DashboardKpi.from(dynamic data) {
    if (data is num) return DashboardKpi(value: data);
    final map = DashboardSummary.mapFrom(data);
    var value = _kpiNumber(map);
    if (value == null) {
      for (final nested in map.values) {
        if (nested is Map) {
          value = _kpiNumber(DashboardSummary.mapFrom(nested));
          if (value != null) break;
        }
      }
    }
    return DashboardKpi(
      value: value ?? 0,
      details: DashboardSummary.rowsFrom(data),
    );
  }

  static num? _kpiNumber(Map<String, dynamic> map) {
    final named = DashboardSummary.optionalNum(map, const [
      'value',
      'amount',
      'total',
      'count',
      'balance',
      'funds',
      'availableFunds',
      'netReceivablePayable',
      'pendingOrders',
      'totalDelivery',
      'inflow',
      'outflow',
      'debit',
      'credit',
    ]);
    if (named != null) return named;
    for (final value in map.values) {
      if (value is num) return value;
      if (value is String) {
        final parsed = num.tryParse(value.replaceAll(',', ''));
        if (parsed != null) return parsed;
      }
    }
    return null;
  }
}

class DashboardChartPoint {
  const DashboardChartPoint({
    required this.label,
    required this.value,
    this.trend,
    this.color,
    this.percentage,
  });

  final String label;
  final num value;
  final num? trend;
  final String? color;
  final num? percentage;

  num get sliceValue {
    if (trend != null) return trend!;
    return value;
  }

  factory DashboardChartPoint.fromJson(Map<String, dynamic> json) {
    return DashboardChartPoint(
      label: DashboardSummary.readText(json, const [
        'label',
        'name',
        'category',
        'date',
        'month',
        'week',
        'item',
        'itemName',
      ]),
      value:
          DashboardSummary.optionalNum(json, const [
            'value',
            'amount',
            'sales',
            'received',
            'qty',
            'total',
          ]) ??
          0,
      trend: DashboardSummary.optionalNum(json, const ['trend']),
      color: DashboardSummary.readText(json, const ['color']),
      percentage: DashboardSummary.optionalNum(json, const [
        'percentage',
        'percent',
      ]),
    );
  }
}

class DashboardChartSeries {
  const DashboardChartSeries({this.points = const [], this.total});

  final List<DashboardChartPoint> points;
  final num? total;

  factory DashboardChartSeries.from(dynamic data) {
    final map = DashboardSummary.mapFrom(data);
    final nested = DashboardSummary.valueFor(map, const [
      'points',
      'items',
      'series',
      'categories',
      'dailySales',
      'dailyReceived',
    ]);
    final rows = DashboardSummary.rowsFrom(nested ?? data);
    return DashboardChartSeries(
      points: [for (final row in rows) DashboardChartPoint.fromJson(row)]
          .where((point) => point.label.isNotEmpty || point.value != 0)
          .toList(),
      total: DashboardSummary.optionalNum(map, const [
        'total',
        'totalSales',
        'amount',
      ]),
    );
  }
}

class DashboardGrid {
  const DashboardGrid({this.columns = const [], this.records = const []});

  final List<String> columns;
  final List<Map<String, String>> records;

  factory DashboardGrid.from(dynamic data) {
    final map = DashboardSummary.mapFrom(data);
    final columnsRaw = DashboardSummary.valueFor(map, const [
      'columns',
      'headings',
      'headers',
    ]);
    final rowsRaw = DashboardSummary.valueFor(map, const [
      'rows',
      'items',
      'records',
    ]);
    if (columnsRaw is List && rowsRaw is List) {
      final columns = [
        for (final column in columnsRaw) column.toString().trim(),
      ].where((column) => column.isNotEmpty).toList();
      final records = <Map<String, String>>[];
      for (final row in rowsRaw) {
        final cells = row is List
            ? row
            : row is Map
            ? Map<String, dynamic>.from(row).values.toList()
            : [row];
        final record = <String, String>{};
        for (var i = 0; i < columns.length; i++) {
          final value = i < cells.length ? formatDashboardCell(cells[i]) : '';
          record[columns[i]] = value;
          record[_gridKey(columns[i])] = value;
        }
        records.add(record);
      }
      return DashboardGrid(columns: columns, records: records);
    }

    final rows = DashboardSummary.rowsFrom(data);
    if (rows.isEmpty) return const DashboardGrid();
    final columns = rows.first.keys.map((key) => key.toString()).toList();
    return DashboardGrid(
      columns: columns,
      records: [
        for (final row in rows)
          {
            for (final entry in row.entries) ...{
              entry.key: formatDashboardCell(entry.value),
              _gridKey(entry.key): formatDashboardCell(entry.value),
            },
          },
      ],
    );
  }

  String cell(Map<String, String> record, List<String> keys) {
    for (final key in keys) {
      final direct = record[key];
      if (direct != null && direct.trim().isNotEmpty) return direct.trim();
      final normalized = record[_gridKey(key)];
      if (normalized != null && normalized.trim().isNotEmpty) {
        return normalized.trim();
      }
    }
    for (final key in keys) {
      final needle = _gridKey(key);
      for (final entry in record.entries) {
        if (_gridKey(entry.key).contains(needle) &&
            entry.value.trim().isNotEmpty) {
          return entry.value.trim();
        }
      }
    }
    return '';
  }
}

String _gridKey(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

class OutstandingBalanceItem {
  const OutstandingBalanceItem({
    required this.accountName,
    required this.balance,
  });

  final String accountName;
  final num balance;

  factory OutstandingBalanceItem.fromJson(Map<String, dynamic> json) {
    return OutstandingBalanceItem(
      accountName: DashboardSummary.readText(json, const [
        'city',
        'cityName',
        'accountName',
        'name',
      ]),
      balance:
          DashboardSummary.optionalNum(json, const [
            'balance',
            'outstandingBalance',
            'amount',
          ]) ??
          0,
    );
  }

  static List<OutstandingBalanceItem> listFrom(dynamic data) {
    return [
      for (final row in DashboardSummary.rowsFrom(data))
        OutstandingBalanceItem.fromJson(row),
    ].where((item) => item.accountName.isNotEmpty).toList();
  }
}
