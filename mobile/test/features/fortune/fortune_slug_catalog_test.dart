import 'package:canlifal_social/features/fortune/domain/fortune_type_slug.dart';
import 'package:canlifal_social/features/fortune/presentation/data/fortune_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FortuneTypeSlug resolves dedicated slugs', () {
    expect(FortuneTypeSlug.resolve('aura'), 'aura-analizi');
    expect(FortuneTypeSlug.resolve('istihare'), 'istihare');
    expect(FortuneTypeSlug.resolve('kursun-dokme'), 'kursundokme');
  });

  test('FortuneCatalog maps aura istihare kursun without wrong aliases', () {
    expect(FortuneCatalog.bySlug('aura')?.slug, 'aura-analizi');
    expect(FortuneCatalog.bySlug('istihare')?.slug, 'istihare');
    expect(FortuneCatalog.bySlug('kursundokme')?.slug, 'kursundokme');
    expect(FortuneCatalog.bySlug('dogum-haritasi')?.slug, 'dogum-haritasi');
    expect(FortuneCatalog.bySlug('aura')?.slug, isNot('runik'));
    expect(FortuneCatalog.bySlug('istihare')?.slug, isNot('pendul'));
  });
}
