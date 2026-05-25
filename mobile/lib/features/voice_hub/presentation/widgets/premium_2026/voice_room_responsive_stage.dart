import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../domain/entities/chat_room_presence.dart';
import '../../utils/voice_room_seat_layout.dart';
import 'voice_mic_seat.dart';

/// PART 3 — Ekrana sığan yarım daire 8 mikrofon + merkez host.
class VoiceRoomResponsiveStage extends StatelessWidget {
  const VoiceRoomResponsiveStage({
    super.key,
    required this.room,
    required this.presence,
    required this.speakingUserIds,
    this.onUserTap,
    this.onEmptySeatTap,
    this.maxSeats = 8,
  });

  final VoiceRoomEntity room;
  final List<ChatRoomPresence> presence;
  final Set<String> speakingUserIds;
  final void Function(ChatRoomPresence user)? onUserTap;
  final VoidCallback? onEmptySeatTap;
  final int maxSeats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        if (w <= 0 || h <= 0) return const SizedBox.shrink();

        final seats = VoiceRoomSeatLayout(room: room, presence: presence).build();
        final host = _resolveHost(seats);
        final others = _orderedSpeakers(seats, host);

        final hostSize = (math.min(w, h) * 0.26).clamp(72.0, 108.0);
        final arcRadius = (w * 0.34).clamp(100.0, 160.0);
        final centerY = h * 0.58;
        final center = Offset(w / 2, centerY);

        return RepaintBoundary(
          child: SizedBox(
            width: w,
            height: h,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                ..._arcSeats(
                  others: others,
                  center: center,
                  radius: arcRadius,
                  hostSize: hostSize,
                ),
                Positioned(
                  left: center.dx - hostSize / 2,
                  top: centerY - hostSize / 2 - 8,
                  child: VoiceMicSeat(
                    user: host,
                    seatIndex: 1,
                    size: hostSize,
                    isHost: true,
                    speaking: host != null &&
                        (speakingUserIds.contains(host.id) || host.isSpeaking),
                    onTap: host != null ? () => onUserTap?.call(host) : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
    required double hostSize,
  }) {
    final slots = maxSeats - 1;
    final widgets = <Widget>[];
    for (var i = 0; i < slots; i++) {
      final t = slots == 1 ? 0.5 : i / (slots - 1);
      final angle = math.pi * 1.08 + t * math.pi * 0.84;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle) * 0.52 - 12;
      final user = i < others.length ? others[i] : null;
      final size = i < 2
          ? (hostSize * 0.68).clamp(48.0, 64.0)
          : i < 4
              ? (hostSize * 0.58).clamp(44.0, 56.0)
              : (hostSize * 0.5).clamp(40.0, 48.0);
      widgets.add(
        Positioned(
          left: x - size / 2,
          top: y - size / 2,
          child: VoiceMicSeat(
            user: user,
            seatIndex: i + 2,
            size: size,
            speaking: user != null &&
                (speakingUserIds.contains(user.id) || user.isSpeaking),
            locked: false,
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
