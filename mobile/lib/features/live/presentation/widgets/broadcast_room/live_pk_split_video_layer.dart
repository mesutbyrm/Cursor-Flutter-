import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../trtc/presentation/trtc_room_manager.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../domain/entities/live_broadcast_session.dart';
import '../../../domain/pk/live_pk_side_resolver.dart';
import '../../providers/live_pk_ui_providers.dart';
import '../../providers/live_providers.dart';
import '../../providers/live_video_pk_provider.dart';
import '../live_playback_bridge.dart';

/// PK aktifken üst yarım: sol yerel/yayıncı, sağ rakip.
class LivePkSplitVideoLayer extends ConsumerWidget {
  const LivePkSplitVideoLayer({
    super.key,
    required this.streamId,
    required this.session,
    required this.trtc,
    required this.rtcReady,
    this.onEndPk,
    this.onMuteOpponent,
  });

  final String streamId;
  final LiveBroadcastSession session;
  final TrtcRoomManager trtc;
  final bool rtcReady;
  final VoidCallback? onEndPk;
  final void Function(String opponentUserId, bool mute)? onMuteOpponent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pk = ref.watch(liveVideoPkProvider(streamId));
    final battle = pk.battle;
    if (battle == null || pk.status != 'active') {
      return const ColoredBox(color: Color(0xFF120A1E));
    }

    final myUserId = ref.read(authControllerProvider).valueOrNull?.id;
    final layout = resolveLivePkSplitLayout(
      battle: battle,
      myStreamId: streamId,
      myUserId: myUserId ?? session.hostUserId,
      amBroadcaster: session.isHost,
    );

    final opponentMuted = ref.watch(livePkOpponentMutedProvider(streamId));
    final streams = ref.watch(liveStreamsProvider).valueOrNull ?? const [];

    String? playbackFor(String? targetStreamId) {
      final id = targetStreamId?.trim() ?? '';
      if (id.isEmpty) return null;
      for (final s in streams) {
        if (s.id == id) return s.playbackUrl ?? s.streamUrl;
      }
      return null;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Row(
          children: [
            Expanded(
              child: _PkPane(
                pane: layout.left,
                trtc: trtc,
                rtcReady: rtcReady,
                playbackUrl: layout.left.isLocalPane
                    ? null
                    : playbackFor(layout.left.streamId),
                accent: Colors.pinkAccent,
              ),
            ),
            Container(width: 2, color: Colors.white24),
            Expanded(
              child: _PkPane(
                pane: layout.right,
                trtc: trtc,
                rtcReady: rtcReady,
                playbackUrl: playbackFor(layout.right.streamId),
                accent: Colors.cyanAccent,
                preferRemoteUserId: layout.right.userId,
                playbackAudible: !session.isHost,
              ),
            ),
          ],
        ),
        if (session.isHost)
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (layout.right.userId != null &&
                    layout.right.userId!.isNotEmpty)
                  Material(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    child: IconButton(
                      tooltip: opponentMuted ? 'Sesi aç' : 'Rakibi sessize al',
                      icon: Icon(
                        opponentMuted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        final oppId = layout.right.userId!.trim();
                        final next = !opponentMuted;
                        ref
                            .read(livePkOpponentMutedProvider(streamId).notifier)
                            .state = next;
                        onMuteOpponent?.call(oppId, next);
                        trtc.muteRemoteAudio(oppId, next);
                      },
                    ),
                  ),
                const SizedBox(width: 4),
                Material(
                  color: Colors.orange.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  child: IconButton(
                    tooltip: 'Rakibi PK\'dan çıkar',
                    icon: const Icon(
                      Icons.person_remove_alt_1_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: onEndPk,
                  ),
                ),
                const SizedBox(width: 4),
                Material(
                  color: Colors.red.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20),
                  child: IconButton(
                    tooltip: 'PK bitir',
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                    onPressed: onEndPk,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PkPane extends StatelessWidget {
  const _PkPane({
    required this.pane,
    required this.trtc,
    required this.rtcReady,
    required this.accent,
    this.playbackUrl,
    this.preferRemoteUserId,
    this.playbackAudible = false,
  });

  final LivePkPaneModel pane;
  final TrtcRoomManager trtc;
  final bool rtcReady;
  final Color accent;
  final String? playbackUrl;
  final String? preferRemoteUserId;
  final bool playbackAudible;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: trtc.remoteUserIdsNotifier,
      builder: (context, remoteIds, _) {
        Widget video;
        final remoteId = preferRemoteUserId?.trim() ?? '';
        if (pane.isLocalPane && rtcReady) {
          video = TrtcLocalVideoView(manager: trtc);
        } else if (remoteId.isNotEmpty &&
            rtcReady &&
            remoteIds.contains(remoteId)) {
          video = TrtcRemoteVideoView(manager: trtc, userId: remoteId);
        } else if (playbackUrl != null && playbackUrl!.trim().isNotEmpty) {
          video = LivePlaybackBridge(
            playbackUrl: playbackUrl,
            thumbnailUrl: pane.avatarUrl,
            audible: playbackAudible,
          );
        } else if (pane.avatarUrl != null && pane.avatarUrl!.trim().isNotEmpty) {
          video = CanlifalNetworkImage(
            url: pane.avatarUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );
        } else {
          video = Center(
            child: Icon(Icons.videocam_rounded, size: 44, color: accent),
          );
        }

        return ColoredBox(
          color: const Color(0xFF120A1E),
          child: Stack(
            fit: StackFit.expand,
            children: [
              video,
              Positioned(
                left: 8,
                bottom: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      pane.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
