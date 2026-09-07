import 'package:dio/dio.dart';

import '../../network/api_endpoints.dart';
import '../../network/dio_provider.dart';
import '../../util/json_util.dart';
import '../domain/currency_branding_snapshot.dart';

class CurrencyBrandingRemoteDataSource {
  CurrencyBrandingRemoteDataSource(this._dio);

  final Dio _dio;

  Future<CurrencyBrandingSnapshot?> fetchBranding() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.currencyBranding);
      final body = res.data;
      if (body is! Map) return null;
      final map = asJsonMap(body);
      if (map['error'] != null && map['jeton'] == null) return null;
      return CurrencyBrandingSnapshot.fromJson(map);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    } catch (_) {
      return null;
    }
  }
}
