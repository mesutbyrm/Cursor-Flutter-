import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/env.dart';
import '../core/network/dio_provider.dart';
import '../core/network/token_storage.dart';
import 'auth_service.dart';

/// Auth uçları için Bearer eklenmeyen Dio (login, register, refresh).
final authPublicDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 3),
      receiveTimeout: const Duration(seconds: 5),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    publicDio: ref.watch(authPublicDioProvider),
    resolveAuthedDio: () => ref.read(dioProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});
