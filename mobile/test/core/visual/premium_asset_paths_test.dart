import 'package:canlifal_social/core/visual/premium/premium_asset_paths.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('home quick access maps legacy tile to premium path', () {
    expect(
      PremiumAssetPaths.homeQuickAccess('home-kesfet.webp'),
      'assets/tiles/home-kesfet.webp',
    );
  });

  test('fortune slug resolves premium file', () {
    expect(
      PremiumAssetPaths.fortuneFromSlug('kahve-fali'),
      'assets/fortune/kahve-fali.webp',
    );
  });

  test('zodiac and membership paths', () {
    expect(PremiumAssetPaths.zodiac('koc'), contains('zodiac/koc.webp'));
    expect(PremiumAssetPaths.membership('gold'), contains('membership/gold.webp'));
  });

  test('premium fortune asset registered in pubspec manifest', () async {
    final path = PremiumAssetPaths.fortuneFromSlug('kahve-fali')!;
    final data = await rootBundle.load(path);
    expect(data.lengthInBytes, greaterThan(1000));
  });
}
