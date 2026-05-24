import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../theme/voice_room_tokens.dart';

/// Üst bar — yayıncı profili en üstte, tek satır kompakt.
class VoiceLiveHeader2026 extends StatelessWidget {
  const VoiceLiveHeader2026({
    super.key,
    required this.room,
    required this.onlineCount,
    required this.coinBalance,
    required this.onBack,
    required this.onExit,
    this.onFollow,
    this.onShare,
    this.onAudience,
    this.onMore,
    this.onCoinsTap,
    this.hostAvatarUrl,
    this.following = false,
  });

  final VoiceRoomEntity room;
  final int onlineCount;
  final int coinBalance;
  final VoidCallback onBack;
  final VoidCallback onExit;
  final VoidCallback? onFollow;
  final VoidCallback? onShare;
  final VoidCallback? onAudience;
  final VoidCallback? onMore;
  final VoidCallback? onCoinsTap;
  final String? hostAvatarUrl;
  final bool following;

  @override
  Widget build(BuildContext context) {
    final shortId = room.apiRoomKey.length > 8
        ? room.apiRoomKey.substring(0, 8)
        : room.apiRoomKey;
    final onlineLabel = _formatCount(onlineCount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
              GestureDetector(
                onTap: onAudience,
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white12,
                  backgroundImage: hostAvatarUrl != null && hostAvatarUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(hostAvatarUrl!)
                      : null,
                  child: hostAvatarUrl == null || hostAvatarUrl!.isEmpty
                      ? Text(room.icon ?? '🎤', style: const TextStyle(fontSize: 20))
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => Clipboard.setData(ClipboardData(text: room.apiRoomKey)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'ID $shortId · $onlineLabel çevrimiçi',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: onlineCount > 0
                              ? AppColors.onlineGreen
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (onFollow != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _miniFollow(),
                ),
              GestureDetector(
                onTap: onCoinsTap,
                child: _coinPill(),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onMore ?? onShare,
                icon: const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 22),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onExit,
                icon: const Icon(Icons.power_settings_new_rounded,
                    color: AppColors.liveRed, size: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniFollow() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onFollow,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: following ? null : VoiceRoomTokens.followGradient,
            color: following ? Colors.white12 : null,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            following ? '✓' : 'Takip',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }

  Widget _coinPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.diamondBlue.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💎', style: TextStyle(fontSize: 11)),
          const SizedBox(width: 3),
          Text(
            _formatCount(coinBalance),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 10,
              color: AppColors.diamondBlue,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
