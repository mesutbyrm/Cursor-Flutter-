import 'package:flutter/foundation.dart';

/// Sesli oda akışı — yapılandırılmış log (kritik olaylar release'te de yazılır).
abstract final class VoiceRoomDebugLog {
  static const _tag = '[VoiceRoom]';

  /// Kritik olaylar her zaman loglanır (TRTC, presence, socket, UI crash).
  static const _alwaysLogPhases = {
    'ui.error',
    'ui.error_widget',
    'ui.zone',
    'ui.flutter',
    'ui.platform',
    'audio.trtc.token',
    'audio.trtc.joined',
    'audio.trtc.fail',
    'audio.trtc.enter_room',
    'api.presence.join',
    'api.presence.join.ok',
    'api.presence.join.fail',
    'api.response',
    'api.error',
    'sse.connecting',
    'sse.stream_open',
    'sse.fail',
    'sse.error',
    'sse.disconnect',
    'socket.connect',
    'socket.connecting',
    'socket.disconnect',
    'socket.disconnect.manual',
    'socket.error',
    'socket.reconnect',
    'jwt.status',
    'route.enter',
    'route.error',
  };

  static void log(String phase, [Map<String, Object?>? data]) {
    final critical = _alwaysLogPhases.contains(phase);
    if (!kDebugMode && !critical) return;
    final extra = data == null || data.isEmpty
        ? ''
        : ' ${data.entries.map((e) => '${e.key}=${e.value}').join(' ')}';
    debugPrint('$_tag $phase$extra');
  }

  static void routeEnter({
    required String roomId,
    String? slug,
    String source = 'unknown',
  }) {
    log('route.enter', {
      'roomId': roomId,
      'slug': slug ?? '',
      'source': source,
    });
  }

  static void jwtStatus({required bool hasToken, int? tokenLength}) {
    log('jwt.status', {
      'hasToken': hasToken,
      if (tokenLength != null) 'len': tokenLength,
    });
  }

  static void apiResponse({
    required String method,
    required String path,
    int? status,
    Object? summary,
    int? elapsedMs,
  }) {
    log('api.response', {
      'method': method,
      'path': path,
      if (status != null) 'status': status,
      if (summary != null) 'body': summary,
      if (elapsedMs != null) 'ms': elapsedMs,
    });
  }

  static void recordFlutterError(Object error, StackTrace? stack) {
    log('ui.flutter', {
      'error': error.toString(),
      if (stack != null) 'stack': stack.toString().split('\n').take(3).join(' | '),
    });
  }

  static void recordPlatformError(Object error, StackTrace stack) {
    log('ui.platform', {
      'error': error.toString(),
      'stack': stack.toString().split('\n').take(3).join(' | '),
    });
  }

  static void recordZoneError(Object error, StackTrace stack) {
    log('ui.zone', {
      'error': error.toString(),
      'stack': stack.toString().split('\n').take(3).join(' | '),
    });
  }
}
