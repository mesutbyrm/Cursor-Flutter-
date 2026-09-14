import 'package:flutter/material.dart';

import 'live_host_fortune_request_center_overlay.dart';
import 'live_host_guest_request_center_overlay.dart';

/// Host-only canlı yayın overlay'leri (misafir + fal istek merkezi).
class LiveBroadcastRoomHostOverlays extends StatelessWidget {
  const LiveBroadcastRoomHostOverlays({
    super.key,
    required this.streamId,
    required this.currentGuestCount,
    required this.onApproved,
    required this.onRejected,
    required this.onBlocked,
  });

  final String streamId;
  final int currentGuestCount;
  final Future<void> Function(Map<String, dynamic> request) onApproved;
  final Future<void> Function(Map<String, dynamic> request) onRejected;
  final Future<void> Function(Map<String, dynamic> request) onBlocked;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        LiveHostGuestRequestCenterOverlay(
          streamId: streamId,
          currentGuestCount: currentGuestCount,
          onApproved: onApproved,
          onRejected: onRejected,
          onBlocked: onBlocked,
        ),
        LiveHostFortuneRequestCenterOverlay(streamId: streamId),
      ],
    );
  }
}
