import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/chat_room_providers.dart';
import '../providers/voice_room_session_registry.dart';
import 'voice_room_presence_persistence.dart';

/// Oturum açılışında sunucuda kalmış presence kaydını temizle (backend: DELETE/POST leave).
///
/// Kayıt yalnızca çıkış sunucu tarafından kabul edildiğinde silinir. Aksi halde
/// (ağ yok, token henüz hazır değil, 5xx) kayıt korunur ve bir sonraki açılışta
/// yeniden denenir — yoksa kullanıcı hiç girmediği odada görünmeye devam eder.
Future<void> clearStaleVoicePresenceOnAuth(Ref ref) async {
  final pending = await VoiceRoomPresencePersistence.readPending();
  if (pending == null) return;

  final active = ref.read(voiceRoomActiveLiveKeyProvider)?.trim();
  if (active != null && active.isNotEmpty && active == pending.roomId) {
    return;
  }

  // Kayıt başka bir hesaba aitse bu oturumdan temizlenemez; yanlış kullanıcı
  // adına leave göndermek yerine kaydı düşür.
  final currentUserId = ref.read(authControllerProvider).valueOrNull?.id.trim();
  final recordedUserId = pending.userId;
  if (recordedUserId != null &&
      currentUserId != null &&
      currentUserId.isNotEmpty &&
      recordedUserId != currentUserId) {
    await VoiceRoomPresencePersistence.clear();
    return;
  }

  var cleared = false;
  try {
    cleared = await ref.read(chatRoomRemoteProvider).leavePresence(
          pending.roomId,
          alternateKey: pending.alternate,
        );
  } catch (_) {
    cleared = false;
  }
  if (!cleared) return;

  await VoiceRoomPresencePersistence.clear();
}
