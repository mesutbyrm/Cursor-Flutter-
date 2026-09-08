import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/site_animation_catalog_datasource.dart';
import '../data/site_animation_catalog_preload.dart';
import '../data/site_animation_repository.dart';
import '../domain/site_animation_catalog_entry.dart';

final siteAnimationRepositoryProvider = Provider<SiteAnimationRepository>(
  (ref) => SiteAnimationRepository(ref.watch(dioProvider)),
);

final siteAnimationCatalogDataSourceProvider =
    Provider<SiteAnimationCatalogDataSource>(
  (ref) => SiteAnimationCatalogDataSource(ref.watch(dioProvider)),
);

final siteAnimationCatalogProvider =
    AsyncNotifierProvider<SiteAnimationCatalogNotifier, SiteAnimationCatalogSnapshot>(
  SiteAnimationCatalogNotifier.new,
);

class SiteAnimationCatalogNotifier
    extends AsyncNotifier<SiteAnimationCatalogSnapshot> {
  @override
  Future<SiteAnimationCatalogSnapshot> build() async {
    ref.keepAlive();
    final snapshot =
        await ref.read(siteAnimationRepositoryProvider).getActiveCatalog();
    unawaited(SiteAnimationCatalogPreload.warm(snapshot));
    return snapshot;
  }

  Future<void> refresh({bool forceRefresh = true}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final snapshot = await ref
          .read(siteAnimationRepositoryProvider)
          .getActiveCatalog(forceRefresh: forceRefresh);
      unawaited(SiteAnimationCatalogPreload.warm(snapshot));
      return snapshot;
    });
  }

  Future<void> syncFromAdminLocal() async {
    await ref.read(siteAnimationRepositoryProvider).syncFromAdminLocal();
    await refresh(forceRefresh: false);
  }
}
