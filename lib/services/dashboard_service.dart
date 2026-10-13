import '../api/api_client.dart';
import '../api/api_config.dart';
import '../models/dashboard_summary.dart';
import '../session/app_session.dart';

class DashboardService {
  DashboardService({ApiClient? client})
    : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<
    ({
      num sodaBookFeedingCount,
      num deliveryFeedingCount,
      num pickedDeliveryCount,
      num? outstandingBalance,
    })
  >
  getCounts() async {
    final response = await _client.get(
      ApiConfig.mobileDashboardCounts,
      query: _sessionQuery(),
    );
    final map = _figures(response.data);
    return (
      sodaBookFeedingCount:
          DashboardSummary.optionalNum(map, const ['sodaBookFeedingCount']) ??
          0,
      deliveryFeedingCount:
          DashboardSummary.optionalNum(map, const ['deliveryFeedingCount']) ??
          0,
      pickedDeliveryCount:
          DashboardSummary.optionalNum(map, const ['pickedDeliveryCount']) ?? 0,
      outstandingBalance: DashboardSummary.optionalNum(map, const [
        'outstandingBalance',
      ]),
    );
  }

  Future<({num? outstandingBalance, List<OutstandingBalanceItem> items})>
  getOutstanding() async {
    final response = await _client.get(
      ApiConfig.mobileDashboardOutstanding,
      query: _sessionQuery(),
    );
    final data = response.data;
    final map = DashboardSummary.mapFrom(data);
    return (
      outstandingBalance: data is Map
          ? DashboardSummary.optionalNum(map, const ['outstandingBalance'])
          : null,
      items: OutstandingBalanceItem.listFrom(data),
    );
  }

  Future<List<Map<String, dynamic>>> getCityOutstanding(String city) async {
    final name = city.trim();
    if (name.isEmpty) {
      throw ApiException('City is required.');
    }
    final response = await _client.get(
      ApiConfig.mobileCityOutstanding,
      query: {..._sessionQuery(), 'city': name},
    );
    return DashboardSummary.rowsFrom(response.data);
  }

  Map<String, String> _sessionQuery() {
    final session = AppSession.instance;
    final company = session.ccode;
    final branch = session.bcode;
    final period = session.pid;
    if (company == null || branch == null || period == null) {
      throw ApiException('Company, Branch and Period are required.');
    }
    return {'company': '$company', 'branch': '$branch', 'period': '$period'};
  }

  Map<String, dynamic> _figures(dynamic data) {
    final map = DashboardSummary.mapFrom(data);
    if (_hasFigure(map)) return map;
    for (final value in map.values) {
      if (value is Map) {
        final nested = DashboardSummary.mapFrom(value);
        if (_hasFigure(nested)) return nested;
      }
    }
    return map;
  }

  bool _hasFigure(Map<String, dynamic> map) {
    return DashboardSummary.optionalNum(map, const [
          'sodaBookFeedingCount',
          'deliveryFeedingCount',
          'pickedDeliveryCount',
          'outstandingBalance',
        ]) !=
        null;
  }
}
