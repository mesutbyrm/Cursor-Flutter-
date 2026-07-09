import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

import '../../../../gifts/domain/gift_leaderboard_entry.dart';
import '../../providers/voice_gift_leaderboard_provider.dart';
import '../../theme/voice_room_tokens.dart';

/// Üst çevrimiçi kutusu — hediye atanlar öncelikli (çoktan aza), oturum boyunca.
class VoiceOnlineGiftBox extends ConsumerWidget {
  const VoiceOnlineGiftBox({
    super.key,
    required this.onlineCount,
    this.onTap,
    this.maxSpenders = 8,
  });

  final int onlineCount;
  final VoidCallback? onTap;
  final int maxSpenders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaders = ref.watch(voiceSessionGiftLeaderboardProvider);
    final spenders = leaders.take(maxSpenders).toList();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              constraints: const BoxConstraints(minWidth: 72, maxWidth: 220),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppThemeColors.onlineGreen.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people_alt_rounded,
                        size: 14,
                        color: onlineCount > 0
                            ? AppThemeColors.onlineGreen
                            : Colors.white54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$onlineCount çevrimiçi',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: onlineCount > 0
                              ? AppThemeColors.onlineGreen
                              : Colors.white54,
                        ),
                      ),
                    ],
                  ),
                  if (spenders.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    ...spenders.map((e) => _SpenderRow(entry: e)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpenderRow extends StatelessWidget {
  const _SpenderRow({required this.entry});

  final GiftLeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final name = entry.displayName.trim().isNotEmpty
        ? entry.displayName.trim()
        : 'Kullanıcı';
    final avatar = entry.avatarUrl;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Text(
            '#${entry.rank}',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: entry.rank == 1
                  ? VoiceRoomTokens.gold
                  : Colors.white.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(width: 4),
          CircleAvatar(
            radius: 8,
            backgroundColor: Colors.white12,
            backgroundImage: avatar != null && avatar.isNotEmpty
                ? canlifalImageProvider(avatar)
                : null,
            child: avatar == null || avatar.isEmpty
                ? Text(
                    name.characters.first.toUpperCase(),
                    style: const TextStyle(fontSize: 7),
                  )
                : null,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            _fmt(entry.totalCoins),
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: VoiceRoomTokens.gold,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
