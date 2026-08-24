import '../../../auth/domain/entities/user_entity.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/entities/chat_room_presence.dart';
import 'voice_room_permissions.dart';

/// Koltuk / admin kuralları — koltukta olmayan konuşamaz; gerçek admin her yerden konuşur.
abstract final class VoiceRoomSpeakAccess {
  /// Site admin, oda sahibi veya moderasyon — koltuksuz konuşabilir.
  static bool canSpeakOffSeat(VoiceRoomPermissions perms) {
    return perms.isSiteAdmin || perms.isRoomOwner || perms.canModerate;
  }

  static ChatRoomPresence? selfPresence(
    String? userId,
    List<ChatRoomPresence> presence,
  ) {
    if (userId == null || userId.isEmpty) return null;
    for (final p in presence) {
      if (p.id == userId) return p;
    }
    return null;
  }

  /// Backend `seatIndex` — UI layout doldurması sayılmaz.
  static bool hasBackendSeat({
    required String userId,
    required List<ChatRoomPresence> presence,
  }) {
    final self = selfPresence(userId, presence);
    final idx = self?.seatIndex;
    return idx != null && idx >= 1;
  }

  static Set<String> backendSeatedUserIds(List<ChatRoomPresence> presence) {
    return {
      for (final p in presence)
        if (p.seatIndex != null && p.seatIndex! >= 1) p.id,
    };
  }

  static bool canSpeak({
    required UserEntity? user,
    required VoiceRoomPermissions perms,
    required VoiceRoomEntity room,
    required List<ChatRoomPresence> presence,
  }) {
    if (user == null) return false;
    final self = selfPresence(user.id, presence);
    if (self?.isMuted == true) return false;

    if (canSpeakOffSeat(perms)) return true;
    return hasBackendSeat(userId: user.id, presence: presence);
  }

  static bool isSelfOnStage({
    required UserEntity? user,
    required VoiceRoomEntity room,
    required List<ChatRoomPresence> presence,
    VoiceRoomPermissions? perms,
  }) {
    if (user == null) return false;
    if (perms != null && canSpeakOffSeat(perms)) return true;
    return hasBackendSeat(userId: user.id, presence: presence);
  }
}
