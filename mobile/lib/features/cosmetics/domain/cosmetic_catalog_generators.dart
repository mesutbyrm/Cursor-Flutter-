import '../../../core/config/env.dart';
import '../../vip_gold/domain/vip_tier.dart';
import 'cosmetic_effect_kind.dart';
import 'cosmetic_item.dart';
import 'cosmetic_slot.dart';

/// Kozmetik örnek kataloğu — programatik üretim.
abstract final class CosmeticCatalogGenerators {
  static List<CosmeticItem> profileFrames({int count = 20}) => _cosmetics(
        slot: CosmeticSlot.profileFrame,
        count: count,
        prefix: 'Çerçeve',
        kinds: const [
          CosmeticEffectKind.rotatingLight,
          CosmeticEffectKind.neonGlow,
          CosmeticEffectKind.fire,
          CosmeticEffectKind.diamond,
          CosmeticEffectKind.cosmicStars,
          CosmeticEffectKind.aura,
          CosmeticEffectKind.lightning,
          CosmeticEffectKind.rainbow,
        ],
      );

  static List<CosmeticItem> nameEffects({int count = 20}) => _cosmetics(
        slot: CosmeticSlot.nameEffect,
        count: count,
        prefix: 'İsim',
        kinds: const [
          CosmeticEffectKind.goldText,
          CosmeticEffectKind.silverText,
          CosmeticEffectKind.diamondText,
          CosmeticEffectKind.neonText,
          CosmeticEffectKind.rainbowText,
          CosmeticEffectKind.fireText,
          CosmeticEffectKind.hologramText,
          CosmeticEffectKind.glowText,
          CosmeticEffectKind.crystalText,
        ],
      );

  static List<CosmeticItem> avatarAccessories({int count = 20}) => _cosmetics(
        slot: CosmeticSlot.avatarAccessory,
        count: count,
        prefix: 'Aksesuar',
        kinds: const [
          CosmeticEffectKind.crown,
          CosmeticEffectKind.cosmicStars,
          CosmeticEffectKind.heart,
          CosmeticEffectKind.diamond,
          CosmeticEffectKind.goldParticles,
          CosmeticEffectKind.aura,
          CosmeticEffectKind.neonGlow,
          CosmeticEffectKind.rainbow,
        ],
      );

  static List<CosmeticItem> chatBubbles({int count = 10}) => _cosmetics(
        slot: CosmeticSlot.chatBubble,
        count: count,
        prefix: 'Balon',
        kinds: const [
          CosmeticEffectKind.goldText,
          CosmeticEffectKind.neonText,
          CosmeticEffectKind.glassText,
          CosmeticEffectKind.rainbowText,
          CosmeticEffectKind.hologramText,
        ],
      );

  static List<CosmeticItem> microphoneFrames({int count = 10}) => _cosmetics(
        slot: CosmeticSlot.microphoneFrame,
        count: count,
        prefix: 'Mikrofon',
        kinds: const [
          CosmeticEffectKind.neonGlow,
          CosmeticEffectKind.fire,
          CosmeticEffectKind.goldParticles,
          CosmeticEffectKind.diamond,
          CosmeticEffectKind.rainbow,
        ],
      );

  static List<CosmeticItem> membershipBadges({int count = 10}) => _cosmetics(
        slot: CosmeticSlot.badge,
        count: count,
        prefix: 'Üyelik',
        kinds: const [
          CosmeticEffectKind.goldParticles,
          CosmeticEffectKind.diamond,
          CosmeticEffectKind.crown,
          CosmeticEffectKind.imageOverlay,
        ],
        tiers: const [VipTier.premium, VipTier.gold, VipTier.diamond],
      );

  static List<CosmeticItem> _cosmetics({
    required CosmeticSlot slot,
    required int count,
    required String prefix,
    required List<CosmeticEffectKind> kinds,
    List<VipTier> tiers = const [VipTier.gold],
  }) {
    return List.generate(count, (i) {
      final n = i + 1;
      return CosmeticItem(
        id: '${slot.name}_sample_$n',
        slot: slot,
        name: '$prefix $n',
        effectKind: kinds[i % kinds.length],
        requiredTier: tiers[i % tiers.length],
        sortOrder: n,
        previewUrl: _previewFor(slot, n),
      );
    });
  }

  static String? _previewFor(CosmeticSlot slot, int index) {
    final origin = Env.webOrigin.replaceAll(RegExp(r'/$'), '');
    return switch (slot) {
      CosmeticSlot.profileFrame ||
      CosmeticSlot.avatarAccessory =>
        '$origin/images/cosmetics/frame-$index.png',
      CosmeticSlot.microphoneFrame => '$origin/images/cosmetics/mic-$index.png',
      CosmeticSlot.chatBubble => '$origin/images/cosmetics/bubble-$index.png',
      CosmeticSlot.badge => '$origin/images/cosmetics/badge-$index.png',
      _ => null,
    };
  }
}
