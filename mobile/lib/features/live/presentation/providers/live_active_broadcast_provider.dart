import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Aktif canlı yayın odası (`LiveBroadcastRoomPage`) — aynı `streamId` için
/// ikinci oda/TRTC oturumu açılmasını engellemek için.
final liveActiveBroadcastStreamIdProvider = StateProvider<String?>((ref) => null);

bool isLiveBroadcastRoomActiveForStream(Ref ref, String streamId) {
  final active = ref.read(liveActiveBroadcastStreamIdProvider)?.trim() ?? '';
  final sid = streamId.trim();
  return active.isNotEmpty && sid.isNotEmpty && active == sid;
}
