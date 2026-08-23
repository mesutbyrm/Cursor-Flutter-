import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../../trtc/presentation/trtc_room_manager.dart';
import '../../../domain/entities/chat_room_presence.dart';
import '../../providers/chat_room_providers.dart';
import '../../utils/voice_seat_snapshot.dart';
import 'voice_mic_seat.dart';

/// Tek koltuk — yalnızca kendi snapshot'ı değişince rebuild.
class VoiceWebOwnerStageSeat extends ConsumerWidget {
  const VoiceWebOwnerStageSeat({
    super.key,
    required this.roomKey,
    required this.room,
    required this.seatIndex,
    required this.size,
    this.isHost = false,
    this.djUserIds = const [],
    this.speakingUserIds = const {},
    this.onSeatTap,
    this.onSeatLongPress,
    this.trtc,
    this.trtcReady = false,
    this.selfUserId,
    this.remoteTrtcUserId,
  });

  final String roomKey;
  final VoiceRoomEntity room;
  final int seatIndex;
  final double size;
  final bool isHost;
  final List<String> djUserIds;
  final Set<String> speakingUserIds;
  final void Function(int internalSeatIndex, ChatRoomPresence? user)? onSeatTap;
  final void Function(int internalSeatIndex)? onSeatLongPress;
  final TrtcRoomManager? trtc;
  final bool trtcReady;
  final String? selfUserId;
  final String? remoteTrtcUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(
      voiceRoomLiveProvider(roomKey).select(
        (live) => VoiceSeatSnapshot.fromLive(
          room: room,
          live: live,
          seatIndex: seatIndex,
        ),
      ),
    );

    final user = snap.user;
    return VoiceMicSeat(
      user: user,
      seatIndex: seatIndex,
      size: size,
      isHost: isHost,
      room: room,
      roomKey: roomKey,
      djUserIds: djUserIds,
      speaking: snap.isSpeaking(extraSpeakingIds: speakingUserIds),
      locked: snap.locked,
      micOpen: snap.micOpen,
      onTap: () => onSeatTap?.call(seatIndex, user),
      onLongPress: user == null ? () => onSeatLongPress?.call(seatIndex) : null,
      trtc: trtc,
      trtcReady: trtcReady,
      selfUserId: selfUserId,
      remoteTrtcUserId: remoteTrtcUserId,
    );
  }
}
