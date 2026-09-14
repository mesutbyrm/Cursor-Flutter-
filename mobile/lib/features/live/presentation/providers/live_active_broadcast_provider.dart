import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Aktif canlı yayın odası (`LiveBroadcastRoomPage`) — aynı `streamId` için
/// ikinci oda/TRTC oturumu açılmasını engellemek için.
final liveActiveBroadcastStreamIdProvider = StateProvider<String?>((ref) => null);

bool isLiveBroadcastRoomActiveForStreamId(
  String? activeStreamId,
  String streamId,
) {
  final active = activeStreamId?.trim() ?? '';
  final sid = streamId.trim();
  return active.isNotEmpty && sid.isNotEmpty && active == sid;
}

bool isLiveBroadcastRoomActiveForStream(WidgetRef ref, String streamId) {
  return isLiveBroadcastRoomActiveForStreamId(
    ref.read(liveActiveBroadcastStreamIdProvider),
    streamId,
  );
}
