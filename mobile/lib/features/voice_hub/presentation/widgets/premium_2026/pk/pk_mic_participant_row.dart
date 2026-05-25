import 'package:flutter/material.dart';

import '../../../../domain/entities/chat_room_presence.dart';
import '../../../theme/voice_room_tokens.dart';
import '../voice_mic_seat.dart';

/// PK altı — sesli katılımcı şeridi (referans: 5 mikrofon).
class PkMicParticipantRow extends StatelessWidget {
  const PkMicParticipantRow({
    super.key,
    required this.presence,
    this.maxSeats = 5,
  });

  final List<ChatRoomPresence> presence;
  final int maxSeats;

  @override
  Widget build(BuildContext context) {
    final seats = presence.take(maxSeats).toList();
    while (seats.length < maxSeats) {
      seats.add(
        ChatRoomPresence(
          id: 'empty-${seats.length}',
          name: '',
          image: null,
        ),
      );
    }

    return SizedBox(
      height: 88,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var i = 0; i < maxSeats; i++)
            Expanded(
              child: Center(
                child: seats[i].displayName.isEmpty
                    ? _EmptyMicSeat(index: i + 1)
                    : VoiceMicSeat(
                        user: seats[i],
                        seatIndex: i + 1,
                        size: 52,
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyMicSeat extends StatelessWidget {
  const _EmptyMicSeat({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.35),
              width: 2,
            ),
            color: Colors.white.withValues(alpha: 0.04),
          ),
          child: Icon(
            Icons.mic_none_rounded,
            color: Colors.white.withValues(alpha: 0.35),
            size: 22,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$index',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}
