import '../../../../core/auth/voice_staff_rank.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/entities/chat_room_presence.dart';

/// 11 koltuk: 1 = oda sahibi, 2–11 misafir (web: 10’lu ızgara + sol admin).
class VoiceRoomSeatLayout {
  VoiceRoomSeatLayout({
    required this.room,
    required this.presence,
  });

  final VoiceRoomEntity room;
  final List<ChatRoomPresence> presence;

  static const seatCount = 11;

  /// Koltuk numarası → kullanıcı; boş koltuklar map’te yok.
  Map<int, ChatRoomPresence> build() {
    final ownerId = room.ownerId;
    final bySeat = <int, ChatRoomPresence>{};
    final withoutSeat = <ChatRoomPresence>[];

    for (final u in presence) {
      final idx = u.seatIndex;
      if (idx != null && idx >= 1 && idx <= seatCount) {
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

    // Koltuk 1: oda sahibi veya (sahip yoksa) en yetkili kullanıcı.
    var hostUser = ownerUser ?? _highestAuthority(presence, ownerId: ownerId);
    if (hostUser != null) {
      final displaced = bySeat[1];
      if (displaced != null && displaced.id != hostUser.id) {
        withoutSeat.add(displaced);
      }
      bySeat[1] = hostUser;
      withoutSeat.remove(hostUser);
    } else {
      final onOne = bySeat[1];
      if (onOne != null) {
        withoutSeat.add(onOne);
      }
      bySeat.remove(1);
    }

    // Host 1 dışındaki koltuktaysa oradan çıkar (tekrar atanacak).
    if (hostUser != null) {
      for (final entry in bySeat.entries.toList()) {
        if (entry.key != 1 && entry.value.id == hostUser.id) {
          withoutSeat.add(entry.value);
          bySeat.remove(entry.key);
        }
      }
    }

    // Kalan kullanıcıları 2–11’e doldur (sahip hariç).
    var next = 2;
    void place(ChatRoomPresence u) {
      if (hostUser != null && u.id == hostUser.id) return;
      if (ownerId != null && u.id == ownerId) return;
      while (next <= seatCount && bySeat.containsKey(next)) {
        next++;
      }
      if (next <= seatCount) {
        bySeat[next] = u;
        next++;
      }
    }

    for (final u in withoutSeat) {
      place(u);
    }

    return bySeat;
  }

  static ChatRoomPresence? _highestAuthority(
    List<ChatRoomPresence> presence, {
    String? ownerId,
  }) {
    ChatRoomPresence? best;
    var bestPower = -1;
    for (final u in presence) {
      if (ownerId != null && u.id == ownerId) continue;
      final rank = VoiceStaffRankParser.resolve(
        username: u.nickname ?? u.name,
        chatRole: u.chatRole,
      );
      var power = VoiceStaffRankParser.powerLevel(rank);
      if (u.chatRole == 'owner' || u.chatRole == 'founder') {
        power = 120;
      }
      if (power > bestPower) {
        bestPower = power;
        best = u;
      }
    }
    if (bestPower <= 0) return null;
    return best;
  }
}
