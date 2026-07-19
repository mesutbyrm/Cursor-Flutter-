import '../../vip_gold/domain/vip_tier.dart';
import 'cosmetic_effect_kind.dart';
import 'cosmetic_item.dart';
import 'cosmetic_slot.dart';

/// Yerleşik katalog — backend boş/eksik olduğunda veya offline.
abstract final class CosmeticCatalogDefaults {
  static List<CosmeticItem> forSlot(CosmeticSlot slot) {
    return switch (slot) {
      CosmeticSlot.profileFrame => _frames,
      CosmeticSlot.nameEffect => _nameEffects,
      CosmeticSlot.profileEffect => _profileEffects,
      CosmeticSlot.entranceAnimation => _entrances,
      _ => const [],
    };
  }

  static List<CosmeticItem> get all => [
        ..._frames,
        ..._nameEffects,
        ..._profileEffects,
        ..._entrances,
      ];

  static const _frames = [
    CosmeticItem(
      id: 'frame_admin_lightning',
      slot: CosmeticSlot.profileFrame,
      name: 'Admin — Şimşek',
      effectKind: CosmeticEffectKind.lightning,
      requiredRole: 'admin',
      sortOrder: 1,
    ),
    CosmeticItem(
      id: 'frame_mod_neon',
      slot: CosmeticSlot.profileFrame,
      name: 'Moderatör — Neon',
      effectKind: CosmeticEffectKind.neonGlow,
      requiredRole: 'moderator',
      sortOrder: 2,
    ),
    CosmeticItem(
      id: 'frame_owner_crown',
      slot: CosmeticSlot.profileFrame,
      name: 'Oda Sahibi — Taç',
      effectKind: CosmeticEffectKind.crown,
      requiredRole: 'owner',
      sortOrder: 3,
    ),
    CosmeticItem(
      id: 'frame_gold_rotating',
      slot: CosmeticSlot.profileFrame,
      name: 'Gold — Dönen Işık',
      effectKind: CosmeticEffectKind.rotatingLight,
      requiredTier: VipTier.gold,
      sortOrder: 10,
    ),
    CosmeticItem(
      id: 'frame_gold_fire',
      slot: CosmeticSlot.profileFrame,
      name: 'Gold — Ateş',
      effectKind: CosmeticEffectKind.fire,
      requiredTier: VipTier.gold,
      sortOrder: 11,
    ),
    CosmeticItem(
      id: 'frame_premium_diamond',
      slot: CosmeticSlot.profileFrame,
      name: 'Premium — Elmas',
      effectKind: CosmeticEffectKind.diamond,
      requiredTier: VipTier.premium,
      sortOrder: 20,
    ),
    CosmeticItem(
      id: 'frame_vip_rainbow',
      slot: CosmeticSlot.profileFrame,
      name: 'VIP — Gökkuşağı',
      effectKind: CosmeticEffectKind.rainbow,
      requiredTier: VipTier.diamond,
      sortOrder: 30,
    ),
    CosmeticItem(
      id: 'frame_broadcaster_cosmic',
      slot: CosmeticSlot.profileFrame,
      name: 'Yayıncı — Kozmik',
      effectKind: CosmeticEffectKind.cosmicStars,
      requiredRole: 'broadcaster',
      sortOrder: 40,
    ),
    CosmeticItem(
      id: 'frame_fortune_aura',
      slot: CosmeticSlot.profileFrame,
      name: 'Falcı — Aura',
      effectKind: CosmeticEffectKind.aura,
      requiredRole: 'fortune_teller',
      sortOrder: 41,
    ),
    CosmeticItem(
      id: 'frame_support_heart',
      slot: CosmeticSlot.profileFrame,
      name: 'Destek — Kalp',
      effectKind: CosmeticEffectKind.heart,
      requiredRole: 'support',
      sortOrder: 42,
    ),
    CosmeticItem(
      id: 'frame_official_gold',
      slot: CosmeticSlot.profileFrame,
      name: 'Resmi Hesap — Altın',
      effectKind: CosmeticEffectKind.goldParticles,
      requiredRole: 'official',
      sortOrder: 5,
    ),
  ];

  static const _nameEffects = [
    CosmeticItem(
      id: 'name_gold',
      slot: CosmeticSlot.nameEffect,
      name: 'Altın yazı',
      effectKind: CosmeticEffectKind.goldText,
      requiredTier: VipTier.gold,
    ),
    CosmeticItem(
      id: 'name_silver',
      slot: CosmeticSlot.nameEffect,
      name: 'Gümüş yazı',
      effectKind: CosmeticEffectKind.silverText,
      requiredTier: VipTier.premium,
    ),
    CosmeticItem(
      id: 'name_diamond',
      slot: CosmeticSlot.nameEffect,
      name: 'Elmas yazı',
      effectKind: CosmeticEffectKind.diamondText,
      requiredTier: VipTier.diamond,
    ),
    CosmeticItem(
      id: 'name_neon',
      slot: CosmeticSlot.nameEffect,
      name: 'Neon yazı',
      effectKind: CosmeticEffectKind.neonText,
      requiredTier: VipTier.gold,
    ),
    CosmeticItem(
      id: 'name_rainbow',
      slot: CosmeticSlot.nameEffect,
      name: 'Rainbow yazı',
      effectKind: CosmeticEffectKind.rainbowText,
      requiredTier: VipTier.gold,
    ),
    CosmeticItem(
      id: 'name_fire',
      slot: CosmeticSlot.nameEffect,
      name: 'Ateş yazısı',
      effectKind: CosmeticEffectKind.fireText,
      requiredTier: VipTier.gold,
    ),
    CosmeticItem(
      id: 'name_hologram',
      slot: CosmeticSlot.nameEffect,
      name: 'Hologram',
      effectKind: CosmeticEffectKind.hologramText,
      requiredTier: VipTier.diamond,
    ),
  ];

  static const _profileEffects = [
    CosmeticItem(
      id: 'pfx_stars',
      slot: CosmeticSlot.profileEffect,
      name: 'Dönen yıldızlar',
      effectKind: CosmeticEffectKind.particleStars,
      requiredTier: VipTier.gold,
    ),
    CosmeticItem(
      id: 'pfx_galaxy',
      slot: CosmeticSlot.profileEffect,
      name: 'Kozmik galaksi',
      effectKind: CosmeticEffectKind.particleGalaxy,
      requiredTier: VipTier.gold,
    ),
    CosmeticItem(
      id: 'pfx_gold_dust',
      slot: CosmeticSlot.profileEffect,
      name: 'Altın tozları',
      effectKind: CosmeticEffectKind.particleGoldDust,
      requiredTier: VipTier.gold,
    ),
    CosmeticItem(
      id: 'pfx_hearts',
      slot: CosmeticSlot.profileEffect,
      name: 'Kalpler',
      effectKind: CosmeticEffectKind.particleHearts,
      requiredTier: VipTier.premium,
    ),
  ];

  static const _entrances = [
    CosmeticItem(
      id: 'ent_gold_rain',
      slot: CosmeticSlot.entranceAnimation,
      name: 'Altın yağmuru',
      effectKind: CosmeticEffectKind.entranceGoldRain,
      requiredTier: VipTier.gold,
    ),
    CosmeticItem(
      id: 'ent_fireworks',
      slot: CosmeticSlot.entranceAnimation,
      name: 'Havai fişek',
      effectKind: CosmeticEffectKind.entranceFireworks,
      requiredTier: VipTier.gold,
    ),
    CosmeticItem(
      id: 'ent_galaxy',
      slot: CosmeticSlot.entranceAnimation,
      name: 'Galaksi',
      effectKind: CosmeticEffectKind.entranceGalaxy,
      requiredTier: VipTier.diamond,
    ),
    CosmeticItem(
      id: 'ent_crown',
      slot: CosmeticSlot.entranceAnimation,
      name: 'Taç',
      effectKind: CosmeticEffectKind.entranceCrown,
      requiredTier: VipTier.gold,
    ),
  ];

  /// Yetki / üyelik için varsayılan çerçeve (Gold seçim yoksa).
  static CosmeticItem? defaultFrameFor({
    required VipTier tier,
    String? role,
    String? chatRole,
  }) {
    final r = _normalizeRole(role, chatRole);
    if (r.contains('admin') || r.contains('superadmin')) {
      return _frames.firstWhere((f) => f.id == 'frame_admin_lightning');
    }
    if (r.contains('moderator') || r.contains('mod') || r == 'op') {
      return _frames.firstWhere((f) => f.id == 'frame_mod_neon');
    }
    if (r.contains('owner') || r.contains('founder')) {
      return _frames.firstWhere((f) => f.id == 'frame_owner_crown');
    }
    if (r.contains('broadcaster') || r.contains('streamer')) {
      return _frames.firstWhere((f) => f.id == 'frame_broadcaster_cosmic');
    }
    if (r.contains('fortune') || r.contains('falc')) {
      return _frames.firstWhere((f) => f.id == 'frame_fortune_aura');
    }
    if (r.contains('support') || r.contains('destek')) {
      return _frames.firstWhere((f) => f.id == 'frame_support_heart');
    }
    if (tier.index >= VipTier.diamond.index) {
      return _frames.firstWhere((f) => f.id == 'frame_vip_rainbow');
    }
    if (tier.index >= VipTier.gold.index) {
      return _frames.firstWhere((f) => f.id == 'frame_gold_rotating');
    }
    if (tier.index >= VipTier.premium.index) {
      return _frames.firstWhere((f) => f.id == 'frame_premium_diamond');
    }
    return null;
  }

  static String _normalizeRole(String? role, String? chatRole) {
    return '${role ?? ''} ${chatRole ?? ''}'.toLowerCase();
  }
}
