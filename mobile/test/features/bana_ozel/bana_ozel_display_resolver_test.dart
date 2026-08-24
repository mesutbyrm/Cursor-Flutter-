import 'package:canlifal_social/features/bana_ozel/domain/entities/bana_ozel_entities.dart';
import 'package:canlifal_social/features/bana_ozel/presentation/data/bana_ozel_display_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BanaOzelDisplayResolver', () {
    test('coverSlugFor maps tarot slug to tarot visuals', () {
      const item = BanaOzelItemEntity(
        id: '1',
        slug: 'gunluk-tarot',
        nameTr: 'Günlük Tarot Kartı',
        icon: '🃏',
        jetonCost: 5,
        category: 'tarot',
      );
      expect(BanaOzelDisplayResolver.coverSlugFor(item), 'tarot');
    });

    test('coverSlugFor maps horoscope slug to yildiz-haritasi', () {
      const item = BanaOzelItemEntity(
        id: '2',
        slug: 'gunluk-burc',
        nameTr: 'Günlük Burç Yorumu',
        icon: '♈',
        jetonCost: 3,
        category: 'astrology',
      );
      expect(BanaOzelDisplayResolver.coverSlugFor(item), 'yildiz-haritasi');
    });

    test('subtitleFor prefers descTr over horoscopeSign', () {
      const item = BanaOzelItemEntity(
        id: '3',
        slug: 'burc',
        nameTr: 'Burç',
        icon: '♈',
        jetonCost: 3,
        category: 'astrology',
        descTr: 'Kişisel yorum',
        horoscopeSign: 'Koç',
      );
      expect(BanaOzelDisplayResolver.subtitleFor(item), 'Kişisel yorum');
    });

    test('subtitleFor uses horoscopeSign when desc empty', () {
      const item = BanaOzelItemEntity(
        id: '4',
        slug: 'burc',
        nameTr: 'Burç',
        icon: '♈',
        jetonCost: 3,
        category: 'astrology',
        horoscopeSign: 'Koç',
      );
      expect(BanaOzelDisplayResolver.subtitleFor(item), 'Koç');
    });

    test('imageUrlFor resolves backend URL', () {
      const item = BanaOzelItemEntity(
        id: '5',
        slug: 'tarot',
        nameTr: 'Tarot',
        icon: '🃏',
        jetonCost: 5,
        category: 'tarot',
        imageUrl: 'https://cdn.example.com/tarot.webp',
      );
      expect(
        BanaOzelDisplayResolver.imageUrlFor(item),
        contains('tarot.webp'),
      );
    });
  });
}
