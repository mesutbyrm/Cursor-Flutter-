import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

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
        final cell = ((w - gap * 4) / 5).clamp(40.0, 56.0);
        final rowH = cell + 20;
        final gridH = rowH * 2 + gap;

        final seats = VoiceRoomSeatLayout(room: room, presence: presence).build();
        _ensureOwnerOnSeatOne(seats);

        return SizedBox(
          height: gridH.clamp(112.0, 176.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _seatRow(
                  seats: seats,
                  displayStart: 1,
                  internalStart: 1,
                  size: cell,
                  gap: gap,
                  hostSeat: 1,
                ),
                SizedBox(height: gap),
                _seatRow(
                  seats: seats,
                  displayStart: 6,
                  internalStart: 6,
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
    required int displayStart,
    required int internalStart,
    required double size,
    required double gap,
    int? hostSeat,
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
