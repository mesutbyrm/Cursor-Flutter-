import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../core/widgets/messages_notifications_actions.dart';
import '../../../../../core/widgets/user_avatar.dart';
import '../profile_screen_state.dart';
import '../profile_theme.dart';

/// Kapak, avatar rozetleri, üst aksiyonlar ve isim bloğu.
class ProfileHeader extends ConsumerWidget {
  const ProfileHeader({
    super.key,
    required this.state,
    this.onEdit,
    this.onAvatarTap,
    this.onLogout,
  });

  final ProfileScreenState state;
  final VoidCallback? onEdit;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = state.user;
    final level = state.level.level;

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _CoverBanner(),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    const Spacer(),
                    const MessagesNotificationsActions(spacing: 6, iconSize: 40),
                    const SizedBox(width: 6),
                    _HeaderIcon(Icons.qr_code_2_rounded, () {
                      SharePlus.instance.share(
                        ShareParams(
                          text: 'https://canlifal.com/@${user.username}',
                          subject: '${user.display} — Canlifal',
                        ),
                      );
                    }),
                    const SizedBox(width: 6),
                    _HeaderIcon(Icons.ios_share_rounded, () {
                      SharePlus.instance.share(
                        ShareParams(text: 'https://canlifal.com/@${user.username}'),
                      );
                    }),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: -ProfilePremiumTheme.avatarSize * 0.52,
                child: Center(child: _AvatarWithBadges(
                  url: user.avatarUrl,
                  level: level,
                  isVip: state.isVip,
                  isBroadcaster: state.liveStreams > 0,
                  onTap: onAvatarTap ?? onEdit,
                )),
              ),
            ],
          ),
          SizedBox(height: ProfilePremiumTheme.avatarSize * 0.58),
          _NameBlock(
            displayName: user.display,
            username: user.username,
            bio: user.bio,
          ),
        ],
      ).animate().fadeIn(duration: 320.ms),
    );
  }
}

class _CoverBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'profile-cover',
      child: Container(
        height: ProfilePremiumTheme.coverHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ProfilePremiumTheme.radiusLg),
          gradient: ProfilePremiumTheme.coverGradient,
          border: Border.all(color: ProfilePremiumTheme.glassBorder),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -20,
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 120,
                color: ProfilePremiumTheme.neonPurple.withValues(alpha: 0.15),
              ),
            ),
            const Positioned(
              left: 20,
              bottom: 18,
              child: Text(
                'Canlifal',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarWithBadges extends StatelessWidget {
  const _AvatarWithBadges({
    required this.url,
    required this.level,
    required this.isVip,
    required this.isBroadcaster,
    this.onTap,
  });

  final String? url;
  final int level;
  final bool isVip;
  final bool isBroadcaster;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [ProfilePremiumTheme.neonPink, ProfilePremiumTheme.neonPurple],
              ),
              boxShadow: [
                BoxShadow(
                  color: ProfilePremiumTheme.neonPurple.withValues(alpha: 0.45),
                  blurRadius: 28,
                ),
              ],
            ),
            child: UserAvatar(url: url, radius: ProfilePremiumTheme.avatarSize / 2),
          ),
          Positioned(
            right: 4,
            bottom: 6,
            child: _BadgeDot(Icons.verified_rounded, Colors.cyanAccent),
          ),
          Positioned(
            left: -4,
            bottom: 12,
            child: _BadgePill('Lv.$level', ProfilePremiumTheme.neonPurple),
          ),
          Positioned(
            right: -6,
            top: 8,
            child: _BadgeDot(Icons.circle, const Color(0xFF00E676), size: 14),
          ),
          if (isBroadcaster)
            Positioned(
              left: 8,
              top: 0,
              child: _BadgePill('YAYIN', ProfilePremiumTheme.neonPink),
            ),
          if (isVip)
            Positioned(
              right: -2,
              top: -2,
              child: _BadgePill('VIP', const Color(0xFFFFD54F)),
            ),
        ],
      ),
    );
  }
}

class _BadgeDot extends StatelessWidget {
  const _BadgeDot(this.icon, this.color, {this.size = 22});
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ProfilePremiumTheme.deepBg,
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.8)),
      ),
      child: Icon(icon, size: size - 8, color: color),
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _NameBlock extends StatelessWidget {
  const _NameBlock({
    required this.displayName,
    required this.username,
    this.bio,
  });

  final String displayName;
  final String username;
  final String? bio;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(
            displayName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '@$username',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          if (bio != null && bio!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              bio!,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                height: 1.35,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Türkiye · Canlifal üyesi',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon(this.icon, this.onTap);
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
