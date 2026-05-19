import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/entities/trtc_credentials.dart';

class TrtcRemoteDataSource {
  TrtcRemoteDataSource(this._dio);

  final Dio _dio;

  Future<TrtcCredentials> fetchUserSig({
    required String userId,
    required String roomId,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.trtcUserSig,
      data: {'userId': userId, 'roomId': roomId},
    );
    final body = res.data;
    if (body is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: 'Geçersiz TRTC yanıtı',
      );
    }
    return TrtcCredentials.fromJson(body);
  }
}
