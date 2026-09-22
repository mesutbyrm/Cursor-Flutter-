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
      ),
    );
  }
}
