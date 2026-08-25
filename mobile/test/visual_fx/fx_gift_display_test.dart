import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/visual_fx/data/fx_dedupe_store.dart';
import 'package:canlifal_social/features/visual_fx/domain/fx_gift_tier.dart';

void main() {
  group('FxDedupeStore', () {
    test('marks first event as new', () {
      final store = FxDedupeStore();
      expect(store.markIfNew('gift-1'), isTrue);
      expect(store.markIfNew('gift-1'), isFalse);
    });

    test('allows same id after window', () {
      final store = FxDedupeStore();
      expect(store.markIfNew('gift-2', nowMs: 0), isTrue);
      expect(store.markIfNew('gift-2', nowMs: 121_000), isTrue);
    });
  });

  group('FxGiftTier', () {
    test('classifies jeton amounts', () {
      expect(FxGiftTier.fromJeton(50), FxGiftTier.small);
      expect(FxGiftTier.fromJeton(500), FxGiftTier.medium);
      expect(FxGiftTier.fromJeton(1500), FxGiftTier.special);
      expect(FxGiftTier.fromJeton(12000), FxGiftTier.legendary);
    });

    test('big gift threshold', () {
      expect(FxGiftTier.fromJeton(999).isBigGift, isFalse);
      expect(FxGiftTier.fromJeton(1000).isBigGift, isTrue);
    });
  });
}
