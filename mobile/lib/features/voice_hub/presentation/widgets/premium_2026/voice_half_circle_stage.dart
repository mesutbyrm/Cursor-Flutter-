import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../domain/entities/chat_room_presence.dart';
import '../../utils/voice_room_seat_layout.dart';
import 'voice_mic_seat.dart';

/// 8 mikrofon: merkez host + yarım daire koltuklar (referans: Gece Muhabbeti).
class VoiceHalfCircleStage extends StatelessWidget {
  const VoiceHalfCircleStage({
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
    final mq = MediaQuery.sizeOf(context);
    final width = mq.width - 24;
    final height = math.min(mq.height * 0.38, 320.0);

    final seats = VoiceRoomSeatLayout(room: room, presence: presence).build();
    final host = _resolveHost(seats);
    final others = _orderedSpeakers(seats, host);

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          ..._arcSeats(
            others: others,
            center: Offset(width / 2, height * 0.62),
            radius: width * 0.36,
            hostY: height * 0.62,
          ),
          Positioned(
            left: width / 2 - 52,
            top: height * 0.62 - 52,
            child: VoiceMicSeat(
              user: host,
              seatIndex: 1,
              size: 96,
              isHost: true,
              speaking: speakingUserId == host?.id || host?.isSpeaking == true,
              onTap: host != null ? () => onUserTap?.call(host) : null,
            ),
          ),
        ],
      ),
    );
  }

  ChatRoomPresence? _resolveHost(Map<int, ChatRoomPresence> seats) {
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

  List<ChatRoomPresence> _orderedSpeakers(
    Map<int, ChatRoomPresence> seats,
    ChatRoomPresence? host,
  ) {
    final list = <ChatRoomPresence>[];
    final hostId = host?.id;
    for (var i = 2; i <= maxSeats; i++) {
      final u = seats[i];
      if (u != null && u.id != hostId) list.add(u);
    }
    for (final p in presence) {
      if (p.id == hostId) continue;
      if (list.any((e) => e.id == p.id)) continue;
      list.add(p);
      if (list.length >= maxSeats - 1) break;
    }
    return list;
  }

  List<Widget> _arcSeats({
    required List<ChatRoomPresence> others,
    required Offset center,
    required double radius,
    required double hostY,
  }) {
    final slots = maxSeats - 1;
    final widgets = <Widget>[];
    for (var i = 0; i < slots; i++) {
      final t = slots == 1 ? 0.5 : i / (slots - 1);
      final angle = math.pi * 1.05 + t * math.pi * 0.9;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle) * 0.55 - 20;
      final user = i < others.length ? others[i] : null;
      final size = i < 2 ? 64.0 : (i < 4 ? 56.0 : 48.0);
      widgets.add(
        Positioned(
          left: x - size / 2,
          top: y - size / 2,
          child: VoiceMicSeat(
            user: user,
            seatIndex: i + 2,
            size: size,
            speaking: speakingUserId == user?.id || user?.isSpeaking == true,
            locked: user == null && i >= 6,
            onTap: user != null
                ? () => onUserTap?.call(user)
                : onEmptySeatTap,
          ),
        ),
      );
    }
    return widgets;
  }
}
