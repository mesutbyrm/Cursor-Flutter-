import 'package:flutter/material.dart';

import '../../../../agora/presentation/agora_room_manager.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../domain/entities/chat_room_presence.dart';
import '../../utils/voice_room_seat_layout.dart';
import '../../utils/voice_room_seat_priority.dart';
import 'voice_mic_seat.dart';

/// canlifal.com: sol Kurucu (koltuk 1) + sağda 2×5 (koltuk 2–11).
/// Koltuk 11 (sağ alt admin) yalnızca doluysa görünür; sahip yoksa koltuk 1 boş kalır.
class VoiceWebOwnerStage extends StatelessWidget {
  const VoiceWebOwnerStage({
    super.key,
    required this.room,
    required this.presence,
    this.djUserIds,
    this.speakingUserId,
    this.speakingUserIds = const {},
    this.onUserTap,
    this.onSeatTap,
    this.agora,
    this.agoraReady = false,
    this.selfUserId,
    this.remoteAgoraUid,
  });

  final VoiceRoomEntity room;
  final List<ChatRoomPresence> presence;
  final List<String>? djUserIds;
  final String? speakingUserId;
  final Set<String> speakingUserIds;
  final void Function(ChatRoomPresence user)? onUserTap;
  final void Function(int internalSeatIndex, ChatRoomPresence? user)? onSeatTap;
  final AgoraRoomManager? agora;
  final bool agoraReady;
  final String? selfUserId;
  final int? remoteAgoraUid;

  List<String> get _effectiveDjIds =>
      djUserIds ?? room.djUserIds;

  bool _isSpeaking(ChatRoomPresence? user) {
    if (user == null) return false;
    return speakingUserIds.contains(user.id) ||
        speakingUserId == user.id ||
        user.isSpeaking;
  }

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
        final showAdminSeat = VoiceRoomSeatPriority.showAdminSeat(seats);
        final host = seats[1];

        final topInternal = const [2, 3, 4, 5, 6];
        final bottomInternal = showAdminSeat
            ? const [7, 8, 9, 10, 11]
            : const [7, 8, 9, 10];

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
                  isHost: host != null,
                  room: room,
                  djUserIds: _effectiveDjIds,
                  speaking: _isSpeaking(host),
                  onTap: () => onSeatTap?.call(1, host),
                  agora: agora,
                  agoraReady: agoraReady,
                  selfUserId: selfUserId,
                  remoteAgoraUid: remoteAgoraUid,
                ),
                const SizedBox(width: gap),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _seatRow(
                        seats: seats,
                        internalNums: topInternal,
                        size: cell,
                        gap: gap,
                      ),
                      const SizedBox(height: gap),
                      _seatRow(
                        seats: seats,
                        internalNums: bottomInternal,
                        size: cell,
                        gap: gap,
                        columns: bottomInternal.length,
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

  Widget _seatRow({
    required Map<int, ChatRoomPresence> seats,
    required List<int> internalNums,
    required double size,
    required double gap,
    int columns = 5,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(columns, (col) {
        if (col >= internalNums.length) {
          return SizedBox(width: size);
        }
        final internal = internalNums[col];
        final user = seats[internal];
        return VoiceMicSeat(
          user: user,
          seatIndex: internal,
          size: size,
          room: room,
          djUserIds: _effectiveDjIds,
          speaking: _isSpeaking(user),
          onTap: () => onSeatTap?.call(internal, user),
          agora: agora,
          agoraReady: agoraReady,
          selfUserId: selfUserId,
          remoteAgoraUid: remoteAgoraUid,
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
