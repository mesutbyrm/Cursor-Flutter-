import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import 'package:dio/dio.dart';

import '../domain/girlive_publisher_assistant_models.dart';

class GirLivePublisherAssistantDataSource {
  GirLivePublisherAssistantDataSource(this._dio);

  final Dio _dio;

  /// `scope`: `session` | `day` | `week` | `month`
  Future<GirLivePublisherAssistantReport?> fetchReport({
    required String roomId,
    String scope = 'session',
    String? sessionId,
  }) async {
    final id = roomId.trim();
    if (id.isEmpty) return null;
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.chatRoomGirLivePublisherAssistant(id),
        query: {
          'scope': scope,
          if (sessionId != null && sessionId.trim().isNotEmpty)
            'sessionId': sessionId.trim(),
        },
      );
      final data = res.data;
      if (data is! Map) return null;
      final report = data['report'] ?? data;
      if (report is! Map) return null;
      return GirLivePublisherAssistantReport.fromJson(
        Map<String, dynamic>.from(report),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<GirLivePublisherAssistantReport?> fetchEndReport({
    required String roomId,
    String? sessionId,
  }) async {
    final id = roomId.trim();
    if (id.isEmpty) return null;
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.chatRoomGirLivePublisherEndReport(id),
        query: {
          if (sessionId != null && sessionId.trim().isNotEmpty)
            'sessionId': sessionId.trim(),
        },
      );
      final data = res.data;
      if (data is! Map) return null;
      final report = data['report'] ?? data;
      if (report is! Map) return null;
      return GirLivePublisherAssistantReport.fromJson(
        Map<String, dynamic>.from(report),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}
