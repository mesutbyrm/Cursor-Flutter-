import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../trtc/presentation/trtc_room_manager.dart';
import '../../../domain/entities/live_broadcast_session.dart';
import '../../providers/live_pk_ui_providers.dart';
import 'live_pk_immersive_controls.dart';

/// Yayın odası PK — referans alt kontroller + floating gül + kompakt sohbet.
class LivePkBroadcastOverlay extends ConsumerWidget {
  const LivePkBroadcastOverlay({
    super.key,
    required this.streamId,
    required this.session,
    required this.trtc,
    required this.chatController,
    required this.chatOpen,
    required this.onChatOpenChanged,
    required this.opponentUserId,
    required this.onEndPk,
    required this.onGift,
    required this.onSendChat,
    this.onRtcStateChanged,
  });

  final String streamId;
  final LiveBroadcastSession session;
  final TrtcRoomManager trtc;
  final TextEditingController chatController;
  final bool chatOpen;
  final ValueChanged<bool> onChatOpenChanged;
  final String opponentUserId;
  final VoidCallback onEndPk;
  final VoidCallback onGift;
  final VoidCallback onSendChat;
  final VoidCallback? onRtcStateChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHost = session.isHost;
    final opponentMuted = ref.watch(livePkOpponentMutedProvider(streamId));
    final bottom = MediaQuery.paddingOf(context).bottom;
    final chatBarHeight = chatOpen ? 52.0 : 0.0;
    final controlsHeight = 96.0 + bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        LivePkFloatingGiftButton(onTap: onGift),
        Positioned(
          left: 0,
          right: 0,
          bottom: controlsHeight,
          child: LivePkChatInputBar(
            controller: chatController,
            visible: chatOpen,
            onGift: onGift,
            onQuickRose: onGift,
            onSend: onSendChat,
            onToggleVisibility: () => onChatOpenChanged(false),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: LivePkImmersiveControls(
            items: [
              if (isHost)
                LivePkControlItem(
                  icon: trtc.micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                  label: 'Mikrofon',
                  active: trtc.micOn,
                  onTap: () {
                    trtc.setMicEnabled(!trtc.micOn);
                    onRtcStateChanged?.call();
                  },
                ),
              if (isHost)
                LivePkControlItem(
                  icon: trtc.cameraOn
                      ? Icons.videocam_rounded
                      : Icons.videocam_off_rounded,
                  label: 'Kamera',
                  active: trtc.cameraOn,
                  onTap: () {
                    trtc.setCameraEnabled(!trtc.cameraOn);
                    onRtcStateChanged?.call();
                  },
                ),
              LivePkControlItem(
                icon: opponentMuted
                    ? Icons.volume_off_rounded
                    : Icons.hearing_rounded,
                label: 'Rakip ses',
                active: !opponentMuted,
                onTap: () {
                  final next = !opponentMuted;
                  ref.read(livePkOpponentMutedProvider(streamId).notifier).state =
                      next;
                  final opp = opponentUserId.trim();
                  if (opp.isNotEmpty) {
                    trtc.muteRemoteAudio(opp, next);
                  }
                },
              ),
              LivePkControlItem(
                icon: chatOpen
                    ? Icons.chat_bubble_rounded
                    : Icons.chat_bubble_outline_rounded,
                label: 'Sohbet',
                onTap: () => onChatOpenChanged(!chatOpen),
              ),
              if (isHost)
                LivePkControlItem(
                  icon: Icons.stop_circle_outlined,
                  label: 'Bitir',
                  danger: true,
                  onTap: onEndPk,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
