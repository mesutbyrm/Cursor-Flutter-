import 'package:dio/dio.dart';

import '../config/env.dart';
import 'api_endpoints.dart';

/// Merkezi Dio istemcisi — [dioProvider] ile paylaşılır.
///
/// Ana site: [Env.apiBaseUrl] · Oyun odaları: [Env.gamesApiBaseUrl]
abstract final class Api {
  static Dio? _bound;

  /// Riverpod [dioProvider] oluşturduktan sonra bağlar.
  static void bind(Dio dio) => _bound = dio;

  static Dio get dio => _bound ?? _standalone;

  static final Dio _standalone = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  static void setToken(String? token) {
    final client = dio;
    if (token == null || token.isEmpty) {
      client.options.headers.remove('Authorization');
    } else {
      client.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  /// `GET /api/v1/health` — splash / arka plan sağlık kontrolü.
  static Future<bool> healthy() async {
    try {
      final r = await dio.get<Map<String, dynamic>>(ApiEndpoints.apiHealth);
      final data = r.data;
      if (data == null) return false;
      if (data['status'] == 'ok') return true;
      final nested = data['data'];
      if (nested is Map && nested['status'] == 'ok') return true;
      return false;
    } catch (_) {
      return false;
    }
  }
}
