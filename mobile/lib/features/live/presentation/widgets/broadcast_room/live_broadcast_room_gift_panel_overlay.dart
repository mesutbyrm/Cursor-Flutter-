import 'package:flutter/material.dart';

import '../../../../gifts/presentation/widgets/premium_gift_panel.dart';
import '../../gifts/live_gift_controller.dart' show LiveGiftController;

/// Alt hediye paneli — canlı yayın.
class LiveBroadcastRoomGiftPanelOverlay extends StatelessWidget {
  const LiveBroadcastRoomGiftPanelOverlay({
    super.key,
    required this.controller,
    required this.streamId,
    required this.senderName,
    required this.senderId,
    required this.onClose,
  });

  final LiveGiftController controller;
  final String streamId;
  final String senderName;
  final String senderId;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Semantics(
        label: 'Hediye paneli',
        child: PremiumGiftPanel(
          controller: controller,
          streamId: streamId,
          senderName: senderName,
          senderId: senderId,
          onClose: onClose,
        ),
      ),
    );
  }
}
