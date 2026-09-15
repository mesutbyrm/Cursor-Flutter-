import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../admin/presentation/widgets/admin_user_hub_launcher.dart';
import '../../../platform_social/presentation/widgets/platform_social_ui_kit.dart';
import '../../domain/entities/social_discovery_user.dart';
import '../../../vip_gold/presentation/widgets/vip_badge.dart';
import '../../../vip_gold/domain/vip_tier.dart';

/// Tam ekran swipe kartı — Canlifal cam / gradient dilinde.
class DiscoveryDatingProfileCard extends ConsumerWidget {
  const DiscoveryDatingProfileCard({
    super.key,
    required this.user,
    required this.onOpenProfile,
    this.dragProgress = 0,
  });

  final SocialDiscoveryUser user;
  final VoidCallback onOpenProfile;
  final double dragProgress;

  VipTier? _membershipTier(String? membership) {
    final m = membership?.toLowerCase() ?? '';
    if (m.contains('svip')) return VipTier.svip;
    if (m.contains('gold') || m.contains('vip')) return VipTier.gold;
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tier = _membershipTier(user.membership);
    final mediaUrl = user.coverMediaUrl;
    final bio = user.bio?.trim();
    final hobbies = user.hobbies;

    final card = ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: AspectRatio(
        aspectRatio: 3 / 4.2,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (mediaUrl != null && mediaUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: mediaUrl,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  color: PlatformSocialPalette.card,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, _, _) => Container(
                  color: PlatformSocialPalette.card,
                  child: const Icon(Icons.person_rounded, size: 72),
                ),
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: PlatformSocialPalette.heroGradient,
                ),
                child: const Icon(Icons.person_rounded, size: 72, color: Colors.white38),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.82),
                  ],
                  stops: const [0, 0.45, 1],
                ),
              ),
            ),
            if (dragProgress.abs() > 0.05)
              Positioned(
                top: 24,
                left: dragProgress > 0 ? 20 : null,
                right: dragProgress < 0 ? 20 : null,
                child: _SwipeLabel(like: dragProgress > 0),
              ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 26,
                          ),
                        ),
                      ),
                      if (tier != null) VipBadge(tier: tier, compact: true),
                    ],
                  ),
                  if (user.username != null && user.username!.isNotEmpty)
                    Text(
                      '@${user.username}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (user.age != null)
                        PlatformSocialStatusPill(
                          label: '${user.age} yaş',
                          icon: Icons.cake_outlined,
                        ),
                      if (user.city != null && user.city!.isNotEmpty)
                        PlatformSocialStatusPill(
                          label: user.city!,
                          icon: Icons.place_outlined,
                        ),
                      if (user.distanceLabel != null)
                        PlatformSocialStatusPill(
                          label: user.distanceLabel!,
                          icon: Icons.near_me_rounded,
                          tone: PlatformSocialPillTone.accent,
                        ),
                      if (user.isOnline)
                        const PlatformSocialStatusPill(
                          label: 'Çevrimiçi',
                          icon: Icons.circle,
                          tone: PlatformSocialPillTone.success,
                        ),
                    ],
                  ),
                  if (bio != null && bio.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      bio,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ],
                  if (hobbies.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      hobbies.take(4).join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(onTap: onOpenProfile),
              ),
            ),
          ],
        ),
      ),
    );

    if (user.id.isEmpty) return card;
    return AdminUserHubLauncher.wrap(
      context: context,
      ref: ref,
      userId: user.id,
      onTap: onOpenProfile,
      child: card,
    );
  }
}

class _SwipeLabel extends StatelessWidget {
  const _SwipeLabel({required this.like});

  final bool like;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: like ? -0.2 : 0.2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: like ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
            width: 3,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          like ? 'BEĞEN' : 'GEÇ',
          style: TextStyle(
            color: like ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}
