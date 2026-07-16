import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_provider.dart';
import '../core/sse_client_provider.dart';
import 'chat_service.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(
    resolveAuthedDio: () => ref.read(dioProvider),
    sseClient: ref.watch(sseClientProvider),
  );
});
