/// VIP / Gold üyelik kademeleri.
enum VipTier {
  basic,
  premium,
  gold,
  diamond,
  svip;

  static VipTier fromMembership(String? raw) {
    final k = raw?.toLowerCase().trim() ?? '';
    return switch (k) {
      'svip' || 'super_vip' => VipTier.svip,
      'diamond' => VipTier.diamond,
      'gold' => VipTier.gold,
      'premium' => VipTier.premium,
      _ => VipTier.basic,
    };
  }

  bool get isVip => index >= VipTier.gold.index;

  bool get hasEntranceFx => index >= VipTier.gold.index;

  bool get hasPremiumFrame => index >= VipTier.premium.index;

  String get label => switch (this) {
        VipTier.basic => 'Üye',
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
