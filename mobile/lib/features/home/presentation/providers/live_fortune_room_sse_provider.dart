import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/token_storage.dart';
import '../../data/services/live_fortune_room_sse_service.dart';

final liveFortuneRoomSseServiceProvider =
    Provider<LiveFortuneRoomSseService>((ref) {
  final service = LiveFortuneRoomSseService();
  ref.onDispose(service.disconnect);
  return service;
});

/// Oturumlu SSE bağlantısı için token okuyucu.
Future<String?> Function() liveFortuneSseTokenReader(WidgetRef ref) {
  final storage = ref.read(tokenStorageProvider);
  return storage.readAccess;
}
