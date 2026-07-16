import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import 'dio_provider.dart';
import 'token_storage.dart';
import '../../services/auth_service.dart';

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
