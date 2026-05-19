import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../constants/api_paths.dart';
import '../error/app_exception.dart';
import '../storage/secure_token_storage.dart';

/// Dio tabanlı REST istemcisi — JWT Bearer ve otomatik token yenileme.
class ApiClient {
  ApiClient({
    required AppConfig config,
    required SecureTokenStorage tokenStorage,
  }) : _config = config,
       _tokenStorage = tokenStorage,
       dio = Dio(
         BaseOptions(
           baseUrl: config.apiBaseUrl,
           connectTimeout: const Duration(seconds: 12),
           receiveTimeout: const Duration(seconds: 20),
           headers: const <String, Object?>{
             'Accept': 'application/json',
             'Content-Type': 'application/json',
           },
         ),
       ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  final AppConfig _config;
  final SecureTokenStorage _tokenStorage;
  final Dio dio;
  bool _isRefreshing = false;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final String? token = await _tokenStorage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final int? status = error.response?.statusCode;
    final bool isAuthPath = error.requestOptions.path.contains('auth/');
    if (status == 401 && !isAuthPath && !_isRefreshing) {
      final bool refreshed = await _tryRefreshToken();
      if (refreshed) {
        try {
          final Response<dynamic> response = await dio.fetch<dynamic>(
            error.requestOptions,
          );
          return handler.resolve(response);
        } on DioException catch (retryError) {
          return handler.next(retryError);
        }
      }
    }
    handler.next(error);
  }

  Future<bool> _tryRefreshToken() async {
    final String? refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }
    _isRefreshing = true;
    try {
      final Response<dynamic> response = await dio.post<dynamic>(
        _path(ApiPaths.refresh),
        data: <String, dynamic>{'refreshToken': refreshToken},
        options: Options(extra: <String, dynamic>{'skipAuthRefresh': true}),
      );
      final Map<String, dynamic> data = _unwrap(response.data);
      final String? access = data['accessToken'] as String?;
      final String? refresh = data['refreshToken'] as String?;
      if (access != null && refresh != null) {
        await _tokenStorage.saveTokens(
          accessToken: access,
          refreshToken: refresh,
        );
        return true;
      }
    } on Object {
      await _tokenStorage.clear();
    } finally {
      _isRefreshing = false;
    }
    return false;
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    final Response<dynamic> response = await dio.get<dynamic>(_path(path));
    return _unwrap(response.data);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final Response<dynamic> response = await dio.post<dynamic>(
      _path(path),
      data: body,
    );
    return _unwrap(response.data);
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final Response<dynamic> response = await dio.patch<dynamic>(
      _path(path),
      data: body,
    );
    return _unwrap(response.data);
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final Response<dynamic> response = await dio.delete<dynamic>(
      _path(path),
      data: body,
    );
    return _unwrap(response.data);
  }

  Future<List<dynamic>> getList(String path) async {
    final Response<dynamic> response = await dio.get<dynamic>(_path(path));
    final Object? raw = response.data;
    if (raw is List<dynamic>) {
      return raw;
    }
    final Map<String, dynamic> map = _unwrap(raw);
    final Object? items = map['items'] ?? map['rooms'] ?? map['videos'];
    if (items is List<dynamic>) {
      return items;
    }
    return <dynamic>[];
  }

  Map<String, dynamic> _unwrap(Object? data) {
    if (data is Map<String, dynamic>) {
      if (_config.usesV1Envelope && data['success'] == true && data['data'] != null) {
        final Object? inner = data['data'];
        if (inner is Map<String, dynamic>) {
          return inner;
        }
      }
      if (data['success'] == false && data['error'] is Map<String, dynamic>) {
        final Map<String, dynamic> error = data['error'] as Map<String, dynamic>;
        throw AppException(
          error['message'] as String? ?? 'API hatası',
          code: error['code'] as String?,
        );
      }
      return data;
    }
    return <String, dynamic>{};
  }

  String _path(String path) {
    if (path.startsWith('/api/v1/')) {
      return path.substring('/api/v1/'.length);
    }
    if (path.startsWith('/api/')) {
      return path.substring('/api/'.length);
    }
    if (path.startsWith('/')) {
      return path.substring(1);
    }
    return path;
  }
}
