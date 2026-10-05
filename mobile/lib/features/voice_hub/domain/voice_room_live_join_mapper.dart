import '../../trtc/domain/entities/live_join_room_result.dart';
import 'entities/chat_room_presence.dart';
import 'entities/voice_room_seat_slot.dart';

/// `POST /api/live/join-room` yanıtını sesli oda state modellerine çevirir.
abstract final class VoiceRoomLiveJoinMapper {
  static List<ChatRoomPresence> participantsToPresence(
    List<LiveJoinParticipant> participants,
  ) {
    return participants
        .where((p) => p.userId.isNotEmpty)
        .map(
          (p) => ChatRoomPresence(
            id: p.userId,
            name: p.userName?.trim().isNotEmpty == true
                ? p.userName!.trim()
                : 'Kullanıcı',
            image: p.userImage,
            seatIndex: p.seatIndex,
          ),
        )
        .toList(growable: false);
  }

  static List<VoiceRoomSeatSlot> seatsToSlots(List<LiveJoinSeat> seats) {
    return seats
        .map(
          (s) => VoiceRoomSeatSlot(
            index: s.seatIndex,
            userId: s.userId,
            name: s.userName,
            image: s.userImage,
            micOn: s.isMicOn,
          ),
        )
        .toList(growable: false);
  }
}
