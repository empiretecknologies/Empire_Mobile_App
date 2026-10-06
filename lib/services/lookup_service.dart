import '../api/api_client.dart';
import '../api/api_config.dart';
import '../models/lookup_item.dart';

class LookupService {
  LookupService({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<List<LookupItem>> getCompanies() async {
    final response = await _client.get(ApiConfig.company);
    return LookupItem.listFrom(
      response.data,
      idKeys: const ['ccode'],
    );
  }

  Future<List<LookupItem>> getBranches({required int companyId}) async {
    final response = await _client.get(
      ApiConfig.branch,
      query: {'companyId': '$companyId'},
    );
    return LookupItem.listFrom(
      response.data,
      idKeys: const ['bcode'],
    );
  }

  Future<List<LookupItem>> getPeriods({required int branchId}) async {
    final response = await _client.get(
      ApiConfig.period,
      query: {'branchId': '$branchId'},
    );
    return LookupItem.listFrom(
      response.data,
      idKeys: const ['pid'],
    );
  }
}
