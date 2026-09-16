import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../trtc/presentation/trtc_room_manager.dart';
import '../../../domain/entities/live_broadcast_session.dart';
import '../../../domain/pk/live_pk_broadcast_stage.dart';
import '../../../domain/pk/pk_status_helper.dart';
import '../../providers/live_pk_ui_providers.dart';
import '../../providers/live_room_interaction_provider.dart';
import '../../providers/live_video_pk_provider.dart';
import 'live_pk_immersive_controls.dart';

/// Yayın odası PK — timer, beğeni, alt kontroller + floating gül.
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
    this.onClose,
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
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHost = session.isHost;
    final opponentMuted = ref.watch(livePkOpponentMutedProvider(streamId));
    final interaction = ref.watch(liveRoomInteractionProvider(streamId));
    final pk = ref.watch(liveVideoPkProvider(streamId));
    final battle = pk.battle ?? const <String, dynamic>{};
    final pkActive = isLivePkBroadcastStage(battle, pk.status);
    final pkRunning = isLivePkActiveStatus(pk.status);

    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final controlsHeight = 96.0 + bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (pkActive)
          Positioned(
            top: top + 52,
            left: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_rounded,
                        color: Color(0xFFFF2D7A), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${interaction.likeCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
                  ref
                      .read(livePkOpponentMutedProvider(streamId).notifier)
                      .state = next;
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
              if (isHost && pkRunning)
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
