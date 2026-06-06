import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../../core/ui/premium/live_badge.dart';
import '../../../../../../core/widgets/user_avatar.dart';
import '../../../../domain/entities/live_broadcast_session.dart';

/// TikTok tarzı üst bar — blur, takip, izleyici, neon.
class LivePremiumTopBar extends StatelessWidget {
  const LivePremiumTopBar({
    super.key,
    required this.session,
    required this.time,
    required this.following,
    required this.followLoading,
    required this.onFollow,
    required this.onClose,
    this.onBack,
    this.onProfileTap,
  });

  final LiveBroadcastSession session;
  final String time;
  final bool following;
  final bool followLoading;
  final VoidCallback onFollow;
  final VoidCallback onClose;
  final VoidCallback? onBack;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final viewers = session.viewerCount;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppThemeColors.accentPink.withValues(alpha: 0.35)),
            boxShadow: AppThemeColors.glowShadow(AppThemeColors.accentPurple, blur: 14),
          ),
          child: Row(
            children: [
              if (onBack != null)
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              GestureDetector(
                onTap: onProfileTap,
                child: UserAvatar(url: session.avatarUrl, radius: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.streamerName ?? 'Yayıncı',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.colors.onSurfaceMuted.withValues(alpha: 0.95),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (!session.isHost && !following)
                _FollowButton(loading: followLoading, onTap: onFollow),
              if (following && !session.isHost)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Takipte',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
              const SizedBox(width: 8),
              const LiveBadge(compact: true),
              const SizedBox(width: 6),
              _StatPill(icon: Icons.visibility_rounded, label: _fmt(viewers)),
              const SizedBox(width: 4),
              _StatPill(icon: Icons.schedule_rounded, label: time),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: -0.15, end: 0);
  }

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            gradient: context.colors.brandGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppThemeColors.glowShadow(AppThemeColors.accentPink, blur: 12),
          ),
          child: loading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text(
                  '+ Takip',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
