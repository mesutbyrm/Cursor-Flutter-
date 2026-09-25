import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/chat_room_providers.dart';
import '../providers/voice_room_session_registry.dart';
import 'voice_room_presence_persistence.dart';

/// Oturum açılışında sunucuda kalmış presence kaydını temizle (backend: DELETE/POST leave).
Future<void> clearStaleVoicePresenceOnAuth(Ref ref) async {
  final pending = await VoiceRoomPresencePersistence.readPending();
  if (pending == null) return;

  final active = ref.read(voiceRoomActiveLiveKeyProvider)?.trim();
  if (active != null && active.isNotEmpty && active == pending.roomId) {
    return;
  }

  try {
    await ref.read(chatRoomRemoteProvider).leavePresence(
          pending.roomId,
          alternateKey: pending.alternate,
        );
  } catch (_) {}
  await VoiceRoomPresencePersistence.clear();
  if (active == pending.roomId) {
    ref.read(voiceRoomActiveLiveKeyProvider.notifier).state = null;
    ref.read(voiceRoomActiveKeyAliasesProvider.notifier).state = const {};
  }
}
