import 'package:dio/dio.dart';

import '../core/network/api_endpoints.dart';
import '../core/network/dio_provider.dart';
import '../core/util/json_util.dart';
import 'service_utils.dart';

/// Ödeme & jeton API — kılavuz §9.12 `PaymentRepository`.
class PaymentService {
  PaymentService({required Dio Function() resolveAuthedDio})
      : _resolveAuthedDio = resolveAuthedDio;

  final Dio Function() _resolveAuthedDio;
  Dio get _dio => _resolveAuthedDio();

  /// `GET /api/credit-packages`
  Future<List<Map<String, dynamic>>> getPackages() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.creditPackages);
    return ServiceUtils.extractList(
      res.data,
      keys: const ['packages', 'items', 'data'],
    );
  }

  /// `GET /api/jeton`
  Future<Map<String, dynamic>> getJeton() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.jetonCatalog);
    return ServiceUtils.unwrapMap(res.data) ?? asJsonMap(res.data);
  }

  /// `POST /api/memberships/purchase`
  Future<Map<String, dynamic>> purchaseMembership({
    required String type,
    String? planId,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.membershipPurchase,
      data: {
        'type': type,
        'planId': planId ?? type,
      },
    );
    return ServiceUtils.unwrapMap(res.data) ?? asJsonMap(res.data);
  }

  /// `GET /api/wallet`
  Future<Map<String, dynamic>> getWallet() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.wallet);
    return ServiceUtils.unwrapMap(res.data) ?? asJsonMap(res.data);
  }
}
