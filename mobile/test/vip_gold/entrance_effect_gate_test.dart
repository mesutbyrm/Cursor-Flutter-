import 'package:canlifal_social/features/vip_gold/domain/entrance_effect_settings.dart';
import 'package:canlifal_social/features/vip_gold/domain/vip_tier.dart';
import 'package:canlifal_social/features/vip_gold/presentation/providers/entrance_effect_gate_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('entranceEffectAllowed', () {
    const settings = EntranceEffectSettings();

    test('gold tier allowed when gold enabled', () {
      expect(
        entranceEffectAllowed(tier: VipTier.gold, settings: settings, isStaff: false),
        isTrue,
      );
    });

    test('basic tier blocked', () {
      expect(
        entranceEffectAllowed(tier: VipTier.basic, settings: settings, isStaff: false),
        isFalse,
      );
    });

    test('staff allowed when admin entrance enabled', () {
      expect(
        entranceEffectAllowed(tier: VipTier.basic, settings: settings, isStaff: true),
        isTrue,
      );
    });

    test('respects disabled gold flag', () {
      const off = EntranceEffectSettings(goldEnabled: false);
      expect(
        entranceEffectAllowed(tier: VipTier.gold, settings: off, isStaff: false),
        isFalse,
      );
    });
  });
}
