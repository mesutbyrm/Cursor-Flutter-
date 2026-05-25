import 'package:flutter/material.dart';

import 'vip_tier.dart';

/// Tek ayrıcalık kartı — SVIP grid.
class VipPrivilege {
  const VipPrivilege({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.minTier,
    this.unlocked = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VipTier minTier;
  final bool unlocked;
}

abstract final class VipPrivilegeCatalog {
  static const all = [
    VipPrivilege(
      icon: Icons.military_tech_rounded,
      title: 'Özel Rozet',
      subtitle: 'Gold / SVIP rozeti',
      minTier: VipTier.gold,
    ),
    VipPrivilege(
      icon: Icons.account_circle_rounded,
      title: 'Premium Çerçeve',
      subtitle: 'Avatar altın halka',
      minTier: VipTier.premium,
    ),
    VipPrivilege(
      icon: Icons.flight_takeoff_rounded,
      title: 'Giriş Animasyonu',
      subtitle: 'Odaya özel giriş FX',
      minTier: VipTier.gold,
    ),
    VipPrivilege(
      icon: Icons.meeting_room_rounded,
      title: 'VIP Odalar',
      subtitle: 'Gold odalara erişim',
      minTier: VipTier.gold,
    ),
    VipPrivilege(
      icon: Icons.lock_rounded,
      title: 'Şifreli Odalar',
      subtitle: 'Özel davet kodu',
      minTier: VipTier.premium,
    ),
    VipPrivilege(
      icon: Icons.auto_awesome_rounded,
      title: 'Neon Efektler',
      subtitle: 'Özel sohbet stili',
      minTier: VipTier.diamond,
    ),
  ];

  static List<VipPrivilege> forTier(VipTier tier) {
    return [
      for (final p in all)
        VipPrivilege(
          icon: p.icon,
          title: p.title,
          subtitle: p.subtitle,
          minTier: p.minTier,
          unlocked: tier.index >= p.minTier.index,
        ),
    ];
  }
}
