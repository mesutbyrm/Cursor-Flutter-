import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../domain/entities/chat_room_presence.dart';
import '../../utils/voice_room_seat_layout.dart';
import 'voice_mic_seat.dart';

/// Web referans: solda büyük Admin, sağda 2×5 (10) mikrofon koltuğu.
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final ownerSize = (w * 0.2).clamp(76.0, 100.0);
        final gridW = w - ownerSize - 24;
        final gap = 5.0;
        final cell = ((gridW - gap * 4) / 5).clamp(40.0, 58.0);
        final rowH = cell + 22;
        final gridH = rowH * 2 + gap;

        final seats = VoiceRoomSeatLayout(room: room, presence: presence).build();
        final owner = _resolveOwner(seats);

        return SizedBox(
          height: gridH.clamp(140.0, 210.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
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
                      owner?.displayName ?? 'Admin',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.coinGold.withValues(alpha: 0.95),
                      ),
                    ),
                    Text(
                      'Oda Sahibi',
                      style: TextStyle(
                        fontSize: 8,
                        color: AppColors.textMuted.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _seatRow(
                        seats: seats,
                        displayStart: 1,
                        internalStart: 2,
                        size: cell,
                        gap: gap,
                      ),
                      SizedBox(height: gap),
                      _seatRow(
                        seats: seats,
                        displayStart: 6,
                        internalStart: 7,
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

  ChatRoomPresence? _resolveOwner(Map<int, ChatRoomPresence> seats) {
    final fromSeat = seats[1];
    if (fromSeat != null) return fromSeat;
    final ownerId = room.ownerId;
    if (ownerId != null) {
      for (final p in presence) {
        if (p.id == ownerId) return p;
      }
    }
    if (room.ownerName != null || room.ownerAvatarUrl != null) {
      return ChatRoomPresence(
        id: ownerId ?? 'owner',
        name: room.ownerName ?? 'Admin',
        image: room.ownerAvatarUrl,
        chatRole: 'owner',
        seatIndex: 1,
      );
    }
    return null;
  }

  Widget _seatRow({
    required Map<int, ChatRoomPresence> seats,
    required int displayStart,
    required int internalStart,
    required double size,
    required double gap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (col) {
        final internal = internalStart + col;
        final displayNum = displayStart + col;
        final user = seats[internal];
        return VoiceMicSeat(
          user: user,
          seatIndex: displayNum,
          size: size,
          speaking: speakingUserId == user?.id || user?.isSpeaking == true,
          onTap: user != null
              ? () => onUserTap?.call(user)
              : onEmptySeatTap,
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
