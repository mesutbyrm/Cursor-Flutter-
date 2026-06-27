import 'package:dio/dio.dart';

import '../../features/voice_hub/data/services/voice_room_debug_log.dart';

/// Sesli oda REST çağrılarını loglar (`/api/chat/rooms`, `/api/trtc/usersig`).
class VoiceRoomApiLogInterceptor extends Interceptor {
  static bool _isVoicePath(String path) {
    final p = path.toLowerCase();
    return p.contains('/chat/rooms') ||
        p.contains('/trtc/usersig') ||
        p.contains('/trtc/');
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_isVoicePath(options.path)) {
      options.extra['_voiceRoomStarted'] = DateTime.now();
      final hasAuth = options.headers['Authorization'] != null;
      VoiceRoomDebugLog.jwtStatus(hasToken: hasAuth);
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final path = response.requestOptions.path;
    if (_isVoicePath(path)) {
      final started = response.requestOptions.extra['_voiceRoomStarted'];
      final ms = started is DateTime
          ? DateTime.now().difference(started).inMilliseconds
          : null;
      VoiceRoomDebugLog.apiResponse(
        method: response.requestOptions.method,
        path: path,
        status: response.statusCode,
        summary: _summarize(response.data),
        elapsedMs: ms,
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final path = err.requestOptions.path;
    if (_isVoicePath(path)) {
      VoiceRoomDebugLog.log('api.error', {
        'method': err.requestOptions.method,
        'path': path,
        'status': err.response?.statusCode,
        'message': err.message ?? err.toString(),
      });
    }
    handler.next(err);
  }

  static String _summarize(dynamic data) {
    if (data is Map) {
      final keys = data.keys.take(6).join(',');
      if (data['success'] == true && data['data'] is Map) {
        final inner = data['data'] as Map;
        return 'success keys=${inner.keys.take(8).join(',')}';
      }
      return 'keys=$keys';
    }
    if (data is List) return 'list len=${data.length}';
    return data?.runtimeType.toString() ?? 'null';
  }
}
