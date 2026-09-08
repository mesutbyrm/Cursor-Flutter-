import '../../../core/site_animation/data/site_animation_resolver.dart';
import '../../../core/site_animation/domain/site_animation_catalog_entry.dart';
import '../../../core/site_animation/domain/site_animation_command.dart';
import '../../../core/site_animation/domain/site_animation_layout.dart';
import '../../../core/site_animation/domain/site_animation_tier.dart';
import '../../../core/site_animation/domain/site_animation_type.dart';
import 'admin_site_animation.dart';

SiteAnimationTier _tier(AdminSiteAnimationMembership membership) =>
    switch (membership) {
      AdminSiteAnimationMembership.gold => SiteAnimationTier.gold,
      AdminSiteAnimationMembership.premium => SiteAnimationTier.premium,
      AdminSiteAnimationMembership.diamond => SiteAnimationTier.diamond,
      AdminSiteAnimationMembership.vip => SiteAnimationTier.vip,
      AdminSiteAnimationMembership.svip => SiteAnimationTier.svip,
      AdminSiteAnimationMembership.admin => SiteAnimationTier.admin,
      AdminSiteAnimationMembership.host => SiteAnimationTier.host,
      _ => SiteAnimationTier.normal,
    };

SiteAnimationType _type(AdminSiteAnimation anim) => switch (anim.category) {
      AdminSiteAnimationCategory.entrance => SiteAnimationType.memberJoined,
      AdminSiteAnimationCategory.exit => SiteAnimationType.memberLeft,
      AdminSiteAnimationCategory.transition => SiteAnimationType.seatChanged,
      AdminSiteAnimationCategory.seat => SiteAnimationType.seatRankGlow,
      AdminSiteAnimationCategory.mic when anim.name.contains('Kapat') =>
        SiteAnimationType.micDisabled,
      AdminSiteAnimationCategory.mic => SiteAnimationType.micEnabled,
      AdminSiteAnimationCategory.host => SiteAnimationType.hostSeat,
      _ => SiteAnimationType.memberJoined,
    };

SiteAnimationAnchor _anchor(AdminSiteAnimationAnchor anchor) =>
    switch (anchor) {
      AdminSiteAnimationAnchor.topCenter => SiteAnimationAnchor.topCenter,
      AdminSiteAnimationAnchor.seat => SiteAnimationAnchor.seat,
      AdminSiteAnimationAnchor.custom => SiteAnimationAnchor.custom,
      _ => SiteAnimationAnchor.topLeft,
    };

SiteAnimationCatalogEntry _catalogEntry(AdminSiteAnimation anim) {
  return SiteAnimationCatalogEntry(
    id: anim.id,
    name: anim.name,
    category: anim.category.name,
    tier: _tier(anim.membership),
    animationType: anim.animationType,
    assetUrl: anim.assetUrl,
    previewMp4Key: anim.previewMp4Key,
    durationMs: anim.durationMs,
    priority: anim.priority,
    anchor: _anchor(anim.anchor),
    scale: anim.scale,
    isActive: anim.isActive,
    description: anim.description,
    soundUrl: anim.soundUrl,
    cooldownMs: anim.cooldownMs,
  );
}

/// Admin katalog kaydı → production-parity preview komutu (asset + ses + CDN).
SiteAnimationCommand adminAnimationToPreviewCommand(
  AdminSiteAnimation anim, {
  String userName = 'Önizleme Kullanıcı',
  String roomId = 'preview-room',
}) {
  final isTransition = anim.category == AdminSiteAnimationCategory.transition;
  final isSeat = anim.anchor == AdminSiteAnimationAnchor.seat ||
      anim.category == AdminSiteAnimationCategory.seat;

  final base = SiteAnimationCommand(
    eventId: 'preview:${anim.id}',
    roomId: roomId,
    type: _type(anim),
    tier: _tier(anim.membership),
    userId: 'preview-user',
    userName: userName,
    animationId: anim.id,
    layout: SiteAnimationLayout(
      anchor: _anchor(anim.anchor),
      scale: anim.scale,
      durationMs: anim.durationMs,
      seatIndex: isSeat ? 2 : null,
      fromSeatIndex: isTransition ? 1 : null,
    ),
  );

  return SiteAnimationResolver.applyCatalogEntry(base, _catalogEntry(anim));
}
