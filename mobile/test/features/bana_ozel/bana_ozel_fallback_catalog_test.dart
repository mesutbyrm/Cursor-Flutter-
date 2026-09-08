import 'package:canlifal_social/features/bana_ozel/data/bana_ozel_fallback_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BanaOzelFallbackCatalog provides premium preview items', () {
    final catalog = BanaOzelFallbackCatalog.build(jetonBalance: 42);
    expect(catalog.items.length, greaterThanOrEqualTo(6));
    expect(catalog.jetonBalance, 42);
    expect(catalog.items.first.slug, 'gunluk-fal');
    expect(catalog.itemBySlug('tarot'), isNotNull);
  });
}
