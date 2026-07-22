import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../gifts/presentation/sync/gift_session_controller.dart';
import '../../../live/presentation/gifts/providers/live_seat_gift_totals_provider.dart';
import 'voice_recent_gifts_provider.dart';
import 'voice_seat_gift_totals_provider.dart';

/// Aktif sesli oda oturumu — oda değişiminde eski bağlantıları kapatmak için.
final voiceRoomActiveLiveKeyProvider = StateProvider<String?>((ref) => null);

void registerVoiceRoomLiveSession(Ref ref, String liveKey) {
  final key = liveKey.trim();
  if (key.isEmpty) return;
  ref.read(voiceRoomActiveLiveKeyProvider.notifier).state = key;
}

void clearVoiceRoomLiveSession(Ref ref, String liveKey) {
  final key = liveKey.trim();
  final active = ref.read(voiceRoomActiveLiveKeyProvider);
  if (active == key) {
    ref.read(voiceRoomActiveLiveKeyProvider.notifier).state = null;
  }
  if (key.isEmpty) return;
  ref.read(voiceSeatGiftTotalsProvider.notifier).clear();
  ref.read(voiceRecentGiftsProvider.notifier).clear();
  ref.invalidate(giftSessionProvider(key));
}

/// Canlı yayın oturumu hediye state temizliği.
void clearLiveGiftSession(Ref ref, String streamId) {
  final key = streamId.trim();
  if (key.isEmpty) return;
  ref.read(liveSeatGiftTotalsProvider.notifier).clear();
  ref.read(voiceRecentGiftsProvider.notifier).clear();
  ref.invalidate(giftSessionProvider(key));
}
