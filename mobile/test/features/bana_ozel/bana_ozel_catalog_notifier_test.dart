import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/bana_ozel/domain/entities/bana_ozel_entities.dart';
import 'package:canlifal_social/features/bana_ozel/presentation/providers/bana_ozel_providers.dart';

void main() {
  group('BanaOzelCatalogNotifier.applyOpenResult', () {
    test('updates jeton balance and streak from open result', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(banaOzelCatalogProvider.notifier).state = AsyncData(
        const BanaOzelCatalogEntity(
          items: [
            BanaOzelItemEntity(
              id: '1',
              slug: 'sansli-sayilar',
              nameTr: 'Şanslı Sayılar',
              icon: '🍀',
              jetonCost: 2,
              category: 'fortune',
            ),
          ],
          jetonBalance: 10,
          streak: BanaOzelStreakEntity(currentStreak: 1),
        ),
      );

      container.read(banaOzelCatalogProvider.notifier).applyOpenResult(
            const BanaOzelOpenResultEntity(
              content: '7, 14',
              itemSlug: 'sansli-sayilar',
              itemName: 'Şanslı Sayılar',
              jetonSpent: 2,
              jetonBalance: 8,
              streak: BanaOzelStreakEntity(currentStreak: 2),
            ),
          );

      final updated = container.read(banaOzelCatalogProvider).value!;
      expect(updated.jetonBalance, 8);
      expect(updated.streak.currentStreak, 2);
    });

    test('derives balance when open response omits jetonBalance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(banaOzelCatalogProvider.notifier).state = AsyncData(
        const BanaOzelCatalogEntity(
          items: [],
          jetonBalance: 10,
        ),
      );

      container.read(banaOzelCatalogProvider.notifier).applyOpenResult(
            const BanaOzelOpenResultEntity(
              content: 'ok',
              itemSlug: 'x',
              itemName: 'X',
              jetonSpent: 3,
              jetonBalance: 0,
            ),
          );

      expect(container.read(banaOzelCatalogProvider).value!.jetonBalance, 7);
    });
  });
}
