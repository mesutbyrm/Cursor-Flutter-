import 'package:flutter/material.dart';

import '../../../domain/entities/live_broadcast_session.dart';
import '../../providers/live_room_interaction_provider.dart';
import '../premium_2026/live_premium_2026.dart';

/// Canlı izleyici yan rail — beğeni + fal CTA.
class LiveBroadcastRoomViewerRail extends StatelessWidget {
  const LiveBroadcastRoomViewerRail({
    super.key,
    required this.session,
    required this.interaction,
    required this.likeLabel,
    required this.onLike,
    required this.showFortune,
    required this.fortuneLabel,
    this.onFortune,
  });

  final LiveBroadcastSession session;
  final LiveRoomInteractionState interaction;
  final String likeLabel;
  final VoidCallback onLike;
  final bool showFortune;
  final String fortuneLabel;
  final VoidCallback? onFortune;

  @override
  Widget build(BuildContext context) {
    return LiveMockupSideRail(
      likeLabel: likeLabel,
      onLike: onLike,
      showFortune: showFortune && !session.isHost,
      fortuneLabel: fortuneLabel,
      onFortune: onFortune,
    );
  }
}

String formatLiveLikeRailLabel(LiveRoomInteractionState interaction) {
  final total = _fmtLikes(interaction.likeCount);
  final mine = interaction.myLikeCount;
  if (mine <= 0) return total;
  return '$total\nSen: $mine';
}

String _fmtLikes(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}
