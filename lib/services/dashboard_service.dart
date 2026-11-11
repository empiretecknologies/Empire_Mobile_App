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

  Future<DashboardKpi> getAvailableFunds({
    required String duration,
    required DateTime fromDate,
    required DateTime toDate,
  }) {
    return _getKpi(
      ApiConfig.dashboardAvailableFunds,
      duration: duration,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  Future<DashboardKpi> getNetReceivablePayable({
    required String duration,
    required DateTime fromDate,
    required DateTime toDate,
  }) {
    return _getKpi(
      ApiConfig.dashboardNetReceivablePayable,
      duration: duration,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  Future<DashboardKpi> getPendingOrdersCount({
    required String duration,
    required DateTime fromDate,
    required DateTime toDate,
  }) {
    return _getKpi(
      ApiConfig.dashboardPendingOrders,
      duration: duration,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  Future<DashboardKpi> getTotalDelivery({
    required String duration,
    required DateTime fromDate,
    required DateTime toDate,
  }) {
    return _getKpi(
      ApiConfig.dashboardTotalDelivery,
      duration: duration,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  Future<DashboardKpi> getCashBankFlowIn({
    required String duration,
    required DateTime fromDate,
    required DateTime toDate,
  }) {
    return _getKpi(
      ApiConfig.dashboardCashBankFlowIn,
      duration: duration,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  Future<DashboardKpi> getCashBankFlowOut({
    required String duration,
    required DateTime fromDate,
    required DateTime toDate,
  }) {
    return _getKpi(
      ApiConfig.dashboardCashBankFlowOut,
      duration: duration,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  Future<DashboardChartSeries> getTotalSales({
    required String duration,
    required DateTime fromDate,
    required DateTime toDate,
  }) {
    return _getChart(
      ApiConfig.dashboardTotalSales,
      duration: duration,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  Future<DashboardChartSeries> getSalesByCategory({
    required String duration,
    required DateTime fromDate,
    required DateTime toDate,
  }) {
    return _getChart(
      ApiConfig.dashboardSalesByCategory,
      duration: duration,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  Future<DashboardChartSeries> getDailyReceived({
    required String duration,
    required DateTime fromDate,
    required DateTime toDate,
  }) {
    return _getChart(
      ApiConfig.dashboardDailyReceived,
      duration: duration,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  Future<DashboardGrid> getPartyReceivablesPayables({
    required String duration,
    required DateTime fromDate,
    required DateTime toDate,
  }) {
    return _getGrid(
      ApiConfig.dashboardPartyReceivablesPayables,
      duration: duration,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  Future<DashboardGrid> getPendingSaleOrders({
    required String duration,
    required DateTime fromDate,
    required DateTime toDate,
  }) {
    return _getGrid(
      ApiConfig.dashboardPendingSaleOrders,
      duration: duration,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  Future<DashboardGrid> getStockMovement({
    required String duration,
    required DateTime fromDate,
    required DateTime toDate,
  }) {
    return _getGrid(
      ApiConfig.dashboardStockMovement,
      duration: duration,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  Future<DashboardKpi> _getKpi(
    String path, {
    required String duration,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final response = await _client.get(
      path,
      query: _dashboardQuery(
        duration: duration,
        fromDate: fromDate,
        toDate: toDate,
      ),
    );
    return DashboardKpi.from(response.data);
  }

  Future<DashboardChartSeries> _getChart(
    String path, {
    required String duration,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final response = await _client.get(
      path,
      query: _dashboardQuery(
        duration: duration,
        fromDate: fromDate,
        toDate: toDate,
      ),
    );
    return DashboardChartSeries.from(response.data);
  }

  Future<DashboardGrid> _getGrid(
    String path, {
    required String duration,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final response = await _client.get(
      path,
      query: _dashboardQuery(
        duration: duration,
        fromDate: fromDate,
        toDate: toDate,
      ),
    );
    return DashboardGrid.from(response.data);
  }

  Map<String, String> _dashboardQuery({
    required String duration,
    required DateTime fromDate,
    required DateTime toDate,
  }) {
    return {
      ..._sessionQuery(),
      'duration': duration,
      'fromDate': _isoDate(fromDate),
      'toDate': _isoDate(toDate),
    };
  }

  String _isoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
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
