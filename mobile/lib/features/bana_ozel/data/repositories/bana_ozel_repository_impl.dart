import '../../domain/entities/bana_ozel_entities.dart';
import '../../domain/repositories/bana_ozel_repository.dart';
import '../datasources/bana_ozel_remote_datasource.dart';

class BanaOzelRepositoryImpl implements BanaOzelRepository {
  BanaOzelRepositoryImpl(this._remote);

  final BanaOzelRemoteDataSource _remote;

  @override
  Future<BanaOzelCatalogEntity> fetchCatalog() => _remote.fetchCatalog();

  @override
  Future<BanaOzelOpenResultEntity> openItem({
    required BanaOzelItemEntity item,
  }) =>
      _remote.openItem(item: item);
}
