import '../domain/site_animation_catalog_entry.dart';
import '../domain/site_animation_slot.dart';
import '../domain/site_animation_tier.dart';

/// Profil çerçevesi / avatar efekti — katalog + admin ataması.
abstract final class SiteAnimationProfileResolver {
  static SiteAnimationCatalogEntry? resolveFrame({
    required String userId,
    required SiteAnimationTier tier,
    required SiteAnimationCatalogSnapshot catalog,
  }) {
    return _resolve(
      userId: userId,
      tier: tier,
      catalog: catalog,
      slot: SiteAnimationSlot.profileFrame,
      category: 'profileFrame',
    );
  }

  static SiteAnimationCatalogEntry? resolveAvatarEffect({
    required String userId,
    required SiteAnimationTier tier,
    required SiteAnimationCatalogSnapshot catalog,
  }) {
    return _resolve(
      userId: userId,
      tier: tier,
      catalog: catalog,
      slot: SiteAnimationSlot.avatar,
      category: 'avatarEffect',
    );
  }

  static SiteAnimationCatalogEntry? _resolve({
    required String userId,
    required SiteAnimationTier tier,
    required SiteAnimationCatalogSnapshot catalog,
    required SiteAnimationSlot slot,
    required String category,
  }) {
    final assignment = catalog.userAssignments[userId]?[slot];
    if (assignment != null &&
        !assignment.isExpired &&
        assignment.animationId.isNotEmpty) {
      final assigned = catalog.byId(assignment.animationId);
      if (assigned != null && assigned.isActive) return assigned;
    }

    SiteAnimationCatalogEntry? tierMatch;
    SiteAnimationCatalogEntry? fallback;
    for (final entry in catalog.animations.values) {
      if (!entry.isActive || entry.category != category) continue;
      fallback ??= entry;
      if (entry.tier == tier) {
        tierMatch = entry;
        break;
      }
    }
    return tierMatch ?? fallback;
  }
}
