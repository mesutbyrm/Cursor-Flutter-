import '../../../auth/domain/entities/user_entity.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../widgets/premium_2026/voice_web_owner_stage.dart';
import 'voice_room_permissions.dart';

/// Koltuk / admin kuralları — koltukta olmayan konuşamaz; admin her yerden konuşur.
abstract final class VoiceRoomSpeakAccess {
  static bool canSpeak({
    required UserEntity? user,
    required VoiceRoomPermissions perms,
    required VoiceRoomEntity room,
    required List<ChatRoomPresence> presence,
  }) {
    if (user == null) return false;
    final onStage = voiceWebOnStageIds(room: room, presence: presence);
    return onStage.contains(user.id);
  }

  static bool isSelfOnStage({
    required UserEntity? user,
    required VoiceRoomEntity room,
    required List<ChatRoomPresence> presence,
  }) {
    if (user == null) return false;
    return voiceWebOnStageIds(room: room, presence: presence).contains(user.id);
  }
}
