import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/util/json_util.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../admin/presentation/widgets/admin_user_hub_launcher.dart';
import '../../../platform_social/presentation/widgets/platform_social_ui_kit.dart';
import '../../domain/entities/social_discovery_user.dart';

/// Tanış keşif — platform sosyal cam kart (beğen / geç).
class DiscoverySocialUserCard extends ConsumerWidget {
  const DiscoverySocialUserCard({
    super.key,
    required this.user,
    required this.onOpenProfile,
    required this.onLike,
    required this.onSkip,
    this.onReport,
  });

  final SocialDiscoveryUser user;
  final VoidCallback onOpenProfile;
  final VoidCallback onLike;
  final VoidCallback onSkip;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = user;
    final rawUser = u.raw['user'] is Map
        ? asJsonMap(u.raw['user'])
        : asJsonMap(u.raw);
    final age = pick(rawUser, ['age', 'userAge']);
    final online = pick(rawUser, ['isOnline', 'online']) == true;
    final interestsRaw = pick(rawUser, ['interests', 'tags', 'hobbies']);
    String? interestsLine;
    if (interestsRaw is List) {
      interestsLine = interestsRaw.take(3).map((e) => e.toString()).join(' · ');
    } else if (interestsRaw != null) {
      interestsLine = interestsRaw.toString();
    }

    final hubChild = Semantics(
      container: true,
      label: '${u.displayName} keşif kartı',
      child: PlatformSocialGlassCard(
        onTap: onOpenProfile,
        gradient: PlatformSocialPalette.heroGradient,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        PlatformSocialPalette.accent,
                        PlatformSocialPalette.accentSecondary,
                      ],
                    ),
                  ),
                  child: UserAvatar(url: u.avatarUrl, radius: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      if (u.username != null && u.username!.isNotEmpty)
                        Text(
                          '@${u.username}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: PlatformSocialPalette.textMuted,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (age is num)
                            PlatformSocialStatusPill(
                              label: '${age.round()} yaş',
                              icon: Icons.cake_outlined,
                            ),
                          if (u.distanceLabel != null)
                            PlatformSocialStatusPill(
                              label: u.distanceLabel!,
                              icon: Icons.near_me_rounded,
                              tone: PlatformSocialPillTone.accent,
                            ),
                          if (online)
                            const PlatformSocialStatusPill(
                              label: 'Çevrimiçi',
                              icon: Icons.circle,
                              tone: PlatformSocialPillTone.success,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (interestsLine != null && interestsLine.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                interestsLine,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: Colors.white70,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PlatformSocialCircleAction(
                  icon: Icons.close_rounded,
                  tone: PlatformSocialPillTone.danger,
                  onTap: onSkip,
                ),
                const SizedBox(width: 24),
                PlatformSocialCircleAction(
                  icon: Icons.favorite_rounded,
                  tone: PlatformSocialPillTone.accent,
                  onTap: onLike,
                ),
                if (onReport != null) ...[
                  const SizedBox(width: 24),
                  PlatformSocialCircleAction(
                    icon: Icons.flag_outlined,
                    onTap: onReport!,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
    if (u.id.isEmpty) return hubChild;
    return AdminUserHubLauncher.wrap(
      context: context,
      ref: ref,
      userId: u.id,
      onTap: onOpenProfile,
      child: hubChild,
    );
  }
}
