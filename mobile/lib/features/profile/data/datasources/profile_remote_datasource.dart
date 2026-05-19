import 'package:dio/dio.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../../auth/data/models/user_dto.dart';
import '../../../auth/domain/entities/user_entity.dart';

class ProfileRemoteDataSource {
  ProfileRemoteDataSource(this._dio);

  final Dio _dio;

  Future<UserEntity> user(String userId) async {
    final res = await _dio.safeGet<Map<String, dynamic>>(
      ApiEndpoints.userProfile(userId),
    );
    final body = res.data ?? {};
    final u = pick(body, ['user', 'data', 'profile']);
    final map = u is Map ? asJsonMap(u) : body;
    return UserDto.fromJson(map).toEntity();
  }

  /// canlifal.com oturumlu kullanıcı — takipçi, bio, avatar (NextAuth çerezi).
  Future<UserEntity> mySiteProfile() async {
    final res = await _dio.safeGet<Map<String, dynamic>>(
      ApiEndpoints.userSiteProfile,
    );
    final body = res.data ?? {};
    final err = body['error'];
    if (err != null) {
      throw ApiException(err.toString());
    }
    return UserDto.fromSiteProfileMap(body).toEntity();
  }

  Future<void> follow(String userId) async {
    await _dio.safePost(ApiEndpoints.follow(userId));
  }

  Future<void> unfollow(String userId) async {
    await _dio.safeDelete(ApiEndpoints.follow(userId));
  }
}

class WalletRemoteDataSource {
  WalletRemoteDataSource(this._dio);

  final Dio _dio;

  Future<int> balance() async {
    if (Env.useNextAuth) {
      final res = await _dio.safeGet<Map<String, dynamic>>(
        ApiEndpoints.userCredits,
      );
      final body = res.data ?? {};
      final err = body['error'];
      if (err != null) {
        throw ApiException(err.toString());
      }
      return asInt(
        pick(body, [
          'credits',
          'balance',
          'coins',
          'coinBalance',
          'amount',
          'credit',
        ]),
      );
    }
    final res = await _dio.safeGet<Map<String, dynamic>>(ApiEndpoints.wallet);
    final body = res.data ?? {};
    final v = pick(body, ['balance', 'coins', 'coinBalance', 'amount']);
    return asInt(v);
  }
}
