import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_provider.dart';
import '../core/sse_client_provider.dart';
import 'stream_service.dart';

final streamServiceProvider = Provider<StreamService>((ref) {
  return StreamService(
    resolveAuthedDio: () => ref.read(dioProvider),
    sseClient: ref.watch(sseClientProvider),
  );
});
