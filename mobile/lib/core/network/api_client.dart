import 'package:dio/dio.dart';

import 'api.dart';
import 'api_endpoints.dart';
import 'dio_provider.dart';

/// Tek merkezi HTTP istemcisi — tüm feature katmanları [dioProvider] / [Api.dio] kullanır.
///
/// Yeni kod doğrudan Dio çağırmamalı; repository veya remote datasource üzerinden gider.
/// Servis eşlemesi (web ile aynı backend uçları):
///
/// | Facade | Modül |
/// |--------|-------|
/// | Auth | `features/auth/` |
/// | User / Profile / Wallet | `features/profile/` |
/// | Room / Chat / Music | `features/voice_hub/` |
/// | Live / PK | `features/live/` |
/// | Gift | `features/gifts/` |
/// | Notification | `features/notifications/` |
/// | Story / Social | `features/social/` |
/// | Shorts | `features/shorts/` |
/// | Search / Follow | `features/search/`, `features/profile/` |
/// | Admin | `features/admin/` |
abstract final class ApiClient {
  ApiClient._();

  /// Paylaşımlı Dio — interceptors: auth, refresh, retry, routing, cache.
  static Dio get dio => Api.dio;

  static String get baseUrl => dio.options.baseUrl;

  static void bind(Dio client) => Api.bind(client);

  static void setToken(String? token) => Api.setToken(token);

  static Future<bool> healthy() => Api.healthy();
}
