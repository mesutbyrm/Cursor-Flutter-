import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../vip_gold/domain/vip_tier.dart';
import '../../../vip_gold/presentation/providers/vip_membership_provider.dart';
import '../../data/cosmetic_loadout_store.dart';
import '../../data/cosmetics_catalog_cache.dart';
import '../../data/cosmetics_remote_datasource.dart';
import '../../domain/cosmetic_catalog_defaults.dart';
import '../../domain/cosmetic_item.dart';
import '../../domain/cosmetic_slot.dart';
import '../../domain/user_cosmetic_loadout.dart';

final cosmeticsRemoteProvider = Provider<CosmeticsRemoteDataSource>((ref) {
  return CosmeticsRemoteDataSource(ref.watch(dioProvider));
});

final profileFramesCatalogProvider =
    FutureProvider<List<CosmeticItem>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final cache = CosmeticsCatalogCache(prefs);
  final cached = await cache.read();
  if (cached != null && cached.isNotEmpty) {
    // Arka planda tazele.
    Future.microtask(() async {
      try {
        final remote =
            await ref.read(cosmeticsRemoteProvider).fetchProfileFrames();
        if (remote.isNotEmpty) await cache.write(remote);
      } catch (_) {}
    });
    return cached;
  }
  final remote = await ref.watch(cosmeticsRemoteProvider).fetchProfileFrames();
  if (remote.isNotEmpty) {
    await cache.write(remote);
    return remote;
  }
  return CosmeticCatalogDefaults.forSlot(CosmeticSlot.profileFrame);
});

final membershipBadgesCatalogProvider =
    FutureProvider<List<CosmeticItem>>((ref) async {
  final remote =
      await ref.watch(cosmeticsRemoteProvider).fetchMembershipBadges();
  if (remote.isNotEmpty) return remote;
  return const [];
});

final cosmeticLoadoutProvider =
    AsyncNotifierProvider<CosmeticLoadoutNotifier, UserCosmeticLoadout>(
  CosmeticLoadoutNotifier.new,
);

class CosmeticLoadoutNotifier extends AsyncNotifier<UserCosmeticLoadout> {
  CosmeticLoadoutStore? _store;

  Future<CosmeticLoadoutStore> _ensureStore() async {
    _store ??= CosmeticLoadoutStore(await SharedPreferences.getInstance());
    return _store!;
  }

  @override
  Future<UserCosmeticLoadout> build() async {
    final userId = ref.watch(authControllerProvider).valueOrNull?.id ?? '';
    if (userId.isEmpty) return const UserCosmeticLoadout.empty();
    return (await _ensureStore()).read(userId);
  }

  Future<void> equip(CosmeticSlot slot, String? itemId) async {
    final userId = ref.read(authControllerProvider).valueOrNull?.id ?? '';
    if (userId.isEmpty) return;
    final current = state.valueOrNull ?? const UserCosmeticLoadout.empty();
    final next = current.copyWithEquipped(slot, itemId);
    state = AsyncData(next);
    await (await _ensureStore()).write(userId, next);
  }
}

final resolvedProfileFrameProvider = Provider<CosmeticItem?>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  final tier = ref.watch(vipTierProvider);
  final loadout = ref.watch(cosmeticLoadoutProvider).valueOrNull;
  final catalog = ref.watch(profileFramesCatalogProvider).valueOrNull ??
      CosmeticCatalogDefaults.forSlot(CosmeticSlot.profileFrame);

  final equippedId = loadout?.idFor(CosmeticSlot.profileFrame);
  if (equippedId != null) {
    for (final picked in catalog) {
      if (picked.id == equippedId &&
          picked.isUnlockedFor(tier: tier, role: user?.role)) {
        return picked;
      }
    }
  }

  return CosmeticCatalogDefaults.defaultFrameFor(
    tier: tier,
    role: user?.role,
    chatRole: user?.role,
  );
});

final resolvedNameEffectProvider = Provider<CosmeticItem?>((ref) {
  final tier = ref.watch(vipTierProvider);
  if (tier.index < VipTier.gold.index) return null;
  final loadout = ref.watch(cosmeticLoadoutProvider).valueOrNull;
  final id = loadout?.idFor(CosmeticSlot.nameEffect);
  if (id == null) return null;
  for (final c in CosmeticCatalogDefaults.forSlot(CosmeticSlot.nameEffect)) {
    if (c.id == id) return c;
  }
  return null;
});

final resolvedProfileEffectProvider = Provider<CosmeticItem?>((ref) {
  final tier = ref.watch(vipTierProvider);
  if (tier.index < VipTier.gold.index) return null;
  final loadout = ref.watch(cosmeticLoadoutProvider).valueOrNull;
  final id = loadout?.idFor(CosmeticSlot.profileEffect);
  if (id == null) return null;
  for (final c in CosmeticCatalogDefaults.forSlot(CosmeticSlot.profileEffect)) {
    if (c.id == id) return c;
  }
  return null;
});

final canCustomizeCosmeticsProvider = Provider<bool>((ref) {
  return ref.watch(vipTierProvider).index >= VipTier.gold.index;
});

/// Üyelik rozeti — `GET /api/membership-badges` + tier eşleşmesi.
final resolvedMembershipBadgeProvider = Provider<CosmeticItem?>((ref) {
  final tier = ref.watch(vipTierProvider);
  if (tier == VipTier.basic) return null;
  final catalog = ref.watch(membershipBadgesCatalogProvider).valueOrNull;
  if (catalog == null || catalog.isEmpty) return null;
  for (final b in catalog) {
    if (b.requiredTier == tier) return b;
  }
  return catalog.first;
});

List<CosmeticItem> catalogForSlot(CosmeticSlot slot) {
  return CosmeticCatalogDefaults.forSlot(slot);
}
