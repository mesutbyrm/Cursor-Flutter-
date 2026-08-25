import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../admin/presentation/providers/staff_access_provider.dart';
import '../../domain/entrance_effect_settings.dart';
import '../../domain/vip_tier.dart';
import '../providers/entrance_effect_settings_provider.dart';
import '../providers/vip_membership_provider.dart';

/// Giriş efektinin oynatılıp oynatılmayacağı — üyelik + admin ayarları.
bool entranceEffectAllowed({
  required VipTier tier,
  required EntranceEffectSettings settings,
  required bool isStaff,
  bool hasCosmeticEntrance = false,
}) {
  if (hasCosmeticEntrance) return true;
  if (isStaff && settings.adminEnabled) return true;
  return switch (tier) {
    VipTier.svip => settings.svipEnabled && tier.hasEntranceFx,
    VipTier.diamond => settings.diamondEnabled && tier.hasEntranceFx,
    VipTier.gold => settings.goldEnabled && tier.hasEntranceFx,
    VipTier.premium => settings.premiumEnabled && tier.hasPremiumFrame,
    VipTier.basic => false,
  };
}

final entranceEffectAllowedProvider = Provider<bool>((ref) {
  final tier = ref.watch(vipTierProvider);
  final settings = ref.watch(entranceEffectSettingsProvider);
  final staff = ref.watch(staffAccessProvider);
  return entranceEffectAllowed(
    tier: tier,
    settings: settings,
    isStaff: staff.isSiteAdmin || staff.isFounder,
  );
});
