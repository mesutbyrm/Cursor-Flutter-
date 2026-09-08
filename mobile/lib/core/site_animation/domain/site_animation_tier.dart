import '../../../features/vip_gold/domain/vip_tier.dart';
import '../../../core/auth/voice_staff_rank.dart';

/// Üyelik / yetki seviyesi — koltuk ve giriş animasyonları.
enum SiteAnimationTier {
  normal,
  gold,
  premium,
  diamond,
  vip,
  svip,
  admin,
  host;

  /// Spec priority: NORMAL=10 … EMPEROR=100, ADMIN_CUSTOM=110 (catalog override).
  int get queuePriority => switch (this) {
        SiteAnimationTier.normal => 10,
        SiteAnimationTier.gold => 30,
        SiteAnimationTier.premium => 40,
        SiteAnimationTier.diamond => 60,
        SiteAnimationTier.vip => 80,
        SiteAnimationTier.svip => 90,
        SiteAnimationTier.host => 95,
        SiteAnimationTier.admin => 100,
      };

  static SiteAnimationTier resolve({
    String? membership,
    VoiceStaffRank staffRank = VoiceStaffRank.none,
    bool isHost = false,
    bool isOwner = false,
  }) {
    if (isHost || isOwner) return SiteAnimationTier.host;
    if (staffRank == VoiceStaffRank.admin ||
        staffRank == VoiceStaffRank.founder) {
      return SiteAnimationTier.admin;
    }
    final vip = VipTier.fromMembership(membership);
    return switch (vip) {
      VipTier.svip => SiteAnimationTier.svip,
      VipTier.diamond => SiteAnimationTier.diamond,
      VipTier.premium => SiteAnimationTier.premium,
      VipTier.gold => SiteAnimationTier.gold,
      VipTier.basic => SiteAnimationTier.normal,
    };
  }
}
