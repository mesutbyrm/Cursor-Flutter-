import 'package:canlifal_social/core/site_animation/data/site_animation_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sound path follows CDN convention', () {
    expect(
      SiteAnimationAssetPaths.sound('anim_entrance_gold_crown'),
      'https://cdn.canlifal.com/animations/sounds/anim_entrance_gold_crown.mp3',
    );
  });
}
