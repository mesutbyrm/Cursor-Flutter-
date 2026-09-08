import 'package:dio/dio.dart';

import '../domain/site_animation_catalog_entry.dart';
import 'site_animation_catalog_datasource.dart';

/// Kılavuz §9.14 — aktif site animasyon kataloğu repository.
class SiteAnimationRepository {
  SiteAnimationRepository(Dio dio)
      : _dataSource = SiteAnimationCatalogDataSource(dio);

  final SiteAnimationCatalogDataSource _dataSource;

  Future<SiteAnimationCatalogSnapshot> getActiveCatalog({
    bool forceRefresh = false,
  }) =>
      _dataSource.load(forceRefresh: forceRefresh);

  Future<void> syncFromAdminLocal() => _dataSource.syncFromAdminLocal();
}
