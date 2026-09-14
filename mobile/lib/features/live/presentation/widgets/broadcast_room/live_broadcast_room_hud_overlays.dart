import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../games/domain/game_models.dart';
import '../../../../gifts/presentation/widgets/gift_goal_bar.dart';
import '../../providers/live_host_rank_provider.dart';
import '../pk/pk_room_live_section.dart';
import '../premium_2026/live/live_mockup_side_widgets.dart';
import 'live_broadcast_room_chips.dart';
import 'music_video_player.dart';

/// Yayın HUD: müzik, hediye hedefi, turnuva, beğeni, PK bölümü.
class LiveBroadcastRoomHudOverlays extends ConsumerWidget {
  const LiveBroadcastRoomHudOverlays({
    super.key,
    required this.hasStream,
    required this.streamId,
    required this.topInset,
    required this.myUserId,
    required this.userLikeCounts,
    required this.onTournamentTap,
    required this.hostRank,
    required this.tournamentsAsync,
  });

  final bool hasStream;
  final String streamId;
  final double topInset;
  final String myUserId;
  final Map<String, int> userLikeCounts;
  final VoidCallback onTournamentTap;
  final LiveHostRankInfo? hostRank;
  final AsyncValue<List<GameScoreItem>> tournamentsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!hasStream) return const SizedBox.shrink();

    final tournamentRank = tournamentsAsync.valueOrNull?.isNotEmpty == true
        ? (tournamentsAsync.valueOrNull!.first.rank ?? 3)
        : null;

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 12,
          right: 12,
          bottom: 300,
          child: MusicVideoPlayer(streamId: streamId),
        ),
        Positioned(
          left: 12,
          top: topInset + 108,
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width * 0.42,
            child: GiftGoalBar(
              context: 'live_stream',
              contextId: streamId,
            ),
          ),
        ),
        if (tournamentsAsync.valueOrNull?.isNotEmpty == true)
          Positioned(
            right: 12,
            top: topInset + 108,
            child: LiveStarTournamentCard(
              rank: tournamentRank ?? hostRank?.popularRank ?? 3,
              onTap: onTournamentTap,
            ),
          ),
        if (userLikeCounts.isNotEmpty)
          Positioned(
            left: 12,
            bottom: 268,
            child: LiveBroadcastLikeContributorsChip(
              counts: userLikeCounts,
            ),
          ),
        Positioned(
          left: 12,
          bottom: 210,
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width * 0.55,
            child: PkRoomLiveSection(
              streamId: streamId,
              myUserId: myUserId,
            ),
          ),
        ),
      ],
    );
  }
}
