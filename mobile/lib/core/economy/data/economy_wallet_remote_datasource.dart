import 'package:dio/dio.dart';

import '../../network/api_endpoints.dart';
import '../../network/dio_provider.dart';
import '../../util/json_util.dart';
import '../domain/economy_wallet_snapshot.dart';

class EconomyWalletRemoteDataSource {
  EconomyWalletRemoteDataSource(this._dio);

  final Dio _dio;

  Future<EconomyWalletSnapshot?> fetchWallet({
    int limit = 25,
    int offset = 0,
    String currency = 'all',
  }) async {
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.userWallet,
        query: {
          'limit': limit,
          'offset': offset,
          'currency': currency,
        },
      );
      final body = res.data;
      if (body is! Map) return null;
      final map = asJsonMap(body);
      if (map['error'] != null && map['balances'] == null) return null;
      return EconomyWalletSnapshot.fromJson(map);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401 || code == 404 || code == 405) return null;
      rethrow;
    } catch (_) {
      return null;
    }
  }
}
