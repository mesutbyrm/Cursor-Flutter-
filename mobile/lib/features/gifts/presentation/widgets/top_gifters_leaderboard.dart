import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/widgets/user_avatar.dart';
import '../../domain/gift_leaderboard_entry.dart';

/// TikTok tarzı top gifters listesi.
class TopGiftersLeaderboard extends StatelessWidget {
  const TopGiftersLeaderboard({
    super.key,
    required this.entries,
    this.loading = false,
  });

  final List<GiftLeaderboardEntry> entries;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        height: 160,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppThemeColors.accentPink,
          ),
        ),
      );
    }

    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'Henüz hediye sıralaması yok',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.colors.onSurfaceMuted.withValues(alpha: 0.9)),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length.clamp(0, 10),
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final e = entries[i];
        return _LeaderRow(entry: e)
            .animate(delay: (40 * i).ms)
            .fadeIn(duration: 220.ms)
            .slideX(begin: 0.05, end: 0);
      },
    );
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({required this.entry});

  final GiftLeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final medal = switch (entry.rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '#${entry.rank}',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: entry.rank <= 3
              ? AppThemeColors.coinGold.withValues(alpha: 0.35)
              : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '$medal',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ),
          UserAvatar(url: entry.avatarUrl, radius: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${entry.giftCount} hediye',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.colors.onSurfaceMuted.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.monetization_on_rounded,
                size: 14,
                color: AppThemeColors.coinGold,
              ),
              const SizedBox(width: 4),
              Text(
                '${entry.totalCoins}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: AppThemeColors.coinGold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
