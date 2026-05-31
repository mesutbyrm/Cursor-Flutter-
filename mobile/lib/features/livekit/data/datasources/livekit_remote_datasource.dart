import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/entities/livekit_credentials.dart';

class LiveKitRemoteDataSource {
  LiveKitRemoteDataSource(this._dio);

  final Dio _dio;

  Future<LiveKitCredentials> fetchToken({
    required String roomId,
    String? roomName,
  }) async {
    final res = await _dio.safePost<Map<String, dynamic>>(
      ApiEndpoints.livekitToken,
      data: {
        'roomId': roomId,
        if (roomName != null) 'roomName': roomName,
      },
    );
    final cred = LiveKitCredentials.fromJson(res.data ?? {});
    if (!cred.isValid) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: 'LiveKit jetonu alınamadı',
      );
    }
    return cred;
  }
}
