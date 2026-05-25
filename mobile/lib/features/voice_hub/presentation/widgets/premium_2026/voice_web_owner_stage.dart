import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../domain/entities/chat_room_presence.dart';
import '../../utils/voice_room_seat_layout.dart';
import 'voice_mic_seat.dart';

/// Web düzeni: solda büyük oda sahibi, sağda 4+4 mikrofon ızgarası.
class VoiceWebOwnerStage extends StatelessWidget {
  const VoiceWebOwnerStage({
    super.key,
    required this.room,
    required this.presence,
    this.speakingUserId,
    this.onUserTap,
    this.onEmptySeatTap,
  });

  final VoiceRoomEntity room;
  final List<ChatRoomPresence> presence;
  final String? speakingUserId;
  final void Function(ChatRoomPresence user)? onUserTap;
  final VoidCallback? onEmptySeatTap;

  static const _guestSeatStart = 2;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final ownerSize = (w * 0.22).clamp(72.0, 96.0);
        final gridW = w - ownerSize - 28;
        final gap = 6.0;
        final cell = ((gridW - gap * 3) / 4).clamp(44.0, 64.0);
        final rowH = cell + 26;
        final gridH = rowH * 2 + gap;

        final seats = VoiceRoomSeatLayout(room: room, presence: presence).build();
        final owner = _resolveOwner(seats);

        return SizedBox(
          height: gridH.clamp(130.0, 200.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VoiceMicSeat(
                      user: owner,
                      seatIndex: 0,
                      size: ownerSize,
                      isHost: true,
                      speaking: speakingUserId == owner?.id ||
                          owner?.isSpeaking == true,
                      onTap: owner != null ? () => onUserTap?.call(owner) : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      owner != null ? 'Oda Sahibi' : 'Admin',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.coinGold.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _guestRow(
                        seats: seats,
                        displayStart: 1,
                        seatStart: _guestSeatStart,
                        size: cell,
                      ),
                      SizedBox(height: gap),
                      _guestRow(
                        seats: seats,
                        displayStart: 5,
                        seatStart: _guestSeatStart + 4,
                        size: cell,
                        lockFromDisplay: 7,
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

  ChatRoomPresence? _resolveOwner(Map<int, ChatRoomPresence> seats) {
    final fromSeat = seats[1];
    if (fromSeat != null) return fromSeat;
    final ownerId = room.ownerId;
    if (ownerId != null) {
      for (final p in presence) {
        if (p.id == ownerId) return p;
      }
    }
    if (room.ownerName != null) {
      return ChatRoomPresence(
        id: ownerId ?? 'owner',
        name: room.ownerName!,
        image: room.ownerAvatarUrl,
        chatRole: 'owner',
        seatIndex: 1,
      );
    }
    return null;
  }

  Widget _guestRow({
    required Map<int, ChatRoomPresence> seats,
    required int displayStart,
    required int seatStart,
    required double size,
    int lockFromDisplay = 99,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(4, (col) {
        final seatIndex = seatStart + col;
        final displayNum = displayStart + col;
        final user = seats[seatIndex];
        return VoiceMicSeat(
          user: user,
          seatIndex: displayNum,
          size: size,
          speaking: speakingUserId == user?.id || user?.isSpeaking == true,
          locked: user == null && displayNum >= lockFromDisplay,
          onTap: user != null
              ? () => onUserTap?.call(user)
              : onEmptySeatTap,
        );
      }),
    );
  }
}

/// Web sahnesindeki 8 misafir koltuğu + sahip.
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
