import 'dart:math';

import 'package:flutter/material.dart';

import '../../../live/domain/entities/live_gift_event.dart';
import '../../domain/premium_gift_catalog_2026.dart';
import 'gift_animation_player.dart';
import 'premium_2026/premium_gift_icon.dart';

/// Hediye sahnesi — koltukların altından mesaj alanına kadar.
enum GiftStageContext {
  voiceRoom,
  liveStream,
}

abstract final class GiftStageMetrics {
  static EdgeInsets stagePadding(
    BuildContext context, {
    required GiftStageContext stage,
  }) {
    final topInset = switch (stage) {
      GiftStageContext.voiceRoom => 0.34,
      GiftStageContext.liveStream => 0.30,
    };
    final bottomInset = switch (stage) {
      GiftStageContext.voiceRoom => 168.0,
      GiftStageContext.liveStream => 210.0,
    };
    final h = MediaQuery.sizeOf(context).height;
    return EdgeInsets.fromLTRB(12, h * topInset, 12, bottomInset);
  }

  static double giftSizeFor(BoxConstraints constraints) {
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;
    if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) return 220;
    return min(w * 0.88, h * 0.92);
  }
}

/// Büyük hediye — yalnızca sol üstte gönderen → alıcı etiketi.
class GiftStageLargeDisplay extends StatelessWidget {
  const GiftStageLargeDisplay({
    super.key,
    required this.event,
    required this.giftSize,
    this.showBackdrop = false,
    this.preferFastVisual = false,
  });

  final LiveGiftEvent event;
  final double giftSize;
  final bool showBackdrop;
  final bool preferFastVisual;

  String get _senderReceiverLabel {
    final sender = event.senderName.trim();
    final receiver = event.receiverName.trim();
    if (sender.isEmpty && receiver.isEmpty) return 'Hediye';
    if (receiver.isEmpty) return sender;
    if (sender.isEmpty) return receiver;
    return '$sender → $receiver';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (showBackdrop)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.28),
                    Colors.black.withValues(alpha: 0.08),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          left: 4,
          top: 4,
          right: 48,
          child: _SenderReceiverChip(label: _senderReceiverLabel),
        ),
        Center(
          child: preferFastVisual
              ? PremiumGiftIcon(
                  giftId: PremiumGiftCatalog2026.canonicalId(event.giftId) ??
                      event.giftId,
                  size: giftSize,
                )
              : GiftAnimationPlayer(
                  giftId: event.giftId,
                  event: event,
                  size: giftSize,
                  preferPremiumVisual: false,
                ),
        ),
      ],
    );
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

/// Sahne bandı — üst/alt inset ile konumlandırılmış hediye alanı.
class GiftStageBand extends StatelessWidget {
  const GiftStageBand({
    super.key,
    required this.stage,
    required this.child,
  });

  final GiftStageContext stage;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final pad = GiftStageMetrics.stagePadding(context, stage: stage);
    return Positioned(
      left: pad.left,
      right: pad.right,
      top: pad.top,
      bottom: pad.bottom,
      child: child,
    );
  }
}
