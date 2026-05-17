import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'token_store.dart';

class ApiClient {
  ApiClient({http.Client? httpClient, TokenStore? tokenStore})
    : _httpClient = httpClient ?? http.Client(),
      _tokenStore = tokenStore ?? TokenStore();

  final http.Client _httpClient;
  final TokenStore _tokenStore;

  bool get isConfigured => ApiConfig.hasBaseUrl;

  Future<dynamic> get(String path, {Map<String, String>? query}) {
    return _send('GET', path, query: query);
  }

  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, String>? query,
  }) {
    return _send('POST', path, body: body, query: query);
  }

  Future<dynamic> put(String path, {Object? body, Map<String, String>? query}) {
    return _send('PUT', path, body: body, query: query);
  }

  Future<dynamic> delete(
    String path, {
    Object? body,
    Map<String, String>? query,
  }) {
    return _send('DELETE', path, body: body, query: query);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
  }) async {
    if (!isConfigured) {
      throw const ApiException('API_BASE_URL tanımlı değil.');
    }

    final Uri uri = _buildUri(path, query);
    final String? token = await _tokenStore.readAccessToken();
    final Map<String, String> headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final String? encodedBody = body == null ? null : jsonEncode(body);
    late final http.Response response;

    try {
      response = await switch (method) {
        'GET' => _httpClient.get(uri, headers: headers),
        'POST' => _httpClient.post(uri, headers: headers, body: encodedBody),
        'PUT' => _httpClient.put(uri, headers: headers, body: encodedBody),
        'DELETE' => _httpClient.delete(
          uri,
          headers: headers,
          body: encodedBody,
        ),
        _ => throw ApiException('Desteklenmeyen method: $method'),
      }.timeout(ApiConfig.requestTimeout);
    } on TimeoutException {
      throw const ApiException('API isteği zaman aşımına uğradı.');
    } on http.ClientException catch (error) {
      throw ApiException(error.message);
    }

    final dynamic decoded = response.body.isEmpty
        ? null
        : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final String message = decoded is Map<String, dynamic>
          ? (decoded['message'] ?? decoded['error'] ?? response.reasonPhrase)
                .toString()
          : response.reasonPhrase ?? 'API hatası';
      throw ApiException(message, statusCode: response.statusCode);
    }

    return decoded;
  }

  Uri _buildUri(String path, Map<String, String>? query) {
    final Uri baseUri = Uri.parse(ApiConfig.baseUrl);
    final String normalizedPath = path.startsWith('/')
        ? path.substring(1)
        : path;
    final String basePath = baseUri.path.endsWith('/')
        ? baseUri.path.substring(0, baseUri.path.length - 1)
        : baseUri.path;

    return baseUri.replace(
      path: <String>[
        if (basePath.isNotEmpty) basePath,
        normalizedPath,
      ].join('/'),
      queryParameters: query,
    );
  }
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
