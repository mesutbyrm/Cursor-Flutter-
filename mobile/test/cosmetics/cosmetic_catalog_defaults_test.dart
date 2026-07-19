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

  test('catalog includes name effects for gold', () {
    final names = CosmeticCatalogDefaults.forSlot(CosmeticSlot.nameEffect);
    expect(names.any((e) => e.id == 'name_gold'), isTrue);
  });
}
