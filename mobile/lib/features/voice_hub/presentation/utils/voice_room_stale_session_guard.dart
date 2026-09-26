import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/presentation/providers/voice_rooms_list_notifier.dart';
import '../providers/chat_room_providers.dart';
import '../providers/voice_room_session_registry.dart';
import '../providers/voice_rooms_presence_provider.dart';
import 'voice_room_presence_persistence.dart';

/// Oturum açılışında sunucuda kalmış presence kayıtlarını temizle
/// (backend: `DELETE .../presence`, ardından `POST {action: leave}`).
///
/// Kayıt yalnızca çıkış sunucu tarafından kabul edildiğinde silinir. Aksi
/// halde (ağ yok, token henüz hazır değil, 5xx) kayıt korunur ve bir sonraki
/// açılışta yeniden denenir — yoksa kullanıcı hiç girmediği odada görünmeye
/// devam eder.
///
/// Çıkış kabul edilirse keşfet listesi tazelenir; aksi halde ana sayfadaki
/// oda kartı temizlenmiş kaydın eski sayısını göstermeye devam ediyordu.
Future<void> clearStaleVoicePresenceOnAuth(Ref ref) async {
  final pending = await VoiceRoomPresencePersistence.readPendingAll();
  if (pending.isEmpty) return;

  final active = ref.read(voiceRoomActiveLiveKeyProvider)?.trim();
  final currentUserId = ref.read(authControllerProvider).valueOrNull?.id.trim();

  var clearedAny = false;
  for (final record in pending) {
    // Kullanıcı şu anda gerçekten bu odadaysa dokunma.
    if (active != null && active.isNotEmpty && active == record.roomId) {
      continue;
    }

    // Kayıt başka bir hesaba aitse bu oturumdan temizlenemez; yanlış kullanıcı
    // adına leave göndermek yerine kaydı düşür.
    final recordedUserId = record.userId;
    if (recordedUserId != null &&
        currentUserId != null &&
        currentUserId.isNotEmpty &&
        recordedUserId != currentUserId) {
      await VoiceRoomPresencePersistence.clearRoom(record.roomId);
      continue;
    }

    var cleared = false;
    // Ağ yeni açılmış olabilir; kısa aralıkla iki deneme.
    for (var attempt = 0; attempt < 2 && !cleared; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      try {
        cleared = await ref.read(chatRoomRemoteProvider).leavePresence(
              record.roomId,
              alternateKey: record.alternate,
            );
      } catch (_) {
        cleared = false;
      }
    }
    if (!cleared) continue;

    await VoiceRoomPresencePersistence.clearRoom(record.roomId);
    clearedAny = true;
    ref.read(voiceRoomsPresenceProvider.notifier).patchRoomCount(
          record.roomId,
          0,
        );
  }

  if (clearedAny) {
    await ref.read(voiceRoomsListNotifierProvider.notifier).refresh();
  }
}
