import 'package:canlifal_social/features/gifts/domain/gift_animation_kind.dart';
import 'package:canlifal_social/features/gifts/domain/gift_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GiftEntity.fromJson uses animationUrl for video playback', () {
    const origin = 'https://canlifal.com';
    final gift = GiftEntity.fromJson(
      {
        'id': 'video-gift',
        'name': 'Video Hediye',
        'price': 500,
        'thumbnailUrl': 'https://cdn.example.com/thumb.jpg',
        'animationUrl': 'https://cdn.example.com/gift.mp4',
        'animationType': 'mp4',
      },
      siteOrigin: origin,
    );

    expect(gift.networkAnimationUrl, 'https://cdn.example.com/gift.mp4');
    expect(gift.animationKind, GiftAnimationKind.video);
    expect(gift.hasCmsAnimation, isTrue);
  });

  test('GiftEntity.fromJson resolves relative animationUrl', () {
    final gift = GiftEntity.fromJson(
      {
        'id': 'rel-video',
        'name': 'Rel Video',
        'price': 100,
        'animationUrl': '/uploads/gifts/rocket.webm',
        'animationType': 'webm',
      },
      siteOrigin: 'https://canlifal.com',
    );

    expect(
      gift.networkAnimationUrl,
      'https://canlifal.com/uploads/gifts/rocket.webm',
    );
    expect(gift.animationKind, GiftAnimationKind.video);
  });
}
