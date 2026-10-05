import 'package:canlifal_social/core/animations/animation_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolve yükü ayrıştırılır; göreli adres siteye tamamlanır', () {
    final p = AnimationPayload.fromJson({
      'animationId': 'a1',
      'slug': 'entrance-diamond-1',
      'category': 'entrance',
      'type': 'IMAGE',
      'assetUrl': '/cosmetics/animations/entrance-diamond-1.svg',
      'durationMs': 2500,
      'scale': 'large',
      'cooldownMs': 100,
    });
    expect(p.type, 'image');
    expect(p.isSvg, isTrue);
    expect(p.resolvedAssetUrl, endsWith('/cosmetics/animations/entrance-diamond-1.svg'));
    expect(p.resolvedAssetUrl.startsWith('http'), isTrue);
    expect(p.scaleFactor, 1.25);
    expect(p.cooldownMs, 100);
    expect(p.resolvedSoundUrl, isNull);
  });

  test('mutlak adres olduğu gibi kalır', () {
    expect(AnimationPayload.absoluteUrl('https://x.test/a.png'), 'https://x.test/a.png');
    expect(AnimationPayload.absoluteUrl(''), '');
  });
}
