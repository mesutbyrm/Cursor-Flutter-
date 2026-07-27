import 'package:canlifal_social/features/gifts/domain/gift_animation_policy.dart';
import 'package:canlifal_social/features/gifts/domain/gift_asset_type.dart';
import 'package:canlifal_social/features/gifts/domain/gift_display_type.dart';
import 'package:canlifal_social/features/gifts/domain/gift_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GiftAnimationPolicy', () {
    test('queue duration follows doc thresholds', () {
      expect(
        GiftAnimationPolicy.queueDuration(jetonPrice: 50),
        const Duration(seconds: 3),
      );
      expect(
        GiftAnimationPolicy.queueDuration(jetonPrice: 150),
        const Duration(seconds: 4),
      );
      expect(
        GiftAnimationPolicy.queueDuration(jetonPrice: 600),
        const Duration(seconds: 5),
      );
    });

    test('fullscreen flash at 200+ jeton', () {
      expect(GiftAnimationPolicy.shouldFullscreenFlash(199), isFalse);
      expect(GiftAnimationPolicy.shouldFullscreenFlash(200), isTrue);
    });

    test('network animation triggers fullscreen at any price', () {
      expect(
        GiftAnimationPolicy.shouldFullscreen(
          jetonPrice: 10,
          hasNetworkAnimation: true,
        ),
        isTrue,
      );
    });
  });

  group('GiftEntity schema fields', () {
    test('parses assetType and displayType from catalog JSON', () {
      final gift = GiftEntity.fromJson({
        'id': 'gift_rose',
        'name': 'Gül',
        'price': 100,
        'assetType': 'svga',
        'displayType': 'fullscreen',
        'contentVersion': 12,
        'assetUrl': 'https://cdn.example/rose.svga',
      });
      expect(gift.assetType, GiftAssetType.svga);
      expect(gift.displayType, GiftDisplayType.fullscreen);
      expect(gift.contentVersion, 12);
      expect(gift.shouldFullscreen, isTrue);
    });
  });

  group('GiftDisplayType', () {
    test('unknown values map to unknown', () {
      expect(GiftDisplayType.parse('future_mode'), GiftDisplayType.unknown);
    });
  });
}
