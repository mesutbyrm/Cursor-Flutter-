import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}
