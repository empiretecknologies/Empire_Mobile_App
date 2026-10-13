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
