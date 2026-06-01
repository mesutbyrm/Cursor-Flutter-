import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

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
        final ownerSize = (w * 0.18).clamp(68.0, 88.0);
        final gridW = w - ownerSize - 16;
        final gap = 4.0;
        final cell = ((gridW - gap * 4) / 5).clamp(36.0, 52.0);
        final rowH = cell + 18;
        final gridH = rowH * 2 + gap;

        final seats = VoiceRoomSeatLayout(room: room, presence: presence).build();
        final owner = _resolveOwner(seats);

        return SizedBox(
          height: gridH.clamp(108.0, 168.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
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
                        color: AppThemeColors.coinGold.withValues(alpha: 0.95),
                      ),
                    ),
                    Text(
                      'Oda Sahibi',
                      style: TextStyle(
                        fontSize: 8,
                        color: context.colors.onSurfaceMuted.withValues(alpha: 0.85),
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
