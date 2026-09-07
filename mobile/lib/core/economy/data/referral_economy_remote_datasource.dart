import 'package:dio/dio.dart';

import '../../network/api_endpoints.dart';
import '../../network/dio_provider.dart';
import '../../util/json_util.dart';
import '../domain/agency_invite_earnings_snapshot.dart';
import '../domain/referral_economy_snapshot.dart';

class ReferralEconomyRemoteDataSource {
  ReferralEconomyRemoteDataSource(this._dio);

  final Dio _dio;

  Future<ReferralEconomySnapshot?> fetchUserReferralEarnings({
    int limit = 25,
    int offset = 0,
    String? type,
  }) async {
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.userReferralEarnings,
        query: {
          'limit': limit,
          'offset': offset,
          if (type != null && type.isNotEmpty) 'type': type,
        },
      );
      final body = res.data;
      if (body is! Map) return null;
      final map = asJsonMap(body);
      if (map['error'] != null && map['summary'] == null) return null;
      return ReferralEconomySnapshot.fromJson(map);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401 || code == 404 || code == 405) return null;
      rethrow;
    } catch (_) {
      return null;
    }
  }

  Future<AgencyInviteEarningsSnapshot?> fetchAgencyInviteEarnings({
    int limit = 25,
    int offset = 0,
  }) async {
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.agencyInviteEarnings,
        query: {
          'limit': limit,
          'offset': offset,
        },
      );
      final body = res.data;
      if (body is! Map) return null;
      final map = asJsonMap(body);
      if (map['error'] != null && map['agency'] == null && map['totalEarnings'] == null) {
        return null;
      }
      return AgencyInviteEarningsSnapshot.fromJson(map);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401 || code == 404 || code == 405) return null;
      rethrow;
    } catch (_) {
      return null;
    }
  }
}
