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
    final map = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
    return DashboardSummary(
      sodaBookFeedingCount: _asNum(map['sodaBookFeedingCount']),
      deliveryFeedingCount: _asNum(map['deliveryFeedingCount']),
      pickedDeliveryCount: _asNum(map['pickedDeliveryCount']),
      outstandingBalance: _asNum(map['outstandingBalance']),
      outstandingBalances: OutstandingBalanceItem.listFrom(
        map['outstandingBalances'],
      ),
    );
  }

  static num _asNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }
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
      accountName: (json['accountName'] ?? '').toString().trim(),
      balance: DashboardSummary._asNum(json['balance']),
    );
  }

  static List<OutstandingBalanceItem> listFrom(dynamic data) {
    if (data is! List) return const [];
    return [
      for (final row in data)
        if (row is Map)
          OutstandingBalanceItem.fromJson(Map<String, dynamic>.from(row)),
    ];
  }
}
