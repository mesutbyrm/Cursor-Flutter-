import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/env.dart';
import 'network/api_endpoints.dart';
import 'network/auth_token_refresh_coordinator.dart';
import 'network/token_storage.dart';
import 'sse_client.dart';

export 'sse_client.dart';

final sseClientProvider = Provider<SseClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final refreshDio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  final client = SseClient(
    accessToken: storage.readAccess,
    refreshTokens: () => tryRefreshAccessTokenLegacy(
      refreshDio,
      storage,
      refreshPath: ApiEndpoints.authMobileRefresh,
    ),
  );
  ref.onDispose(client.disconnectAll);
  return client;
});

final sseClientLifecycleProvider = Provider<SseClientLifecycleBinding>((ref) {
  final binding = SseClientLifecycleBinding(ref.read(sseClientProvider));
  ref.onDispose(binding.dispose);
  return binding;
});
