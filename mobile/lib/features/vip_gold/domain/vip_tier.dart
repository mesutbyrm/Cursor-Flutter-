/// VIP üyelik kademeleri — sıra: Basic < Gold < Premium < Diamond < SVIP.
enum VipTier {
  basic,
  gold,
  premium,
  diamond,
  svip;

  /// Karşılaştırma ve yetki için tek kaynak (enum sırasına güvenilmez).
  int get rank => switch (this) {
        VipTier.basic => 0,
        VipTier.gold => 1,
        VipTier.premium => 2,
        VipTier.diamond => 3,
        VipTier.svip => 4,
      };

  bool isAtLeast(VipTier minimum) => rank >= minimum.rank;

  static VipTier fromMembership(String? raw) {
    final k = raw?.toLowerCase().trim() ?? '';
    return switch (k) {
      'svip' || 'super_vip' => VipTier.svip,
      'diamond' => VipTier.diamond,
      'premium' => VipTier.premium,
      'gold' || 'vip' => VipTier.gold,
      'basic' || 'free' || '' => VipTier.basic,
      _ => VipTier.basic,
    };
  }

  bool get isVip => isAtLeast(VipTier.gold);

  bool get hasEntranceFx => isAtLeast(VipTier.gold);

  bool get hasPremiumFrame => isAtLeast(VipTier.premium);

  String get label => switch (this) {
        VipTier.basic => 'Basic',
        VipTier.premium => 'Premium',
        VipTier.gold => 'Gold',
        VipTier.diamond => 'Diamond',
        VipTier.svip => 'SVIP',
      };

  String get badgeShort => switch (this) {
        VipTier.basic => '',
        VipTier.premium => 'PRO',
        VipTier.gold => 'GOLD',
        VipTier.diamond => 'VIP',
        VipTier.svip => 'SVIP',
      };
}
