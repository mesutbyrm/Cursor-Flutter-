import 'package:dio/dio.dart';

import '../../../../core/economy/domain/economy_payment_models.dart';
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
    bool useAd = false,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.banaOzelOpen,
        data: {
          'slug': item.slug,
          if (useAd) 'useAd': true,
        },
      );
      final body = asJsonMap(res.data);
      final err = pick(body, ['error', 'message'])?.toString();
      if (err != null && err.trim().isNotEmpty && !body.containsKey('content')) {
        throw ApiException(err);
      }
      return BanaOzelOpenResultEntity.fromJson(body, item: item);
    } on DioException catch (e) {
      if (e.response?.statusCode == 402) {
        final data = e.response?.data;
        if (data is Map) {
          throw BanaOzelInsufficientPayment.fromJson(asJsonMap(data));
        }
      }
      throw ApiException.fromDio(e);
    }
  }
}
