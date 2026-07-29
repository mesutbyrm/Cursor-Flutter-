import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/gift_repository.dart';
import '../providers/gift_providers.dart';
import 'gift_catalog_invalidate.dart';

/// CMS hediye sürümü değişince katalogları otomatik yeniler (uygulama yeniden
/// başlatmadan yeni hediyeler görünür).
final giftCatalogVersionWatcherProvider = Provider<void>((ref) {
  Timer? timer;
  var knownVersion = 0;
  var checking = false;

  Future<void> poll() async {
    if (checking) return;
    checking = true;
    try {
      final repo = ref.read(giftRepositoryProvider);
      final remote = await repo.fetchCatalogVersion();
      final version = remote.giftVersion;
      if (version <= 0) return;

      if (knownVersion > 0 && version > knownVersion) {
        await repo.syncCatalogIfNeeded(forceRefresh: true);
        invalidateGiftCatalogProvidersFromRef(ref);
      } else if (knownVersion == 0) {
        await repo.syncCatalogIfNeeded();
      }
      knownVersion = version;
    } catch (_) {
    } finally {
      checking = false;
    }
  }

  unawaited(poll());
  timer = Timer.periodic(const Duration(seconds: 45), (_) => poll());
  ref.onDispose(timer.cancel);
});

void watchGiftCatalogVersion(WidgetRef ref) {
  ref.watch(giftCatalogVersionWatcherProvider);
}
