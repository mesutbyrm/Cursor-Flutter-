import 'package:canlifal_social/features/gifts/domain/gift_animation_kind.dart';
import 'package:canlifal_social/features/gifts/domain/gift_entity.dart';
import 'package:canlifal_social/features/gifts/domain/gift_event_catalog_enricher.dart';
import 'package:canlifal_social/features/live/domain/entities/live_gift_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('enrichGiftEventFromCatalog adds video animation from CMS', () {
    const catalog = GiftEntity(
      id: 'gt_rose',
      name: 'Gül',
      price: 100,
      assetUrl: 'https://cdn.example.com/rose.mp4',
      animationKind: GiftAnimationKind.video,
    );
    final raw = LiveGiftEvent(
      id: 'e1',
      senderName: 'A',
      receiverName: 'B',
      giftId: 'gt_rose',
      giftName: 'Gül',
      quantity: 1,
      coinCost: 100,
      timestamp: DateTime(2026, 7, 23),
    );

    final enriched = enrichGiftEventFromCatalog(raw, catalog);

    expect(enriched.animationKey, 'https://cdn.example.com/rose.mp4');
    expect(enriched.animationKind, GiftAnimationKind.video);
  });
}
