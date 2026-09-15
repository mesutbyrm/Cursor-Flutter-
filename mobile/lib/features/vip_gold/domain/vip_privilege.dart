import 'package:flutter/material.dart';

import '../../../core/membership/membership_capabilities.dart';
import '../../../core/membership/membership_capability_keys.dart';
import 'vip_tier.dart';

/// Tek ayrıcalık kartı — site üyelik tablosu ile uyumlu.
class VipPrivilege {
  const VipPrivilege({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.minTier,
    this.capabilityKey,
    this.unlocked = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VipTier minTier;
  final String? capabilityKey;
  final bool unlocked;
}

abstract final class VipPrivilegeCatalog {
  static const all = [
    VipPrivilege(
      icon: Icons.military_tech_rounded,
      title: 'Özel Rozet',
      subtitle: 'Profilde Gold/SVIP rozeti',
      minTier: VipTier.basic,
    ),
    VipPrivilege(
      icon: Icons.block_rounded,
      title: 'Reklamsız Deneyim',
      subtitle: 'Gold ve üzeri reklamsız kullanım',
      minTier: VipTier.gold,
      capabilityKey: MembershipCapabilityKeys.adFree,
    ),
    VipPrivilege(
      icon: Icons.account_circle_rounded,
      title: 'Premium Çerçeve',
      subtitle: 'Avatar altın halka',
      minTier: VipTier.gold,
      capabilityKey: MembershipCapabilityKeys.profileFrame,
    ),
    VipPrivilege(
      icon: Icons.flight_takeoff_rounded,
      title: 'Giriş Animasyonu',
      subtitle: 'Odaya özel giriş FX',
      minTier: VipTier.gold,
      capabilityKey: MembershipCapabilityKeys.entranceEffect,
    ),
    VipPrivilege(
      icon: Icons.meeting_room_rounded,
      title: 'VIP Odalar',
      subtitle: 'Diamond ve üzeri VIP odalar',
      minTier: VipTier.diamond,
      capabilityKey: MembershipCapabilityKeys.vipRooms,
    ),
    VipPrivilege(
      icon: Icons.live_tv_rounded,
      title: 'Canlı Yayın Önceliği',
      subtitle: 'Keşfet ve listede öne çıkma',
      minTier: VipTier.gold,
      capabilityKey: MembershipCapabilityKeys.discoveryPriority,
    ),
    VipPrivilege(
      icon: Icons.headset_mic_rounded,
      title: 'Sesli Oda Önceliği',
      subtitle: 'Oda listesinde üst sıra',
      minTier: VipTier.gold,
      capabilityKey: MembershipCapabilityKeys.discoveryPriority,
    ),
    VipPrivilege(
      icon: Icons.lock_rounded,
      title: 'Şifreli Odalar',
      subtitle: 'Özel davet kodu',
      minTier: VipTier.premium,
      capabilityKey: MembershipCapabilityKeys.hiddenRoomEntry,
    ),
    VipPrivilege(
      icon: Icons.chat_bubble_rounded,
      title: 'Özel Sohbet Balonları',
      subtitle: 'Premium sohbet stili',
      minTier: VipTier.premium,
      capabilityKey: MembershipCapabilityKeys.messageBubble,
    ),
    VipPrivilege(
      icon: Icons.card_giftcard_rounded,
      title: 'Özel Hediyeler',
      subtitle: 'Üyelik hediye paketleri',
      minTier: VipTier.premium,
    ),
    VipPrivilege(
      icon: Icons.sports_martial_arts_rounded,
      title: 'PK Avantajı',
      subtitle: 'PK savaşlarında bonus',
      minTier: VipTier.premium,
    ),
    VipPrivilege(
      icon: Icons.auto_awesome_rounded,
      title: 'Neon Efektler',
      subtitle: 'Diamond sohbet efektleri',
      minTier: VipTier.diamond,
      capabilityKey: MembershipCapabilityKeys.nameEffect,
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
          capabilityKey: p.capabilityKey,
          unlocked: tier.isAtLeast(p.minTier),
        ),
    ];
  }

  static List<VipPrivilege> forCapabilities(MembershipCapabilities caps) {
    return [
      for (final p in all)
        VipPrivilege(
          icon: p.icon,
          title: p.title,
          subtitle: p.subtitle,
          minTier: p.minTier,
          capabilityKey: p.capabilityKey,
          unlocked: p.capabilityKey != null
              ? caps.allows(p.capabilityKey!)
              : caps.effectiveTier.isAtLeast(p.minTier),
        ),
    ];
  }
}
