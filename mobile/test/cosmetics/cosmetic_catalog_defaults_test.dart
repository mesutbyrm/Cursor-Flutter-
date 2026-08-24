import 'package:canlifal_social/features/cosmetics/domain/cosmetic_catalog_defaults.dart';
import 'package:canlifal_social/features/cosmetics/domain/cosmetic_slot.dart';
import 'package:canlifal_social/features/vip_gold/domain/vip_tier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('default admin frame is lightning', () {
    final frame = CosmeticCatalogDefaults.defaultFrameFor(
      tier: VipTier.basic,
      role: 'admin',
    );
    expect(frame?.id, 'frame_admin_lightning');
  });

  test('gold tier gets rotating light when no role frame', () {
    final frame = CosmeticCatalogDefaults.defaultFrameFor(
      tier: VipTier.gold,
      role: 'user',
    );
    expect(frame?.id, 'frame_gold_rotating');
  });

  test('catalog includes entrance and chat bubble slots', () {
    final entrances =
        CosmeticCatalogDefaults.forSlot(CosmeticSlot.entranceAnimation);
    final bubbles = CosmeticCatalogDefaults.forSlot(CosmeticSlot.chatBubble);
    final mic = CosmeticCatalogDefaults.forSlot(CosmeticSlot.microphoneFrame);
    expect(entrances.any((e) => e.id == 'ent_dragon'), isTrue);
    expect(bubbles.any((e) => e.id == 'bubble_gold'), isTrue);
    expect(mic.any((e) => e.id == 'mic_neon'), isTrue);
  });

  test('membership badge defaults exist when API empty', () {
    final badges = CosmeticCatalogDefaults.forSlot(CosmeticSlot.badge);
    expect(badges.any((e) => e.id == 'badge_gold'), isTrue);
    expect(badges.any((e) => e.id == 'badge_founder'), isTrue);
  });
}
