import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../../domain/entities/voice_room_seat_slot.dart';
import 'voice_room_seat_capacity.dart';

/// Koltuk haritası: 1 = oda sahibi; 11 = admin (kapasite > 10 ise).
class VoiceRoomSeatLayout {
  VoiceRoomSeatLayout({
    required this.room,
    required this.presence,
    this.seatSlots = const [],
    int? seatCapacity,
  })  : maxSeatIndex = voiceRoomLayoutMaxSeatIndex(
          room: room,
          seatSlots: seatSlots,
          configuredSeatCount: seatCapacity ?? room.seatCount,
        ),
        adminSeatIndex = voiceRoomAdminSeatIndex(
          room: room,
          seatSlots: seatSlots,
          configuredSeatCount: seatCapacity ?? room.seatCount,
        );

  final VoiceRoomEntity room;
  final List<ChatRoomPresence> presence;
  final List<VoiceRoomSeatSlot> seatSlots;
  final int maxSeatIndex;
  final int? adminSeatIndex;

  Map<int, ChatRoomPresence> build() {
    final ownerId = room.ownerId;
    final bySeat = <int, ChatRoomPresence>{};
    final withoutSeat = <ChatRoomPresence>[];

    for (final u in presence) {
      final idx = u.seatIndex;
      if (idx != null && idx >= 0 && idx <= maxSeatIndex) {
        bySeat.putIfAbsent(idx, () => u);
      } else {
        withoutSeat.add(u);
      }
    }

    ChatRoomPresence? ownerUser;
    if (ownerId != null && ownerId.isNotEmpty) {
      for (final u in presence) {
        if (u.id == ownerId) {
          ownerUser = u;
          break;
        }
      }
    }

    // Koltuk 1: yalnızca odada bulunan oda sahibi; sahip yoksa boş kalır.
    final hostUser = ownerUser;
    if (hostUser != null) {
      final displaced = bySeat[1];
      if (displaced != null && displaced.id != hostUser.id) {
        withoutSeat.add(displaced);
      }
      bySeat[1] = hostUser;
      withoutSeat.remove(hostUser);
      for (final entry in Map.from(bySeat).entries) {
        if (entry.key != 1 && entry.value.id == hostUser.id) {
          withoutSeat.add(entry.value);
          bySeat.remove(entry.key);
        }
      }
    } else {
      final onOne = bySeat[1];
      if (onOne != null) {
        withoutSeat.add(onOne);
      }
      bySeat.remove(1);
    }

    // Kalan kullanıcıları boş koltuklara doldur (sahip hariç; admin ayrı).
    var next = 0;
    void place(ChatRoomPresence u) {
      if (hostUser != null && u.id == hostUser.id) return;
      if (ownerId != null && u.id == ownerId) return;
      while (next <= maxSeatIndex &&
          (bySeat.containsKey(next) ||
              (adminSeatIndex != null && next == adminSeatIndex))) {
        next++;
      }
      if (next <= maxSeatIndex) {
        bySeat[next] = u;
        next++;
      }
    }

    for (final u in withoutSeat) {
      place(u);
    }

    return bySeat;
  }
}
