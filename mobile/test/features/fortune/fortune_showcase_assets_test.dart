import 'package:canlifal_social/features/fortune/presentation/data/fortune_catalog.dart';
import 'package:canlifal_social/features/fortune/presentation/data/fortune_type_images.dart';
import 'package:canlifal_social/features/fortune/presentation/data/fortune_type_showcase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FortuneTypeShowcase covers every catalog type without RangeError', () {
    for (final type in FortuneCatalog.types) {
      final showcase = FortuneTypeShowcase.forSlug(type.slug);
      expect(showcase, isNotNull, reason: 'missing showcase for ${type.slug}');
      expect(showcase!.type.slug, type.slug);
    }
  });

  test('FortuneTypeImages assetPathFor all catalog slugs', () {
    for (final type in FortuneCatalog.types) {
      expect(
        FortuneTypeImages.assetPathFor(type.slug),
        isNotNull,
        reason: 'missing asset for ${type.slug}',
      );
    }
    expect(FortuneTypeImages.assetPathFor('gunluk-fal'), contains('gunluk-fal'));
    expect(FortuneTypeImages.assetPathFor('dogum-haritasi'), contains('dogum-haritasi'));
    expect(FortuneTypeImages.assetPathFor('kursundokme'), contains('kursundokme'));
    expect(FortuneTypeImages.assetPathFor('pendul'), contains('pendul'));
    expect(FortuneTypeImages.assetPathFor('runik'), contains('runik'));
    expect(FortuneTypeImages.assetPathFor('aura-analizi'), contains('aura-analizi'));
  });
}
