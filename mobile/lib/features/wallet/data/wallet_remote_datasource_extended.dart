import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/util/json_util.dart';
import '../domain/platform_commission_rates.dart';
import '../domain/withdrawal_request.dart';

class WalletRemoteDataSourceExtended {
  WalletRemoteDataSourceExtended(this._dio);

  final Dio _dio;

  Future<List<WithdrawalRequest>> fetchWithdrawals() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.withdrawals);
    return _parseWithdrawalList(res.data);
  }

  Future<WithdrawalRequest> requestWithdrawal({
    required double amount,
    required String method,
    required Map<String, dynamic> details,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.withdrawals,
      data: {
        'amount': amount,
        'method': method,
        'details': details,
      },
    );
    final body = res.data;
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      final item = map['withdrawal'] ?? map['data'] ?? map;
      if (item is Map) {
        return WithdrawalRequest.fromJson(Map<String, dynamic>.from(item));
      }
      return WithdrawalRequest.fromJson(map);
    }
    throw const ApiException('Çekim talebi oluşturulamadı.');
  }

  Future<PlatformCommissionRates> fetchCommissionRates() async {
    try {
      final res =
          await _dio.safeGet<dynamic>(ApiEndpoints.platformCommissionRate);
      final body = res.data;
      if (body is Map) {
        final map = body['data'] is Map
            ? Map<String, dynamic>.from(body['data'] as Map)
            : Map<String, dynamic>.from(body);
        return PlatformCommissionRates.fromJson(map);
      }
    } catch (_) {}
    return const PlatformCommissionRates();
  }

  List<WithdrawalRequest> _parseWithdrawalList(dynamic body) {
    dynamic list = body;
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      list = pick(map, ['withdrawals', 'items', 'data', 'requests']) ?? map;
      if (list is Map && list['items'] is List) {
        list = Map<String, dynamic>.from(list as Map)['items'];
      }
    }
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => WithdrawalRequest.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
