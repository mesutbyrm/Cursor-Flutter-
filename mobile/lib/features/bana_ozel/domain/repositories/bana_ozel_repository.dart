import '../entities/bana_ozel_entities.dart';

abstract class BanaOzelRepository {
  Future<BanaOzelCatalogEntity> fetchCatalog();

  Future<BanaOzelOpenResultEntity> openItem({
    required BanaOzelItemEntity item,
  });
}
