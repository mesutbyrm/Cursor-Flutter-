import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/entities/chat_room_presence.dart';

/// 15 koltuk: 0–14 (üretim); 1 = oda sahibi gösterimi.
class VoiceRoomSeatLayout {
  VoiceRoomSeatLayout({
    required this.room,
    required this.presence,
  });

  final VoiceRoomEntity room;
  final List<ChatRoomPresence> presence;

  static const seatCount = 15;

  Map<int, ChatRoomPresence> build() {
    final ownerId = room.ownerId;
    final bySeat = <int, ChatRoomPresence>{};
    final withoutSeat = <ChatRoomPresence>[];

    for (final u in presence) {
      final idx = u.seatIndex;
      if (idx != null && idx >= 0 && idx <= seatCount - 1) {
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
      for (final entry in bySeat.entries.toList()) {
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

    // Kalan kullanıcıları 0–14 arası boş koltuklara doldur (sahip hariç).
    var next = 0;
    void place(ChatRoomPresence u) {
      if (hostUser != null && u.id == hostUser.id) return;
      if (ownerId != null && u.id == ownerId) return;
      while (next <= seatCount - 1 && bySeat.containsKey(next)) {
        next++;
      }
      if (next <= seatCount - 1) {
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
