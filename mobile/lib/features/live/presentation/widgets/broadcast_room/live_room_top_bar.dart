import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

import '../../../../../core/ui/premium/live_badge.dart';
import '../../../../../core/ui/premium/premium_glass_surface.dart';
import '../../../../../core/widgets/user_avatar.dart';
import '../../../domain/entities/live_broadcast_session.dart';

class LiveRoomTopBar extends StatelessWidget {
  const LiveRoomTopBar({
    super.key,
    required this.session,
    required this.time,
    required this.following,
    required this.onFollow,
    required this.onClose,
  });

  final LiveBroadcastSession session;
  final String time;
  final bool following;
  final VoidCallback onFollow;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return PremiumGlassSurface(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      borderRadius: BorderRadius.circular(20),
      blur: 10,
      child: Row(
        children: [
          UserAvatar(url: session.avatarUrl, radius: 18),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.streamerName ?? 'Yayıncı',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '12.5K beğeni',
                  style: TextStyle(
                    color: context.colors.onSurfaceMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (!session.isHost && !following)
            Material(
              color: AppThemeColors.accentPink,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onFollow,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    '+ Takip Et',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          SizedBox(width: 8),
          const LiveBadge(compact: true),
          SizedBox(width: 6),
          Text(
            time,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          SizedBox(width: 8),
          Row(
            children: [
              Icon(Icons.visibility_rounded, size: 14),
              SizedBox(width: 4),
              Text(
                _formatViewers(
                  session.viewerCount > 0 ? session.viewerCount : 4892,
                ),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close_rounded, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  static String _formatViewers(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
