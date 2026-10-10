import 'package:flutter/material.dart';

import '../../../../core/visual/premium/premium_asset_paths.dart';
import '../../../../core/visual/premium/premium_glass_image.dart';

/// Üyelik kademesine özel kapak illüstrasyonu (`assets/membership/<id>.webp`).
/// Kademe değişince yumuşak geçiş yapar; dosya yoksa [fallback] gösterilir.
class MembershipTierArt extends StatelessWidget {
  const MembershipTierArt({
    super.key,
    required this.tierId,
    this.height = 180,
    this.radius = 24,
    this.title,
    this.subtitle,
    this.glow = const Color(0xFFFFC107),
    this.fallback,
  });

  static const knownTiers = {'basic', 'gold', 'premium', 'diamond', 'svip'};

  final String tierId;
  final double height;
  final double radius;
  final String? title;
  final String? subtitle;
  final Color glow;
  final Widget? fallback;

  static String? assetFor(String tierId) {
    final id = tierId.trim().toLowerCase();
    return knownTiers.contains(id) ? PremiumAssetPaths.membership(id) : null;
  }

  static String? legacyAssetFor(String tierId) {
    final id = tierId.trim().toLowerCase();
    return knownTiers.contains(id) ? PremiumAssetPaths.legacyMembership(id) : null;
  }

  @override
  Widget build(BuildContext context) {
    final asset = assetFor(tierId);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Semantics(
      image: true,
      label: title == null ? 'Üyelik kademesi' : '$title üyelik görseli',
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: glow.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(
              color: glow.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - 1),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOut,
                child: asset == null
                    ? (fallback ?? const SizedBox.shrink(key: ValueKey('none')))
                    : PremiumGlassImage(
                        key: ValueKey(asset),
                        assetPath: asset,
                        fallbackAssetPath: legacyAssetFor(tierId),
                        borderRadius: radius - 1,
                        glowColor: glow,
                        cacheWidth: (420 * dpr).round().clamp(320, 1000),
                        fit: BoxFit.cover,
                        fallbackIcon: Icons.workspace_premium_rounded,
                      ),
              ),
              if (title != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0xCC000000)],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xCCFFFFFF),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
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
