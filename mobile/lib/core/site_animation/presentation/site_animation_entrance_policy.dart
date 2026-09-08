import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/cosmetics/presentation/providers/cosmetics_providers.dart';
import '../domain/site_animation_catalog_entry.dart';
import 'site_animation_catalog_provider.dart';

/// Site animation giriş kataloğu aktifken tam ekran VIP overlay atlanır.
bool shouldSkipFullscreenVipEntrance({
  required SiteAnimationCatalogSnapshot? catalog,
  required bool hasCosmeticEntrance,
}) {
  if (hasCosmeticEntrance) return false;
  if (catalog == null) return false;
  return catalog.hasActiveEntranceCatalog;
}

/// Riverpod yardımcısı — sesli oda self-join giriş kararı.
bool shouldSkipFullscreenVipEntranceRef(WidgetRef ref) {
  final catalog = ref.read(siteAnimationCatalogProvider).valueOrNull;
  final cosmetic = ref.read(resolvedEntranceEffectProvider);
  return shouldSkipFullscreenVipEntrance(
    catalog: catalog,
    hasCosmeticEntrance: cosmetic != null,
  );
}
