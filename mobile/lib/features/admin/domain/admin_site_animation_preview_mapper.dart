import '../../../../core/site_animation/domain/site_animation_asset.dart';
import '../../../../core/site_animation/domain/site_animation_command.dart';
import '../../../../core/site_animation/domain/site_animation_layout.dart';
import '../../../../core/site_animation/domain/site_animation_tier.dart';
import '../../../../core/site_animation/domain/site_animation_type.dart';
import 'admin_site_animation.dart';

/// Admin katalog kaydı → client preview komutu.
SiteAnimationCommand adminAnimationToPreviewCommand(
  AdminSiteAnimation anim, {
  String userName = 'Önizleme Kullanıcı',
  String roomId = 'preview-room',
}) {
  final tier = switch (anim.membership) {
    AdminSiteAnimationMembership.gold => SiteAnimationTier.gold,
    AdminSiteAnimationMembership.premium => SiteAnimationTier.premium,
    AdminSiteAnimationMembership.diamond => SiteAnimationTier.diamond,
    AdminSiteAnimationMembership.vip => SiteAnimationTier.vip,
    AdminSiteAnimationMembership.svip => SiteAnimationTier.svip,
    AdminSiteAnimationMembership.admin => SiteAnimationTier.admin,
    AdminSiteAnimationMembership.host => SiteAnimationTier.host,
    _ => SiteAnimationTier.normal,
  };

  final type = switch (anim.category) {
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

  final anchor = switch (anim.anchor) {
    AdminSiteAnimationAnchor.topCenter => SiteAnimationAnchor.topCenter,
    AdminSiteAnimationAnchor.seat => SiteAnimationAnchor.seat,
    AdminSiteAnimationAnchor.custom => SiteAnimationAnchor.custom,
    _ => SiteAnimationAnchor.topLeft,
  };

  return SiteAnimationCommand(
    eventId: 'preview:${anim.id}',
    roomId: roomId,
    type: type,
    tier: tier,
    userId: 'preview-user',
    userName: userName,
    layout: SiteAnimationLayout(
      anchor: anchor,
      scale: anim.scale,
      durationMs: anim.durationMs,
      seatIndex: anim.anchor == AdminSiteAnimationAnchor.seat ? 2 : null,
    ),
    asset: SiteAnimationAsset(
      url: anim.assetUrl,
      kind: anim.animationType == 'lottie'
          ? SiteAnimationMediaKind.lottie
          : SiteAnimationMediaKind.native,
      previewMp4Key: anim.previewMp4Key,
    ),
  );
}
