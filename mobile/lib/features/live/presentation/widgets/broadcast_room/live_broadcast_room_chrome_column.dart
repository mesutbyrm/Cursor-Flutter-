import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../trtc/presentation/trtc_room_manager.dart';
import '../../../domain/entities/live_broadcast_session.dart';
import '../../../domain/entities/live_fortune_request_entity.dart';
import '../../providers/live_gift_leaderboard_provider.dart';
import '../../providers/live_host_rank_provider.dart';
import '../../providers/live_video_pk_provider.dart';
import 'live_network_quality_pill.dart';
import '../premium_2026/live_premium_2026.dart';
import 'live_broadcast_room_bottom_chrome.dart';
import 'live_broadcast_room_chat_overlay.dart';
import 'live_pk_score_bar.dart';
import 'live_room_chat_message.dart';
import '../pk/live_pk_host_pending_banner.dart';

/// Üst bar + PK bekleyen + sohbet + alt kontrol (orchestration üstte).
class LiveBroadcastRoomChromeColumn extends ConsumerWidget {
  const LiveBroadcastRoomChromeColumn({
    super.key,
    required this.topInset,
    required this.session,
    required this.streamId,
    required this.hasStream,
    required this.embeddedInSwipe,
    required this.chatVisible,
    required this.onChatVisibleChanged,
    required this.roomMessages,
    required this.lastJoinedName,
    required this.balance,
    required this.initialFortuneType,
    required this.onMessageLongPress,
    required this.onSubmitFortuneRequest,
    required this.viewerSideRail,
    required this.chatController,
    required this.trtc,
    required this.networkQualityListenable,
    required this.following,
    required this.followLoading,
    required this.onFollow,
    required this.onClose,
    required this.onViewersTap,
    required this.onProfileTap,
    required this.fortuneTypeBadge,
    required this.hostRank,
    required this.pkState,
    required this.pkStatus,
    required this.commentsEnabled,
    required this.onGift,
    required this.onTip,
    required this.onMore,
    required this.onRtcStateChanged,
    required this.onToggleCamera,
    required this.onSend,
    required this.onEnd,
  });

  final double topInset;
  final LiveBroadcastSession session;
  final String? streamId;
  final bool hasStream;
  final bool embeddedInSwipe;
  final bool chatVisible;
  final ValueChanged<bool> onChatVisibleChanged;
  final List<LiveRoomChatMessage> roomMessages;
  final String? lastJoinedName;
  final int? balance;
  final String? initialFortuneType;
  final void Function(LiveRoomChatMessage message)? onMessageLongPress;
  final Future<bool> Function({
    required String displayName,
    required String question,
    required String fortuneType,
    required LiveFortunePriority priority,
    required int jetonCost,
  }) onSubmitFortuneRequest;
  final Widget viewerSideRail;
  final TextEditingController chatController;
  final TrtcRoomManager trtc;
  final ValueListenable<int?> networkQualityListenable;
  final bool following;
  final bool followLoading;
  final VoidCallback onFollow;
  final VoidCallback onClose;
  final VoidCallback? onViewersTap;
  final VoidCallback? onProfileTap;
  final String? fortuneTypeBadge;
  final LiveHostRankInfo? hostRank;
  final LiveVideoPkState? pkState;
  final String pkStatus;
  final bool commentsEnabled;
  final VoidCallback? onGift;
  final VoidCallback? onTip;
  final VoidCallback onMore;
  final VoidCallback? onRtcStateChanged;
  final VoidCallback? onToggleCamera;
  final VoidCallback onSend;
  final VoidCallback? onEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = session;
    final streamId = this.streamId;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12, topInset > 0 ? 4 : 12, 12, 0),
            child: LivePremiumTopBar(
              session: s,
              elapsedBadge: const LiveElapsedTimePill(),
              streamTitle: s.title.trim().isNotEmpty ? s.title : null,
              fortuneTypeBadge: fortuneTypeBadge,
              networkQualityBadge: s.isHost
                  ? LiveNetworkQualityPill(
                      qualityListenable: networkQualityListenable,
                    )
                  : null,
              following: following,
              followLoading: followLoading,
              onFollow: onFollow,
              onClose: onClose,
              topGifters: hasStream && streamId != null
                  ? ref.watch(liveGiftLeaderboardProvider(streamId))
                  : const [],
              popularRank: hostRank?.popularRank,
              leagueLabel: hostRank?.leagueLabel,
              onPopularTap: () => context.push('/pk/leaderboard'),
              onLeagueTap: () => context.push('/pk/leaderboard'),
              onViewersTap: onViewersTap,
              onProfileTap: onProfileTap,
              onDiscoverTap: () => context.go('/live'),
              onBack: embeddedInSwipe ? onClose : null,
            ),
          ),
          if (hasStream && streamId != null && s.isHost)
            LivePkHostPendingBanner(streamId: streamId!),
          if (hasStream && pkState?.battle != null && pkStatus == 'pending' && !s.isHost)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Builder(
                builder: (_) {
                  final state = pkState!;
                  final canRespond = state.isOpponent;
                  return LivePkScoreBar(
                    leftScore: state.leftScore,
                    rightScore: state.rightScore,
                    status: pkStatus,
                    isHost: s.isHost,
                    onAccept: canRespond
                        ? () => ref
                            .read(liveVideoPkProvider(streamId!).notifier)
                            .accept()
                        : null,
                    onReject: canRespond
                        ? () => ref
                            .read(liveVideoPkProvider(streamId!).notifier)
                            .reject()
                        : null,
                  );
                },
              ),
            ),
          const Spacer(),
          LiveBroadcastRoomChatOverlay(
            chatVisible: chatVisible,
            onHideChat: () => onChatVisibleChanged(false),
            onShowChat: () => onChatVisibleChanged(true),
            session: s,
            lastJoinedName: lastJoinedName,
            messages: roomMessages,
            balance: balance,
            initialFortuneType: initialFortuneType,
            onMessageLongPress: onMessageLongPress,
            onSubmitFortuneRequest: onSubmitFortuneRequest,
            viewerSideRail: viewerSideRail,
          ),
          const SizedBox(height: 8),
          LiveBroadcastRoomBottomChrome(
            chatController: chatController,
            isHost: s.isHost,
            trtc: s.isHost ? trtc : null,
            commentsEnabled: commentsEnabled,
            chatVisible: chatVisible,
            onToggleChat: () => onChatVisibleChanged(!chatVisible),
            onGift: onGift,
            onTip: onTip,
            onMore: onMore,
            onRtcStateChanged: onRtcStateChanged,
            onToggleCamera: onToggleCamera,
            onSend: onSend,
            onEnd: onEnd,
          ),
        ],
      ),
    );
  }
}
