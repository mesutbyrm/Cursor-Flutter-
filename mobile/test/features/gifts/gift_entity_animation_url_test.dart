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
  test('GiftEntity.fromJson resolves R2 gift cloud path to CDN', () {
    final gift = GiftEntity.fromJson(
      {
        'id': 'r2-video',
        'name': 'R2 Video',
        'price': 100,
        'animationUrl': 'gift/gifts/60de072e-66c3-4ac2-9acd-cac8b076097d.mp4',
        'animationType': 'video',
      },
      siteOrigin: 'https://canlifal.com',
    );

    expect(
      gift.networkAnimationUrl,
      'https://cdn.girlive.com/gift/gifts/60de072e-66c3-4ac2-9acd-cac8b076097d.mp4',
    );
    expect(gift.animationKind, GiftAnimationKind.video);
    expect(gift.hasCmsAnimation, isTrue);
  });
}
