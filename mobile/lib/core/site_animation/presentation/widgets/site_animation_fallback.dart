import 'package:flutter/material.dart';

import '../../domain/site_animation_tier.dart';
import '../../domain/site_animation_type.dart';

/// Network / asset hatasında native premium kart fallback.
class SiteAnimationFallbackCard extends StatelessWidget {
  const SiteAnimationFallbackCard({
    super.key,
    required this.userName,
    required this.tier,
    required this.type,
    this.avatarUrl,
    this.subtitle,
  });

  final String userName;
  final SiteAnimationTier tier;
  final SiteAnimationType type;
  final String? avatarUrl;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = _gradient(tier);
    final label = subtitle ?? _label(type, tier);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            _Avatar(url: avatarUrl, tier: tier),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            _TierChip(tier: tier),
          ],
        ),
      ),
    );
  }

  static List<Color> _gradient(SiteAnimationTier tier) => switch (tier) {
        SiteAnimationTier.admin => [
            const Color(0xFF7F1D1D),
            const Color(0xFFFF5252),
          ],
        SiteAnimationTier.host => [
            const Color(0xFF4A148C),
            const Color(0xFFFFD54F),
          ],
        SiteAnimationTier.diamond => [
            const Color(0xFF0D47A1),
            const Color(0xFF7DF9FF),
          ],
        SiteAnimationTier.svip => [
            const Color(0xFF880E4F),
            const Color(0xFFFF6EC7),
          ],
        SiteAnimationTier.premium => [
            const Color(0xFF311B92),
            const Color(0xFFB388FF),
          ],
        SiteAnimationTier.gold => [
            const Color(0xFF4A148C),
            const Color(0xFFFFD54F),
          ],
        SiteAnimationTier.vip => [
            const Color(0xFF1B5E20),
            const Color(0xFF69F0AE),
          ],
        SiteAnimationTier.normal => [
            const Color(0xFF263238),
            const Color(0xFF546E7A),
          ],
      };

  static String _label(SiteAnimationType type, SiteAnimationTier tier) {
    return switch (type) {
      SiteAnimationType.memberJoined ||
      SiteAnimationType.hostSeat =>
        '${tier.name.toUpperCase()} üye odaya katıldı',
      SiteAnimationType.memberLeft => 'Odadan ayrıldı',
      SiteAnimationType.seatChanged => 'Koltuk değiştirdi',
      SiteAnimationType.micEnabled => 'Mikrofon açıldı',
      SiteAnimationType.micDisabled => 'Mikrofon kapatıldı',
      SiteAnimationType.seatRankGlow => 'Koltuk efekti',
    };
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.url, required this.tier});

  final String? url;
  final SiteAnimationTier tier;

  @override
  Widget build(BuildContext context) {
    final border = switch (tier) {
      SiteAnimationTier.gold ||
      SiteAnimationTier.premium ||
      SiteAnimationTier.diamond ||
      SiteAnimationTier.svip ||
      SiteAnimationTier.admin ||
      SiteAnimationTier.host =>
        Colors.amberAccent,
      _ => Colors.white54,
    };

    Widget child;
    final u = url?.trim();
    if (u != null && u.isNotEmpty) {
      child = CircleAvatar(radius: 18, backgroundImage: NetworkImage(u));
    } else {
      child = CircleAvatar(
        radius: 18,
        backgroundColor: Colors.white.withValues(alpha: 0.15),
        child: const Icon(Icons.person, color: Colors.white70, size: 20),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: border.withValues(alpha: 0.55), blurRadius: 8),
        ],
        border: Border.all(color: border, width: 1.5),
      ),
      child: child,
    );
  }
}

class _TierChip extends StatelessWidget {
  const _TierChip({required this.tier});

  final SiteAnimationTier tier;

  @override
  Widget build(BuildContext context) {
    if (tier == SiteAnimationTier.normal) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        tier.name.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
