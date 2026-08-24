import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/bana_ozel_entities.dart';

class BanaOzelRemoteDataSource {
  BanaOzelRemoteDataSource(this._dio);

  final Dio _dio;

  Future<BanaOzelCatalogEntity> fetchCatalog() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.banaOzel);
    return BanaOzelCatalogEntity.fromJson(asJsonMap(res.data));
  }

  Future<BanaOzelOpenResultEntity> openItem({
    required BanaOzelItemEntity item,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.banaOzelOpen,
        data: {'slug': item.slug},
      );
      final body = asJsonMap(res.data);
      final err = pick(body, ['error', 'message'])?.toString();
      if (err != null && err.trim().isNotEmpty) {
        throw ApiException(err);
      }
      return BanaOzelOpenResultEntity.fromJson(body, item: item);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
