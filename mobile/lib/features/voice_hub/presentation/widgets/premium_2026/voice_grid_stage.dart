import 'package:flutter/material.dart';

import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../domain/entities/chat_room_presence.dart';
import '../../utils/voice_room_seat_layout.dart';
import 'voice_mic_seat.dart';

/// 8 mikrofon: üstte 4, altta 4 (responsive ızgara).
class VoiceGridStage extends StatelessWidget {
  const VoiceGridStage({
    super.key,
    required this.room,
    required this.presence,
    this.speakingUserId,
    this.onUserTap,
    this.onEmptySeatTap,
    this.maxSeats = 8,
  });

  final VoiceRoomEntity room;
  final List<ChatRoomPresence> presence;
  final String? speakingUserId;
  final void Function(ChatRoomPresence user)? onUserTap;
  final VoidCallback? onEmptySeatTap;
  final int maxSeats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final h = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height * 0.42;
        final pad = 12.0;
        final gap = 8.0;
        final cellW = (w - pad * 2 - gap * 3) / 4;
        final seatSize = cellW.clamp(48.0, 72.0);
        final rowH = seatSize + 28;
        final totalH = rowH * 2 + gap + pad;

        final seats = VoiceRoomSeatLayout(room: room, presence: presence).build();
        final ordered = _orderedForGrid(seats);

        return SizedBox(
          width: w,
          height: totalH.clamp(120.0, h),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _seatRow(
                  ordered: ordered,
                  startSeat: 1,
                  seatSize: seatSize,
                  gap: gap,
                ),
                SizedBox(height: gap),
                _seatRow(
                  ordered: ordered,
                  startSeat: 5,
                  seatSize: seatSize,
                  gap: gap,
                  lockFromSeat: 7,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<ChatRoomPresence?> _orderedForGrid(Map<int, ChatRoomPresence> seats) {
    final list = <ChatRoomPresence?>[];
    for (var i = 1; i <= maxSeats; i++) {
      list.add(seats[i]);
    }
    while (list.length < maxSeats) {
      list.add(null);
    }
    return list;
  }

  Widget _seatRow({
    required List<ChatRoomPresence?> ordered,
    required int startSeat,
    required double seatSize,
    required double gap,
    int lockFromSeat = 99,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(4, (col) {
        final seatIndex = startSeat + col;
        final idx = seatIndex - 1;
        final user = idx < ordered.length ? ordered[idx] : null;
        return VoiceMicSeat(
          user: user,
          seatIndex: seatIndex,
          size: seatSize,
          isHost: seatIndex == 1,
          speaking: speakingUserId == user?.id || user?.isSpeaking == true,
          locked: user == null && seatIndex >= lockFromSeat,
          onTap: user != null
              ? () => onUserTap?.call(user)
              : onEmptySeatTap,
        );
      }),
    );
  }
}

/// Sahnedeki 8 koltukta olmayan dinleyiciler.
List<ChatRoomPresence> voiceAudienceOffStage({
  required List<ChatRoomPresence> presence,
  required VoiceRoomEntity room,
  int maxSeats = 8,
}) {
  final onStage =
      VoiceRoomSeatLayout(room: room, presence: presence).build().values;
  final onIds = onStage.map((p) => p.id).toSet();
  return presence.where((p) => !onIds.contains(p.id)).toList();
}
