import '../../../auth/domain/entities/user_entity.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/entities/chat_room_my_permissions.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../providers/voice_room_live_side_effect_slices.dart';
import '../providers/chat_room_providers.dart';
import 'voice_room_permissions.dart';
import 'voice_room_speak_access.dart';

/// Mic gate slice — self kullanıcı konuşma yetkisi değişimini izler.
VoiceRoomMicGateSlice buildVoiceRoomMicGateSlice({
  required UserEntity? user,
  required VoiceRoomEntity room,
  required List<ChatRoomPresence> presence,
  required ChatRoomMyPermissions? serverPermissions,
  required bool staffSiteAdmin,
  required String? walletRole,
}) {
  if (user == null) {
    return (selfUserId: null, selfCanSpeak: false);
  }
  ChatRoomPresence? selfPresence;
  for (final p in presence) {
    if (p.id == user.id) {
      selfPresence = p;
      break;
    }
  }
  final perms = VoiceRoomPermissions.forUser(
    user: user,
    room: room,
    selfPresence: selfPresence,
    server: serverPermissions,
    staffSiteAdmin: staffSiteAdmin,
    walletRole: walletRole,
  );
  final canSpeak = VoiceRoomSpeakAccess.canSpeak(
    user: user,
    perms: perms,
    room: room,
    presence: presence,
  );
  return (selfUserId: user.id, selfCanSpeak: canSpeak);
}
