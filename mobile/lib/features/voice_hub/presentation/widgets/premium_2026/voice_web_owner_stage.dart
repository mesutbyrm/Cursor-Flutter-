import 'package:flutter/material.dart';

import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../domain/entities/chat_room_presence.dart';
import '../../utils/voice_room_seat_layout.dart';
import 'voice_mic_seat.dart';

/// canlifal.com: sol Admin (koltuk 1) + sağda 2×5 (koltuk 2–11).
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
  final void Function(int internalSeatIndex, ChatRoomPresence? user)? onSeatTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        const gap = 6.0;
        const hPad = 8.0;
        final innerW = w - hPad * 2;
        final hostSize = (innerW * 0.17).clamp(52.0, 72.0);
        final gridW = innerW - hostSize - gap;
        final cell = ((gridW - gap * 4) / 5).clamp(34.0, 50.0);
        final rowH = cell + 20;
        final gridH = rowH * 2 + gap;
        final totalH = gridH.clamp(112.0, 176.0);

        final seats = VoiceRoomSeatLayout(room: room, presence: presence).build();
        _ensureOwnerOnSeatOne(seats);
        final host = seats[1];

        return SizedBox(
          height: totalH,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: hPad),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                VoiceMicSeat(
                  user: host,
                  seatIndex: 1,
                  size: hostSize,
                  isHost: true,
                  room: room,
                  djUserIds: room.djUserIds,
                  speaking:
                      speakingUserId == host?.id || host?.isSpeaking == true,
                  onTap: () => onSeatTap?.call(1, host),
                ),
                const SizedBox(width: gap),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _seatRow(
                        seats: seats,
                        displayNums: const [2, 3, 4, 5, 6],
                        internalNums: const [2, 3, 4, 5, 6],
                        size: cell,
                        gap: gap,
                      ),
                      const SizedBox(height: gap),
                      _seatRow(
                        seats: seats,
                        displayNums: const [7, 8, 9, 10, 11],
                        internalNums: const [7, 8, 9, 10, 11],
                        size: cell,
                        gap: gap,
                      ),
                    ],
                  ),
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
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(displayNums.length, (col) {
        final internal = internalNums[col];
        final displayNum = displayNums[col];
        final user = seats[internal];
        return VoiceMicSeat(
          user: user,
          seatIndex: displayNum,
          size: size,
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
