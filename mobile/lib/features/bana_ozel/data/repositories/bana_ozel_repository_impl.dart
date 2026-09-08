import '../../domain/entities/bana_ozel_entities.dart';
import '../../domain/repositories/bana_ozel_repository.dart';
import '../bana_ozel_fallback_catalog.dart';
import '../datasources/bana_ozel_remote_datasource.dart';

class BanaOzelRepositoryImpl implements BanaOzelRepository {
  BanaOzelRepositoryImpl(this._remote);

  final BanaOzelRemoteDataSource _remote;

  @override
  Future<BanaOzelCatalogEntity> fetchCatalog() async {
    try {
      final catalog = await _remote.fetchCatalog();
      if (catalog.items.isNotEmpty) return catalog;
      return BanaOzelFallbackCatalog.build(
        jetonBalance: catalog.jetonBalance,
        cfcBalance: catalog.cfcBalance,
        streak: catalog.streak,
        todayTasks: catalog.todayTasks,
      );
    } catch (_) {
      return BanaOzelFallbackCatalog.build();
    }
  }

  @override
  Future<BanaOzelOpenResultEntity> openItem({
    required BanaOzelItemEntity item,
    bool useAd = false,
  }) =>
      _remote.openItem(item: item, useAd: useAd);
}
