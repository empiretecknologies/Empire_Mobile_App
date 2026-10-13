import '../api/api_client.dart';
import '../api/api_config.dart';
import '../models/soda_book.dart';
import '../session/app_session.dart';

class SodaBookService {
  SodaBookService({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<List<Map<String, dynamic>>> quickSearch({String search = ''}) async {
    final query = _sessionQuery();
    query['top'] = '100';
    final text = search.trim();
    if (text.isNotEmpty) query['search'] = text;
    final response = await _client.get(
      ApiConfig.sodaBookFeedingQuickSearch,
      query: query,
    );
    return _masterRecords(response.data);
  }

  Future<SodaDocument> getById(int id) async {
    final response = await _client.get(
      '${ApiConfig.sodaBookFeeding}/$id',
      query: _sessionQuery(),
    );
    return SodaDocument.fromJson(response.data, extra: response.data2);
  }

  Future<dynamic> save({
    required Map<String, dynamic> master,
    required List<Map<String, dynamic>> detail,
    required bool update,
  }) async {
    final body = {'master': master, 'detail': detail};
    final response = update
        ? await _client.put(
            ApiConfig.sodaBookFeeding,
            query: _sessionQuery(),
            body: body,
          )
        : await _client.post(
            ApiConfig.sodaBookFeeding,
            query: _sessionQuery(),
            body: body,
          );
    return response.data;
  }

  Future<void> delete(int id) {
    return _client.delete(
      '${ApiConfig.sodaBookFeeding}/$id',
      query: _sessionQuery(),
    );
  }

  Future<List<SodaOption>> statuses() =>
      _lookup(ApiConfig.sodaBookFeedingStatuses);

  Future<List<SodaOption>> movements() =>
      _lookup(ApiConfig.sodaBookFeedingMovements);

  Future<List<SodaOption>> parties() =>
      _lookup(ApiConfig.sodaBookFeedingParties);

  Future<List<SodaOption>> conditions() =>
      _lookup(ApiConfig.sodaBookFeedingConditions);

  Future<List<SodaOption>> types() => _lookup(ApiConfig.sodaBookFeedingTypes);

  Future<List<SodaOption>> currencies() =>
      _lookup(ApiConfig.sodaBookFeedingCurrencies);

  Future<List<SodaOption>> units() => _lookup(ApiConfig.sodaBookFeedingUnits);

  Future<List<SodaOption>> sodaTypes() =>
      _lookup(ApiConfig.sodaBookFeedingSodaTypes);

  Future<List<SodaOption>> items() => _lookup(ApiConfig.sodaBookFeedingItems);

  Future<List<SodaOption>> rtTypes() =>
      _lookup(ApiConfig.sodaBookFeedingRtTypes);

  List<Map<String, dynamic>> _masterRecords(dynamic data) {
    final masters = <Map<String, dynamic>>[];
    for (final row in sodaRows(data)) {
      if (!_isMasterRecord(row)) continue;
      masters.add(row);
      if (masters.length == 100) return masters;
    }
    if (masters.isEmpty && data is Map) {
      final map = Map<String, dynamic>.from(data);
      if (_isMasterRecord(map)) return [map];
    }
    return masters;
  }

  bool _isMasterRecord(Map<String, dynamic> row) {
    final id = int.tryParse(sodaCode(sodaFieldLoose(row, 'traN_ID')) ?? '');
    final voucher = sodaFieldLoose(row, 'voucheR_NO')?.toString().trim() ?? '';
    if ((id == null || id == 0) && voucher.isEmpty) return false;
    final hasDetail =
        sodaFieldLoose(row, 'iteM_CODE') != null ||
        sodaFieldLoose(row, 'dT_CODE') != null;
    final hasMaster =
        voucher.isNotEmpty ||
        sodaFieldLoose(row, 'v_DATE') != null ||
        sodaFieldLoose(row, 'selleR_CODE') != null ||
        sodaFieldLoose(row, 'sbF_TYPE') != null;
    if (hasDetail && !hasMaster) return false;
    return true;
  }

  Future<List<SodaOption>> _lookup(String path) async {
    final response = await _client.get(path, query: _sessionQuery());
    return SodaOption.listFrom(response.data);
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
}
