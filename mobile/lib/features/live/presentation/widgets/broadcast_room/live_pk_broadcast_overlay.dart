import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../trtc/presentation/trtc_room_manager.dart';
import '../../../domain/entities/live_broadcast_session.dart';
import '../../../domain/pk/live_pk_broadcast_stage.dart';
import '../../../domain/pk/pk_status_helper.dart';
import '../../providers/live_pk_ui_providers.dart';
import '../../providers/live_video_pk_provider.dart';
import 'live_pk_immersive_controls.dart';
import 'live_pk_layout_metrics.dart';

/// Yayın odası PK — alt kontroller + mesaj girişi (referans 1:1).
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
    this.onMore,
    this.onShare,
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
  final VoidCallback? onMore;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHost = session.isHost;
    final opponentMuted = ref.watch(livePkOpponentMutedProvider(streamId));
    final pk = ref.watch(liveVideoPkProvider(streamId));
    final battle = pk.battle ?? const <String, dynamic>{};
    final pkActive = isLivePkBroadcastStage(battle, pk.status);
    final pkRunning = isLivePkActiveStatus(pk.status);
    final oppId = opponentUserId.trim();

    final inset = LivePkLayoutMetrics.bottomInset(context);
    // Alt çubuk: yorum + hediye + paylaş en altta; yayıncı kontrolleri üstünde.
    final inputBottom = inset + 8;
    final controlsBottom = inputBottom + LivePkLayoutMetrics.inputBarHeight;

    if (!pkActive) return const SizedBox.shrink();

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: inputBottom,
          child: LivePkChatInputBar(
            controller: chatController,
            // İzleyicide sohbet kapatma yok; yayıncı «Sohbet» ile açıp kapatır.
            visible: chatOpen || !isHost,
            onGift: onGift,
            onShare: onShare,
            onSend: onSendChat,
            onMore: onMore,
            onToggleVisibility: () => onChatOpenChanged(false),
          ),
        ),
        if (isHost)
        Positioned(
          left: 0,
          right: 0,
          bottom: controlsBottom,
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
                icon: chatOpen
                    ? Icons.chat_bubble_rounded
                    : Icons.chat_bubble_outline_rounded,
                label: 'Sohbet',
                onTap: () => onChatOpenChanged(!chatOpen),
              ),
              if (isHost && pkRunning && oppId.isNotEmpty)
                LivePkControlItem(
                  icon: opponentMuted
                      ? Icons.mic_off_rounded
                      : Icons.mic_rounded,
                  label: opponentMuted ? 'Ses kapalı' : 'Rakip sesi',
                  onTap: () {
                    final next = !opponentMuted;
                    ref
                        .read(livePkOpponentMutedProvider(streamId).notifier)
                        .state = next;
                    trtc.muteRemoteAudio(oppId, next);
                  },
                ),
              if (isHost && pkRunning)
                LivePkControlItem(
                  icon: Icons.flag_rounded,
                  label: 'PK bitir',
                  danger: true,
                  onTap: onEndPk,
                ),
              if (isHost && !pkRunning)
                LivePkControlItem(
                  icon: Icons.close_rounded,
                  label: "PK'yi Kapat",
                  danger: true,
                  onTap: () => ref
                      .read(liveVideoPkProvider(streamId).notifier)
                      .forceExitPk(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
