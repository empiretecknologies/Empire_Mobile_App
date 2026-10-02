import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../session/app_session.dart';
import 'api_config.dart';

class ApiException implements Exception {
  ApiException(
    this.message, {
    this.statusCode,
    this.isUnauthorized = false,
  });

  final String message;
  final int? statusCode;
  final bool isUnauthorized;

  @override
  String toString() => message;
}

class ApiResponse {
  ApiResponse({
    required this.statusCode,
    required this.msgType,
    this.msg,
    this.msgError,
    this.data,
    this.requireChangePassword,
  });

  final int statusCode;
  final int msgType;
  final String? msg;
  final String? msgError;
  final dynamic data;
  final bool? requireChangePassword;

  bool get isHttpSuccess => statusCode >= 200 && statusCode < 300;
  bool get isBusinessError => msgType == 2;
  bool get isSuccess => isHttpSuccess && !isBusinessError;

  String get userMessage {
    final text = (msg != null && msg!.trim().isNotEmpty)
        ? msg!.trim()
        : (msgError != null && msgError!.trim().isNotEmpty)
            ? msgError!.trim()
            : '';
    if (text.isNotEmpty) return text;
    return fallbackMessage(statusCode);
  }

  static String fallbackMessage(int? statusCode) {
    if (statusCode == 401) {
      return 'Unauthorized. Please sign in again.';
    }
    if (statusCode == 400) {
      return 'Please check your input and try again.';
    }
    if (statusCode != null && statusCode >= 500) {
      return 'Server error. Please try again later.';
    }
    return 'Something went wrong. Please try again.';
  }

  factory ApiResponse.fromHttp(int statusCode, String body) {
    if (body.trim().isEmpty) {
      return ApiResponse(
        statusCode: statusCode,
        msgType: statusCode >= 400 ? 2 : 0,
        msg: fallbackMessage(statusCode),
      );
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      return ApiResponse(
        statusCode: statusCode,
        msgType: statusCode >= 400 ? 2 : 0,
        msg: fallbackMessage(statusCode),
      );
    }

    final map = Map<String, dynamic>.from(decoded);
    if (map.containsKey('msgType') || map.containsKey('msg')) {
      return ApiResponse(
        statusCode: statusCode,
        msgType: _asInt(map['msgType']) ?? 0,
        msg: map['msg'] as String?,
        msgError: map['msgError'] as String?,
        data: map['data'],
        requireChangePassword: map['requireChangePassword'] as bool?,
      );
    }

    return ApiResponse(
      statusCode: statusCode,
      msgType: 2,
      msg: (map['detail'] as String?) ??
          (map['title'] as String?) ??
          fallbackMessage(statusCode),
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class ApiClient {
  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  static final ApiClient instance = ApiClient();

  final http.Client _http;
  static const Duration _timeout = Duration(seconds: 45);

  Future<ApiResponse> get(
    String path, {
    Map<String, String>? query,
    bool auth = true,
  }) {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(
      queryParameters: query == null || query.isEmpty ? null : query,
    );
    return _send(() => _http.get(uri, headers: _headers(auth: auth)));
  }

  Future<ApiResponse> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    return _send(
      () => _http.post(
        uri,
        headers: _headers(auth: auth),
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Map<String, String> _headers({required bool auth}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final token = AppSession.instance.token;
    if (auth && token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<ApiResponse> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(_timeout);
      final parsed = ApiResponse.fromHttp(response.statusCode, response.body);
      if (response.statusCode == 401) {
        throw ApiException(
          parsed.userMessage,
          statusCode: 401,
          isUnauthorized: true,
        );
      }
      if (!parsed.isSuccess) {
        throw ApiException(
          parsed.userMessage,
          statusCode: response.statusCode,
          isUnauthorized: false,
        );
      }
      return parsed;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('The request timed out. Please try again.');
    } on SocketException {
      throw ApiException(
        'Unable to connect. Please check your internet connection.',
      );
    } on HttpException {
      throw ApiException(
        'Unable to connect. Please check your internet connection.',
      );
    } on FormatException {
      throw ApiException('Unexpected response from server.');
    }
  }
}
