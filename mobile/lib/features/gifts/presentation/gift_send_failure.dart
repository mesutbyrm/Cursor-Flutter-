import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/gift_client_price.dart';
import 'providers/gift_catalog_invalidate.dart';
import 'providers/gift_providers.dart';

/// Hediye POST hatası — fiyat uyuşmazlığında katalog yenile.
Future<void> handleGiftSendFailure(WidgetRef ref, Object error) async {
  if (!isGiftPriceMismatch(error)) return;
  await invalidateAllGiftCatalogs(ref);
}

/// [Ref] tabanlı (Notifier / provider içi).
Future<void> handleGiftSendFailureFromRef(Ref ref, Object error) async {
  if (!isGiftPriceMismatch(error)) return;
  await ref.read(giftRepositoryProvider).bustCatalogCache();
  invalidateGiftCatalogProvidersFromRef(ref);
}
