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

  int get queuePriority => switch (this) {
        SiteAnimationTier.admin => 100,
        SiteAnimationTier.host => 95,
        SiteAnimationTier.diamond => 90,
        SiteAnimationTier.svip => 85,
        SiteAnimationTier.premium => 80,
        SiteAnimationTier.gold => 70,
        SiteAnimationTier.vip => 65,
        SiteAnimationTier.normal => 50,
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
