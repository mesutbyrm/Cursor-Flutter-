import 'package:flutter/material.dart';

import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../domain/entities/chat_room_presence.dart';
import '../../utils/voice_room_seat_layout.dart';
import 'voice_mic_seat.dart';

/// canlifal.com: 2×5 (10) mikrofon koltuğu — 1. koltuk Admin.
class VoiceWebOwnerStage extends StatelessWidget {
  const VoiceWebOwnerStage({
    super.key,
    required this.room,
    required this.presence,
    this.speakingUserId,
    this.onUserTap,
    this.onSeatTap,
  });

  final VoiceRoomEntity room;
  final List<ChatRoomPresence> presence;
  final String? speakingUserId;
  final void Function(ChatRoomPresence user)? onUserTap;
  /// [internalSeatIndex] 2–11; [user] dolu koltukta dolu kullanıcı.
  final void Function(int internalSeatIndex, ChatRoomPresence? user)? onSeatTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final gap = 6.0;
        final panelReserve = 36.0;
        final row1W = w - panelReserve;
        final cell = ((row1W - gap * 3) / 4).clamp(40.0, 56.0);
        final rowH = cell + 20;
        final gridH = rowH * 2 + gap;

        final seats = VoiceRoomSeatLayout(room: room, presence: presence).build();
        _ensureOwnerOnSeatOne(seats);

        return SizedBox(
          height: gridH.clamp(112.0, 176.0),
          child: Padding(
            padding: const EdgeInsets.only(left: 8, right: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _seatRow(
                        seats: seats,
                        displayNums: const [1, 2, 3, 4],
                        internalNums: const [1, 2, 3, 4],
                        size: cell,
                        gap: gap,
                        hostSeat: 1,
                      ),
                    ),
                    SizedBox(width: panelReserve - 8),
                  ],
                ),
                SizedBox(height: gap),
                _seatRow(
                  seats: seats,
                  displayNums: const [6, 7, 8, 9, 10],
                  internalNums: const [6, 7, 8, 9, 10],
                  size: cell,
                  gap: gap,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _ensureOwnerOnSeatOne(Map<int, ChatRoomPresence> seats) {
    if (seats.containsKey(1)) return;
    final ownerId = room.ownerId;
    ChatRoomPresence? ownerUser;
    if (ownerId != null) {
      for (final p in presence) {
        if (p.id == ownerId) {
          ownerUser = p;
          break;
        }
      }
    }
    ownerUser ??= ChatRoomPresence(
      id: ownerId ?? 'owner',
      name: room.ownerName ?? 'Admin',
      image: room.ownerAvatarUrl,
      chatRole: 'owner',
      seatIndex: 1,
    );
    seats[1] = ownerUser;
  }

  Widget _seatRow({
    required Map<int, ChatRoomPresence> seats,
    required List<int> displayNums,
    required List<int> internalNums,
    required double size,
    required double gap,
    int? hostSeat,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(displayNums.length, (col) {
        final internal = internalNums[col];
        final displayNum = displayNums[col];
        final user = seats[internal];
        return VoiceMicSeat(
          user: user,
          seatIndex: displayNum,
          size: size,
          isHost: hostSeat != null && displayNum == hostSeat,
          room: room,
          djUserIds: room.djUserIds,
          speaking: speakingUserId == user?.id || user?.isSpeaking == true,
          onTap: () => onSeatTap?.call(internal, user),
        );
      }),
    );
  }
}

Set<String> voiceWebOnStageIds({
  required VoiceRoomEntity room,
  required List<ChatRoomPresence> presence,
}) {
  final seats = VoiceRoomSeatLayout(room: room, presence: presence).build();
  return seats.values.map((p) => p.id).toSet();
}

List<ChatRoomPresence> voiceWebAudienceOffStage({
  required VoiceRoomEntity room,
  required List<ChatRoomPresence> presence,
}) {
  final onIds = voiceWebOnStageIds(room: room, presence: presence);
  return presence.where((p) => !onIds.contains(p.id)).toList();
}
