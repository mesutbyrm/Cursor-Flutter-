import 'package:equatable/equatable.dart';

import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../../domain/entities/voice_room_seat_slot.dart';
import '../providers/chat_room_providers.dart';
import 'voice_room_seat_layout.dart';

/// Tek koltuk için minimal görünüm durumu — `ref.select` ile rebuild sınırı.
class VoiceSeatSnapshot extends Equatable {
  const VoiceSeatSnapshot({
    this.user,
    this.locked = false,
    this.micOpen,
  });

  final ChatRoomPresence? user;
  final bool locked;
  final bool? micOpen;

  static VoiceSeatSnapshot fromLive({
    required VoiceRoomEntity room,
    required VoiceRoomLiveState live,
    required int seatIndex,
  }) {
    final seats = VoiceRoomSeatLayout(
      room: room,
      presence: live.presence,
      seatSlots: live.seatSlots,
    ).build();
    final user = seats[seatIndex];
    VoiceRoomSeatSlot? slot;
    for (final s in live.seatSlots) {
      if (s.index == seatIndex) {
        slot = s;
        break;
      }
    }
    final locked = user == null && slot?.isLocked == true;
    final micOpen = user == null ? null : (slot?.micOn ?? user.micOpen);
    return VoiceSeatSnapshot(user: user, locked: locked, micOpen: micOpen);
  }

  bool isSpeaking({Set<String> extraSpeakingIds = const {}}) {
    if (user == null) return false;
    return user!.isSpeaking || extraSpeakingIds.contains(user!.id);
  }

  @override
  List<Object?> get props => [
        user?.id,
        user?.name,
        user?.nickname,
        user?.image,
        user?.isSpeaking,
        user?.micOn,
        user?.isMuted,
        user?.seatIndex,
        user?.membership,
        user?.chatRole,
        locked,
        micOpen,
      ];
}
