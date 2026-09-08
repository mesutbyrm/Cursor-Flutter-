import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/site_animation/presentation/site_animation_catalog_provider.dart';
import '../../data/admin_site_animation_remote_datasource.dart';
import '../../domain/admin_site_animation.dart';
import '../../../core/network/dio_provider.dart';
import 'admin_panel_providers.dart';

final adminSiteAnimationRemoteProvider =
    Provider<AdminSiteAnimationRemoteDataSource>(
  (ref) => AdminSiteAnimationRemoteDataSource(ref.watch(dioProvider)),
);

final adminSiteAnimationListProvider =
    AsyncNotifierProvider<AdminSiteAnimationListNotifier, List<AdminSiteAnimation>>(
  AdminSiteAnimationListNotifier.new,
);

final adminSiteAnimationStatsProvider =
    FutureProvider<AdminSiteAnimationStats>((ref) async {
  ref.watch(adminSiteAnimationListProvider);
  return ref.read(adminSiteAnimationRemoteProvider).fetchStats();
});

final adminSiteAnimationDefaultsProvider =
    AsyncNotifierProvider<AdminSiteAnimationDefaultsNotifier,
        Map<AdminSiteAnimationMembership, String>>(
  AdminSiteAnimationDefaultsNotifier.new,
);

final adminSiteAnimationExitDefaultsProvider =
    AsyncNotifierProvider<AdminSiteAnimationExitDefaultsNotifier,
        Map<AdminSiteAnimationMembership, String>>(
  AdminSiteAnimationExitDefaultsNotifier.new,
);

class AdminSiteAnimationListNotifier
    extends AsyncNotifier<List<AdminSiteAnimation>> {
  @override
  Future<List<AdminSiteAnimation>> build() =>
      ref.read(adminSiteAnimationRemoteProvider).listAnimations();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(adminSiteAnimationRemoteProvider).listAnimations(),
    );
  }

  Future<AdminSiteAnimation> save(AdminSiteAnimation item, {bool create = false}) async {
    final remote = ref.read(adminSiteAnimationRemoteProvider);
    final saved = create
        ? await remote.create(item.toJson())
        : await remote.update(item.id, item.toJson());
    await ref.read(siteAnimationCatalogDataSourceProvider).syncFromAdminLocal();
    ref.invalidate(siteAnimationCatalogProvider);
    await refresh();
    return saved;
  }

  Future<void> toggleActive(String id, bool active) async {
    await ref.read(adminSiteAnimationRemoteProvider).setActive(id, active);
    await ref.read(siteAnimationCatalogDataSourceProvider).syncFromAdminLocal();
    ref.invalidate(siteAnimationCatalogProvider);
    await refresh();
  }
}

class AdminSiteAnimationDefaultsNotifier
    extends AsyncNotifier<Map<AdminSiteAnimationMembership, String>> {
  @override
  Future<Map<AdminSiteAnimationMembership, String>> build() =>
      ref.read(adminSiteAnimationRemoteProvider).fetchDefaults();

  Future<void> save(Map<AdminSiteAnimationMembership, String> next) async {
    await ref.read(adminSiteAnimationRemoteProvider).saveDefaults(next);
    await ref.read(siteAnimationCatalogDataSourceProvider).syncFromAdminLocal();
    ref.invalidate(siteAnimationCatalogProvider);
    state = AsyncData(next);
  }
}

class AdminSiteAnimationExitDefaultsNotifier
    extends AsyncNotifier<Map<AdminSiteAnimationMembership, String>> {
  @override
  Future<Map<AdminSiteAnimationMembership, String>> build() =>
      ref.read(adminSiteAnimationRemoteProvider).fetchExitDefaults();

  Future<void> save(Map<AdminSiteAnimationMembership, String> next) async {
    await ref.read(adminSiteAnimationRemoteProvider).saveExitDefaults(next);
    await ref.read(siteAnimationCatalogDataSourceProvider).syncFromAdminLocal();
    ref.invalidate(siteAnimationCatalogProvider);
    state = AsyncData(next);
  }
}
