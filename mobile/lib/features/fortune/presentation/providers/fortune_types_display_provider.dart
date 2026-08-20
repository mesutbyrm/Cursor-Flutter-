import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/presentation/providers/home_providers.dart';
import '../../domain/entities/fortune_display_entry.dart';
import '../data/fortune_display_resolver.dart';

/// Fal türleri vitrin — homepage kartları → fortune-request-types → katalog.
final fortuneTypesDisplayProvider =
    FutureProvider<List<FortuneDisplayEntry>>((ref) async {
  ref.keepAlive();
  final cards = await ref.watch(homeFortuneCardsProvider.future);
  if (cards.isNotEmpty) {
    return FortuneDisplayResolver.fromHomeCards(cards);
  }
  final types = await ref.watch(homeFortuneRequestTypesProvider.future);
  if (types.isNotEmpty) {
    return FortuneDisplayResolver.fromRequestTypes(types);
  }
  return FortuneDisplayResolver.fromCatalog();
});

/// Fal vitrin verisini yenile (yalnızca ilgili API'ler).
void invalidateFortuneTypesDisplay(WidgetRef ref) {
  ref.invalidate(homeFortuneCardsProvider);
  ref.invalidate(homeFortuneRequestTypesProvider);
  ref.invalidate(fortuneTypesDisplayProvider);
}
