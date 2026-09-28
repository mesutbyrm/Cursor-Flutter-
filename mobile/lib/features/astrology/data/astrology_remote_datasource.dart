import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/util/json_util.dart';
import '../domain/entities/zodiac_sign.dart';

final astrologyRemoteDataSourceProvider = Provider<AstrologyRemoteDataSource>(
  (ref) => AstrologyRemoteDataSource(ref.watch(dioProvider)),
);

class AstrologyRemoteDataSource {
  AstrologyRemoteDataSource(this._dio);

  final Dio _dio;

  /// `POST /api/compatibility` — AI analizi; yanıt süresi uzun olabilir.
  Future<String> compatibility(ZodiacSign a, ZodiacSign b) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.compatibility,
      data: {'sign1': a.turkishName, 'sign2': b.turkishName},
      options: Options(receiveTimeout: const Duration(seconds: 90)),
    );
    return asJsonMap(res.data)['analysis']?.toString() ?? '';
  }
}
