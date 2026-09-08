import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/site_animation_type.dart';
import '../site_animation_provider.dart';
import 'site_animation_card.dart';
import 'site_animation_seat_glow.dart';

/// Sesli oda site animation overlay — mevcut UI üzerine bindirilir.
class SiteAnimationOverlayHost extends ConsumerWidget {
  const SiteAnimationOverlayHost({
    super.key,
    required this.roomId,
    required this.child,
  });

  final String roomId;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (roomId.trim().isEmpty) return child;

    final anim = ref.watch(siteAnimationProvider(roomId));
    final notifier = ref.read(siteAnimationProvider(roomId).notifier);
    final active = anim.active;

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        child,
        if (anim.seatTransition != null)
          SiteAnimationSeatTransition(command: anim.seatTransition!),
        if (active != null &&
            active.layout.seatIndex != null &&
            (active.type == SiteAnimationType.micEnabled ||
                active.type == SiteAnimationType.micDisabled ||
                active.type == SiteAnimationType.seatRankGlow ||
                active.type == SiteAnimationType.hostSeat))
          SiteAnimationSeatRankGlow(command: active),
        if (active != null && active.type != SiteAnimationType.seatRankGlow)
          SiteAnimationCard(
            key: ValueKey(active.eventId),
            command: active,
            onFinished: () => notifier.onActiveFinished(active.eventId),
          ),
      ],
    );
  }
}
