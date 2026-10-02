import '../api/api_client.dart';
import '../api/api_config.dart';
import '../session/app_session.dart';

class AuthService {
  AuthService({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<void> login({
    required String username,
    required String password,
    required bool isRemember,
  }) async {
    final response = await _client.post(
      ApiConfig.login,
      auth: false,
      body: {
        'username': username,
        'password': password,
        'isRemember': isRemember,
      },
    );

    final token = _readToken(response.data);
    if (token == null || token.isEmpty) {
      throw ApiException(
        response.userMessage.isNotEmpty
            ? response.userMessage
            : 'Login failed.',
      );
    }

    AppSession.instance
      ..token = token
      ..username = username
      ..requireChangePassword = response.requireChangePassword ?? false;
  }

  Future<void> forgotPassword({required String username}) {
    return _client.post(
      ApiConfig.forgotPassword,
      auth: false,
      body: {'username': username},
    );
  }

  Future<void> verifyOtp({required String username, required int otp}) {
    return _client.post(
      ApiConfig.verifyOtp,
      auth: false,
      body: {
        'username': username,
        'otp': otp,
      },
    );
  }

  Future<void> resetPassword({
    required String username,
    required String password,
    required String confirmPassword,
  }) {
    return _client.post(
      ApiConfig.resetPassword,
      auth: false,
      body: {
        'username': username,
        'password': password,
        'confirmPassword': confirmPassword,
      },
    );
  }

  Future<void> saveContext({
    required String company,
    required String branch,
    required String period,
  }) {
    return _client.post(
      ApiConfig.loginContext,
      body: {
        'company': company,
        'branch': branch,
        'period': period,
      },
    );
  }

  Future<void> logout() async {
    try {
      if (AppSession.instance.isLoggedIn) {
        await _client.post(ApiConfig.logout);
      }
    } on ApiException {
      // Local session is still cleared by the caller.
    } finally {
      AppSession.instance.clear();
    }
  }

  static String? _readToken(dynamic data) {
    if (data is String && data.trim().isNotEmpty) return data.trim();
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final token = map['token'] ?? map['Token'];
      if (token != null && token.toString().trim().isNotEmpty) {
        return token.toString().trim();
      }
    }
    return null;
  }
}
