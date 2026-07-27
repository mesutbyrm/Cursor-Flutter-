import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../live/domain/entities/live_gift_event.dart';
import '../../../gifts/domain/gift_render_meta.dart';
import '../../../gifts/presentation/widgets/gift_animation_player.dart';
import '../../../gifts/presentation/widgets/gift_stage_layout.dart';

/// Tam ekran hediye — kenarları tam doldurur (`BoxFit.cover`).
class GiftFullscreenCoverOverlay extends StatelessWidget {
  const GiftFullscreenCoverOverlay({
    super.key,
    required this.event,
    this.stage = GiftStageContext.voiceRoom,
  });

  final LiveGiftEvent event;
  final GiftStageContext stage;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final edge = size.shortestSide;
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.35),
            ),
          ),
          Positioned(
            left: 8,
            top: MediaQuery.paddingOf(context).top + 8,
            right: 56,
            child: _SenderReceiverChip(
              label: _label(event),
            ),
          ),
          Center(
            child: GiftAnimationPlayer(
              giftId: event.giftId,
              event: event,
              size: edge,
              preferPremiumVisual: false,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  static String _label(LiveGiftEvent event) {
    final sender = event.senderName.trim();
    final receiver = event.receiverName.trim();
    if (sender.isEmpty && receiver.isEmpty) return 'Hediye';
    if (receiver.isEmpty) return sender;
    if (sender.isEmpty) return receiver;
    return '$sender → $receiver';
  }
}

class _SenderReceiverChip extends StatelessWidget {
  const _SenderReceiverChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
