import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/core/theme/app_colors.dart';
import 'package:canlifal_social/features/trtc/presentation/trtc_room_manager.dart';
import '../../../domain/entities/live_broadcast_session.dart';
import '../../../domain/entities/live_guest_layout.dart';
import '../../../domain/pk/pk_status_helper.dart';
import '../../pages/live_session_phase.dart';
import '../../gifts/providers/live_gift_providers.dart';
import '../../providers/live_video_pk_provider.dart';
import '../../widgets/live_playback_bridge.dart';
import '../../widgets/live_tiktok/live_guest_grid.dart';
import 'live_pk_split_video_layer.dart';
import 'live_room_video_background.dart';

/// TRTC / playback video katmanı (state orchestration üst dosyada).
class LiveBroadcastRoomVideoLayer extends ConsumerWidget {
  const LiveBroadcastRoomVideoLayer({
    super.key,
    required this.session,
    required this.phase,
    required this.trtc,
    required this.rtcReady,
    required this.rtcError,
    required this.signalPollError,
    required this.localPreviewKey,
    required this.guestLayout,
    required this.onEndActivePk,
    required this.onOpenControlCenter,
    required this.onGuestAction,
    this.chatVisibleForPk = true,
  });

  final LiveBroadcastSession session;
  final LiveSessionPhase phase;
  final TrtcRoomManager trtc;
  final bool rtcReady;
  final String? rtcError;
  final String? signalPollError;
  final Key localPreviewKey;
  final LiveGuestLayout guestLayout;
  final Future<void> Function(String streamId) onEndActivePk;
  final VoidCallback onOpenControlCenter;
  final void Function(int slotIndex, String action) onGuestAction;
  final bool chatVisibleForPk;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = session;
    if (s.backgroundUrl?.trim().isNotEmpty == true && !s.isImageMode) {
      return Stack(
        fit: StackFit.expand,
        children: [
          CanlifalNetworkImage(
            url: s.backgroundUrl!,
            fit: BoxFit.cover,
            errorWidget: const SizedBox.shrink(),
          ),
          _mainVideo(context, ref, s),
        ],
      );
    }
    if (s.isImageMode && s.coverImageUrl?.trim().isNotEmpty == true) {
      return _imageModeLayer(s);
    }
    return _mainVideo(context, ref, s);
  }

  Widget _mainVideo(BuildContext context, WidgetRef ref, LiveBroadcastSession s) {
    final streamId = s.streamId?.trim() ?? '';
    if (streamId.isNotEmpty) {
      final pkState = ref.watch(liveVideoPkProvider(streamId));
      if (isLivePkSplitReady(pkState.battle, pkState.status)) {
        return LivePkSplitVideoLayer(
          streamId: streamId,
          session: s,
          trtc: trtc,
          rtcReady: rtcReady,
          chatVisible: chatVisibleForPk,
          hideTopTimer: true,
          onEndPk: s.isHost ? () => onEndActivePk(streamId) : null,
        );
      }
    }
    if (phase == LiveSessionPhase.reconnecting) {
      return Stack(
        fit: StackFit.expand,
        children: [
          if (!s.isHost)
            LivePlaybackBridge(
              playbackUrl: s.playbackUrl,
              thumbnailUrl: s.coverImageUrl ?? s.avatarUrl,
            )
          else
            _imageModeLayer(s),
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Yeniden bağlanılıyor…',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    if (!rtcReady) {
      return Stack(
        fit: StackFit.expand,
        children: [
          if (!s.isHost)
            LivePlaybackBridge(
              playbackUrl: s.playbackUrl,
              thumbnailUrl: s.coverImageUrl ?? s.avatarUrl,
            )
          else
            _imageModeLayer(s),
          if (rtcError == null && s.isHost)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.sensors_rounded,
                    size: 56,
                    color: Color(0xFFB832FF),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Yayın başlatılıyor…',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          if (rtcError == null && !s.isHost)
            Positioned(
              left: 16,
              bottom: 128,
              child: _liveConnectingBadge(),
            ),
          if (signalPollError != null && rtcError == null)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 52,
              left: 16,
              right: 16,
              child: Material(
                color: Colors.orange.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    signalPollError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ),
            ),
          if (rtcError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  rtcError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
        ],
      );
    }

    final remoteUid = trtc.remoteAnchorUserIdNotifier.value;
    final hostJeton = ref.read(liveGiftControllerProvider).streamerEarnings ?? 0;
    return ValueListenableBuilder<List<String>>(
      valueListenable: trtc.remoteUserIdsNotifier,
      builder: (context, remoteUids, _) {
        return LiveGuestGrid(
          layout: guestLayout,
          isHost: s.isHost,
          trtc: trtc,
          localPreviewKey: localPreviewKey,
          hostAvatarUrl: s.avatarUrl,
          hostName: s.streamerName,
          remoteUserId: remoteUid,
          hostJetonEarned: hostJeton,
          onInviteSlot: s.isHost ? (_) => onOpenControlCenter() : null,
          onGuestAction: s.isHost ? onGuestAction : null,
        );
      },
    );
  }

  Widget _liveConnectingBadge() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white70,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Canlı bağlanıyor',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageModeLayer(LiveBroadcastSession s) {
    final image = s.coverImageUrl?.trim();
    final bg = s.backgroundUrl?.trim();
    final url = image?.isNotEmpty == true ? image : bg;
    if (url == null || url.isEmpty) return const LiveRoomVideoBackground();
    return Stack(
      fit: StackFit.expand,
      children: [
        CanlifalNetworkImage(
          url: url,
          fit: BoxFit.cover,
          errorWidget: const LiveRoomVideoBackground(),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.15),
                Colors.black.withValues(alpha: 0.62),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
