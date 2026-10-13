import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../session/app_session.dart';
import 'api_config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.isUnauthorized = false});

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
    this.data2,
    this.requireChangePassword,
  });

  final int statusCode;
  final int msgType;
  final String? msg;
  final String? msgError;
  final dynamic data;
  final dynamic data2;
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
    if (text.isNotEmpty) return sanitizeMessage(text);
    return fallbackMessage(statusCode);
  }

  static String sanitizeMessage(String text) {
    var value = text.replaceAll(
      RegExp(r'<br\s*/?>', caseSensitive: false),
      ' ',
    );
    value = value.replaceAll(RegExp(r'<[^>]+>'), '');
    value = value
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
    value = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    final lower = value.toLowerCase();
    if (lower.contains('execution timeout expired') ||
        lower.contains('wait operation timed out')) {
      return 'The server took too long to load this data. Please try again.';
    }
    return value;
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
        data: map['data'] ?? map['dataTable'] ?? map['data2'],
        data2: map['data2'],
        requireChangePassword: map['requireChangePassword'] as bool?,
      );
    }

    return ApiResponse(
      statusCode: statusCode,
      msgType: 2,
      msg:
          (map['detail'] as String?) ??
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
  ApiClient({http.Client? httpClient})
    : _http = httpClient ?? IOClient(_apiHttpClient());

  static final ApiClient instance = ApiClient();

  final http.Client _http;
  static const Duration _timeout = Duration(seconds: 45);

  Future<ApiResponse> get(
    String path, {
    Map<String, String>? query,
    bool auth = true,
  }) {
    return _send(
      () => _http.get(_uri(path, query), headers: _headers(auth: auth)),
    );
  }

  Future<ApiResponse> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool auth = true,
  }) {
    return _send(
      () => _http.post(
        _uri(path, query),
        headers: _headers(auth: auth),
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Future<ApiResponse> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool auth = true,
  }) {
    return _send(
      () => _http.put(
        _uri(path, query),
        headers: _headers(auth: auth),
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Future<ApiResponse> delete(
    String path, {
    Map<String, String>? query,
    bool auth = true,
  }) {
    return _send(
      () => _http.delete(_uri(path, query), headers: _headers(auth: auth)),
    );
  }

  Uri _uri(String path, Map<String, String>? query) {
    return Uri.parse(
      '${ApiConfig.baseUrl}$path',
    ).replace(queryParameters: query == null || query.isEmpty ? null : query);
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

HttpClient _apiHttpClient() {
  // The emulator can reach the internet while its own DNS resolver or HTTP
  // proxy fails. Connect directly, and use a public resolver only if the
  // system lookup fails.
  final client = HttpClient();
  client.findProxy = (_) => 'DIRECT';
  client.connectionTimeout = const Duration(seconds: 20);
  client.connectionFactory = (uri, proxyHost, proxyPort) {
    return _connectApiSocket(proxyHost ?? uri.host, proxyPort ?? uri.port);
  };
  return client;
}

Future<ConnectionTask<Socket>> _connectApiSocket(String host, int port) async {
  final address = await _resolveIpv4(host);
  return Socket.startConnect(address, port);
}

Future<InternetAddress> _resolveIpv4(String host) async {
  final literal = InternetAddress.tryParse(host);
  if (literal != null) return literal;

  try {
    final addresses = await InternetAddress.lookup(
      host,
      type: InternetAddressType.IPv4,
    ).timeout(const Duration(seconds: 4));
    if (addresses.isNotEmpty) return addresses.first;
  } on SocketException {
    // Fall through to the public resolver.
  } on TimeoutException {
    // Fall through to the public resolver.
  }

  for (final server in const ['8.8.8.8', '1.1.1.1']) {
    final resolved = await _queryDnsA(host, InternetAddress(server));
    if (resolved != null) return resolved;
  }
  throw SocketException("Failed host lookup: '$host'");
}

Future<InternetAddress?> _queryDnsA(String host, InternetAddress server) async {
  final id = DateTime.now().microsecondsSinceEpoch & 0xffff;
  final query = <int>[
    id >> 8,
    id & 0xff,
    0x01,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
  ];
  for (final label in host.split('.')) {
    final bytes = utf8.encode(label);
    if (bytes.isEmpty || bytes.length > 63) return null;
    query
      ..add(bytes.length)
      ..addAll(bytes);
  }
  query.addAll(const [0, 0, 1, 0, 1]);

  final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  final completer = Completer<Datagram?>();
  final subscription = socket.listen((event) {
    if (event != RawSocketEvent.read || completer.isCompleted) return;
    final packet = socket.receive();
    if (packet != null) completer.complete(packet);
  });
  try {
    socket.send(query, server, 53);
    final datagram = await completer.future.timeout(
      const Duration(seconds: 4),
      onTimeout: () => null,
    );
    if (datagram == null) return null;
    return _ipv4FromDns(datagram.data, id);
  } on SocketException {
    return null;
  } finally {
    await subscription.cancel();
    socket.close();
  }
}

InternetAddress? _ipv4FromDns(List<int> data, int id) {
  if (data.length < 12) return null;
  final responseId = (data[0] << 8) | data[1];
  if (responseId != id) return null;
  if ((data[3] & 0x0f) != 0) return null;

  int skipName(int offset) {
    while (offset < data.length) {
      final length = data[offset];
      if (length == 0) return offset + 1;
      if ((length & 0xc0) == 0xc0) return offset + 2;
      offset += 1 + length;
    }
    return offset;
  }

  var offset = skipName(12);
  if (offset + 4 > data.length) return null;
  offset += 4;
  final answers = (data[6] << 8) | data[7];
  for (var i = 0; i < answers && offset + 10 <= data.length; i++) {
    offset = skipName(offset);
    if (offset + 10 > data.length) return null;
    final type = (data[offset] << 8) | data[offset + 1];
    final length = (data[offset + 8] << 8) | data[offset + 9];
    final start = offset + 10;
    if (type == 1 && length == 4 && start + 4 <= data.length) {
      return InternetAddress(
        '${data[start]}.${data[start + 1]}.${data[start + 2]}.${data[start + 3]}',
      );
    }
    offset = start + length;
  }
  return null;
}
