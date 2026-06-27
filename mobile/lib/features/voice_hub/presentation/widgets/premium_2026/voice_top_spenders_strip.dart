import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../gifts/domain/gift_leaderboard_entry.dart';
import '../../providers/voice_gift_leaderboard_provider.dart';
import '../../theme/voice_room_tokens.dart';

/// Oturum içi top 3 hediye gönderen — `voiceSessionGiftLeaderboardProvider`.
class VoiceTopSpendersStrip extends ConsumerWidget {
  const VoiceTopSpendersStrip({super.key, this.maxVisible = 3});

  final int maxVisible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaders = ref.watch(voiceSessionGiftLeaderboardProvider);
    if (leaders.isEmpty) return const SizedBox.shrink();

    final top = leaders.take(maxVisible).toList();
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                size: 16,
                color: VoiceRoomTokens.gold,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var i = 0; i < top.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        _SpenderChip(entry: top[i], rank: i + 1),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpenderChip extends StatelessWidget {
  const _SpenderChip({required this.entry, required this.rank});

  final GiftLeaderboardEntry entry;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final name = entry.displayName.trim().isNotEmpty
        ? entry.displayName
        : 'Kullanıcı';
    final coins = entry.totalCoins;
    final avatar = entry.avatarUrl;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$rank',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: rank == 1
                  ? VoiceRoomTokens.gold
                  : Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 6),
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.white12,
            backgroundImage:
                avatar != null && avatar.isNotEmpty ? canlifalImageProvider(avatar) : null,
            child: avatar == null || avatar.isEmpty
                ? Text(name.characters.first.toUpperCase(),
                    style: const TextStyle(fontSize: 10))
                : null,
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _formatCoins(coins),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: VoiceRoomTokens.gold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCoins(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
