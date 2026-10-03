import 'package:flutter/material.dart';

import '../../../../trtc/presentation/trtc_room_manager.dart';
import '../premium_2026/live/live_broadcast_bottom_bar_v2.dart';

/// Alt kontrol çubuğu — klavye padding ile.
class LiveBroadcastRoomBottomChrome extends StatelessWidget {
  const LiveBroadcastRoomBottomChrome({
    super.key,
    required this.chatController,
    required this.isHost,
    required this.trtc,
    required this.commentsEnabled,
    required this.onGift,
    required this.onTip,
    required this.onMore,
    required this.onRtcStateChanged,
    required this.onToggleCamera,
    required this.onSend,
    required this.onEnd,
    this.moreBadgeCount = 0,
    this.onEndPk,
    this.onToggleOpponentMute,
    this.opponentMuted = false,
    this.showPkHostControls = false,
    this.onGuest,
    this.onMulti,
    this.onShare,
    this.onSettings,
    this.multiLayoutActive = false,
    this.guestLabel = 'Misafir',
    this.guestIcon = Icons.person_add_alt_1_rounded,
  });

  final TextEditingController chatController;
  final bool isHost;
  final TrtcRoomManager? trtc;
  final bool commentsEnabled;
  final VoidCallback? onGift;
  final VoidCallback? onTip;
  final VoidCallback onMore;
  final VoidCallback? onRtcStateChanged;
  final VoidCallback? onToggleCamera;
  final VoidCallback onSend;
  final VoidCallback? onEnd;
  final int moreBadgeCount;
  final VoidCallback? onEndPk;
  final VoidCallback? onToggleOpponentMute;
  final bool opponentMuted;
  final bool showPkHostControls;
  final VoidCallback? onGuest;
  final VoidCallback? onMulti;
  final VoidCallback? onShare;
  final VoidCallback? onSettings;
  final bool multiLayoutActive;
  final String guestLabel;
  final IconData guestIcon;

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: LiveBroadcastBottomBarV2(
        chatController: chatController,
        isHost: isHost,
        trtc: trtc,
        commentsEnabled: commentsEnabled,
        onGift: onGift,
        onTip: onTip,
        onMore: onMore,
        onRtcStateChanged: onRtcStateChanged,
        onToggleCamera: onToggleCamera,
        onSend: onSend,
        onEnd: onEnd,
        moreBadgeCount: moreBadgeCount,
        onEndPk: onEndPk,
        onToggleOpponentMute: onToggleOpponentMute,
        opponentMuted: opponentMuted,
        showPkHostControls: showPkHostControls,
        onGuest: onGuest,
        onMulti: onMulti,
        onShare: onShare,
        onSettings: onSettings,
        multiLayoutActive: multiLayoutActive,
        guestLabel: guestLabel,
        guestIcon: guestIcon,
      ),
    );
  }
}
