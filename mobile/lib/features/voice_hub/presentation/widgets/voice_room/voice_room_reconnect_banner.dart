import 'package:flutter/material.dart';

import 'package:canlifal_social/features/live/presentation/widgets/broadcast_room/live_reconnect_banner.dart';

/// Sesli oda SSE/TRTC yeniden bağlanma banner'ı.
class VoiceRoomReconnectBanner extends StatelessWidget {
  const VoiceRoomReconnectBanner({
    super.key,
    required this.message,
    this.onRetry,
    this.topPadding = 8,
  });

  final String message;
  final VoidCallback? onRetry;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return LiveReconnectBanner(
      message: message,
      onRetry: onRetry,
      topPadding: topPadding,
    );
  }
}
