import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/chat_room_providers.dart';
import '../providers/pk_battle_remote_provider.dart';
import '../providers/voice_gift_providers.dart';
import '../providers/voice_recent_gifts_provider.dart';

/// Oda değiştirmeden önce aktif oturumu güvenle kapat.
Future<void> teardownVoiceRoomBeforeSwitch(
  WidgetRef ref, {
  required String liveKey,
  String source = 'room_switch',
}) async {
  if (liveKey.trim().isEmpty) return;
  ref.read(pkBattleRemoteProvider.notifier).clear();
  ref.read(voiceRoomGiftRealtimeProvider).stop();
  ref.read(voiceRecentGiftsProvider.notifier).clear();
  try {
    await ref
        .read(voiceRoomLiveProvider(liveKey).notifier)
        .leaveRoomSession(source: source);
  } catch (_) {}
}
