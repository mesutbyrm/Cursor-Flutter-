import 'site_animation_layout.dart';
import 'site_animation_tier.dart';

/// Runtime katalog kaydı — admin/API kaynağından senkronize edilir.
class SiteAnimationCatalogEntry {
  const SiteAnimationCatalogEntry({
    required this.id,
    required this.name,
    required this.category,
    required this.tier,
    this.animationType = 'native',
    this.assetUrl,
    this.previewMp4Key,
    this.durationMs = 3000,
    this.priority = 50,
    this.anchor = SiteAnimationAnchor.topLeft,
    this.scale = 1,
    this.isActive = true,
    this.description,
  });

  final String id;
  final String name;
  final String category;
  final SiteAnimationTier tier;
  final String animationType;
  final String? assetUrl;
  final String? previewMp4Key;
  final int durationMs;
  final int priority;
  final SiteAnimationAnchor anchor;
  final double scale;
  final bool isActive;
  final String? description;
}

class SiteAnimationUserAssignment {
  const SiteAnimationUserAssignment({
    required this.animationId,
    this.expiresAt,
  });

  final String animationId;
  final DateTime? expiresAt;

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

/// Aktif animasyon kataloğu + varsayılanlar + kullanıcı atamaları.
class SiteAnimationCatalogSnapshot {
  const SiteAnimationCatalogSnapshot({
    this.animations = const {},
    this.entranceDefaults = const {},
    this.exitDefaults = const {},
    this.userAssignments = const {},
  });

  final Map<String, SiteAnimationCatalogEntry> animations;
  final Map<SiteAnimationTier, String> entranceDefaults;
  final Map<SiteAnimationTier, String> exitDefaults;
  final Map<String, Map<SiteAnimationSlot, SiteAnimationUserAssignment>>
      userAssignments;

  SiteAnimationCatalogEntry? byId(String? id) {
    if (id == null || id.isEmpty) return null;
    return animations[id];
  }

  SiteAnimationCatalogSnapshot copyWith({
    Map<String, SiteAnimationCatalogEntry>? animations,
    Map<SiteAnimationTier, String>? entranceDefaults,
    Map<SiteAnimationTier, String>? exitDefaults,
    Map<String, Map<SiteAnimationSlot, SiteAnimationUserAssignment>>?
        userAssignments,
  }) {
    return SiteAnimationCatalogSnapshot(
      animations: animations ?? this.animations,
      entranceDefaults: entranceDefaults ?? this.entranceDefaults,
      exitDefaults: exitDefaults ?? this.exitDefaults,
      userAssignments: userAssignments ?? this.userAssignments,
    );
  }
}
