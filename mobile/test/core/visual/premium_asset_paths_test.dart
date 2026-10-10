import 'package:canlifal_social/core/visual/premium/premium_asset_paths.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('home quick access maps legacy tile to premium path', () {
    expect(
      PremiumAssetPaths.homeQuickAccess('home-kesfet.webp'),
      'assets/images/premium/home/discover_icon.webp',
    );
  });

  test('fortune slug resolves premium file', () {
    expect(
      PremiumAssetPaths.fortuneFromSlug('kahve-fali'),
      'assets/images/premium/fortune/kahve-fali.webp',
    );
  });

  test('zodiac and membership paths', () {
    expect(PremiumAssetPaths.zodiac('koc'), contains('zodiac/koc.webp'));
    expect(PremiumAssetPaths.membership('gold'), contains('membership/gold.webp'));
  });
}
