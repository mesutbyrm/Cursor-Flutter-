import 'package:flutter/material.dart';

import '../../../../trtc/presentation/trtc_room_manager.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../domain/entities/chat_room_presence.dart';
import '../../utils/voice_room_seat_layout.dart';
import '../../utils/voice_room_seat_capacity.dart';
import '../../utils/voice_room_speak_access.dart';
import 'voice_web_owner_stage_seat.dart';

/// canlifal.com: sol Kurucu (koltuk 1) + sağda 2×5 (koltuk 2–11).
/// Koltuk 11 (sağ alt admin) yalnızca doluysa görünür; sahip yoksa koltuk 1 boş kalır.
class VoiceWebOwnerStage extends StatelessWidget {
  const VoiceWebOwnerStage({
    super.key,
    required this.roomKey,
    required this.room,
    this.djUserIds,
    this.speakingUserId,
    this.speakingUserIds = const {},
    this.onUserTap,
    this.onSeatTap,
    this.onSeatLongPress,
    this.trtc,
    this.trtcReady = false,
    this.selfUserId,
    this.remoteTrtcUserId,
  });

  final String roomKey;
  final VoiceRoomEntity room;
  final List<String>? djUserIds;
  final String? speakingUserId;
  final Set<String> speakingUserIds;
  final void Function(ChatRoomPresence user)? onUserTap;
  final void Function(int internalSeatIndex, ChatRoomPresence? user)? onSeatTap;
  final void Function(int internalSeatIndex)? onSeatLongPress;
  final TrtcRoomManager? trtc;
  final bool trtcReady;
  final String? selfUserId;
  final String? remoteTrtcUserId;

  List<String> get _effectiveDjIds => djUserIds ?? room.djUserIds;

  Set<String> get _effectiveSpeakingIds {
    if (speakingUserIds.isNotEmpty) return speakingUserIds;
    if (speakingUserId != null) return {speakingUserId!};
    return const {};
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

        final rows = voiceWebOwnerSeatRows(room: room);
        final topInternal = rows.top;
        final bottomInternal = rows.bottom;
        final speaking = _effectiveSpeakingIds;

        return SizedBox(
          height: totalH,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: hPad),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                VoiceWebOwnerStageSeat(
                  roomKey: roomKey,
                  room: room,
                  seatIndex: 1,
                  size: hostSize,
                  isHost: true,
                  djUserIds: _effectiveDjIds,
                  speakingUserIds: speaking,
                  onSeatTap: onSeatTap,
                  onSeatLongPress: onSeatLongPress,
                  trtc: trtc,
                  trtcReady: trtcReady,
                  selfUserId: selfUserId,
                  remoteTrtcUserId: remoteTrtcUserId,
                ),
                const SizedBox(width: gap),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _seatRow(
                        internalNums: topInternal,
                        size: cell,
                        gap: gap,
                        speaking: speaking,
                      ),
                      const SizedBox(height: gap),
                      _seatRow(
                        internalNums: bottomInternal,
                        size: cell,
                        gap: gap,
                        columns: bottomInternal.length,
                        speaking: speaking,
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
    required List<int> internalNums,
    required double size,
    required double gap,
    required Set<String> speaking,
    int columns = 5,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(columns, (col) {
        if (col >= internalNums.length) {
          return SizedBox(width: size);
        }
        final internal = internalNums[col];
        return VoiceWebOwnerStageSeat(
          roomKey: roomKey,
          room: room,
          seatIndex: internal,
          size: size,
          djUserIds: _effectiveDjIds,
          speakingUserIds: speaking,
          onSeatTap: onSeatTap,
          onSeatLongPress: onSeatLongPress,
          trtc: trtc,
          trtcReady: trtcReady,
          selfUserId: selfUserId,
          remoteTrtcUserId: remoteTrtcUserId,
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

/// Koltuk atama / speak-queue — yalnızca backend koltuğu.
Set<String> voiceBackendSeatedIds(List<ChatRoomPresence> presence) {
  return VoiceRoomSpeakAccess.backendSeatedUserIds(presence);
}

List<ChatRoomPresence> voiceWebAudienceOffStage({
  required VoiceRoomEntity room,
  required List<ChatRoomPresence> presence,
}) {
  final onIds = voiceWebOnStageIds(room: room, presence: presence);
  return presence.where((p) => !onIds.contains(p.id)).toList();
}
