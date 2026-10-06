import '../api/api_client.dart';
import '../api/api_config.dart';
import '../models/dashboard_summary.dart';
import '../session/app_session.dart';

class DashboardService {
  DashboardService({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<DashboardSummary> getDashboard() async {
    final session = AppSession.instance;
    final company = session.ccode;
    final branch = session.bcode;
    final period = session.pid;
    if (company == null || branch == null || period == null) {
      throw ApiException('Company, Branch and Period are required.');
    }

    final response = await _client.get(
      ApiConfig.mobileDashboard,
      query: {
        'company': '$company',
        'branch': '$branch',
        'period': '$period',
      },
    );
    return DashboardSummary.fromJson(response.data);
  }
}
