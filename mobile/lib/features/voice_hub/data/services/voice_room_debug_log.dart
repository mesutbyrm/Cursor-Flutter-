import 'package:flutter/foundation.dart';

/// Sesli oda akışı — yapılandırılmış log (kritik olaylar release'te de yazılır).
abstract final class VoiceRoomDebugLog {
  static const _tag = '[VoiceRoom]';

  static var _roomJoinCount = 0;
  static var _roomLeaveCount = 0;
  static var _sseConnectCount = 0;
  static var _sseDisconnectCount = 0;
  static var _sseReconnectCount = 0;

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
    'ROOM JOIN',
    'ROOM LEAVE',
    'SSE CONNECT',
    'SSE DISCONNECT',
    'SSE RECONNECT',
    'PRESENCE UPDATE',
    'SEAT UPDATE',
    'DJ UPDATE',
    'DJ EVENT RECEIVED',
    'MUSIC START',
    'MUSIC STOP',
    'MUSIC ERROR',
    'api.presence.join',
    'api.presence.join.ok',
    'api.presence.join.fail',
    'api.presence.heartbeat',
    'api.response',
    'api.error',
    'sse.connecting',
    'sse.stream_open',
    'sse.fail',
    'sse.error',
    'sse.disconnect',
    'sse.reconnect_scheduled',
    'sse.dj',
    'socket.connect',
    'socket.connecting',
    'socket.disconnect',
    'socket.disconnect.manual',
    'socket.error',
    'socket.reconnect',
    'jwt.status',
    'route.enter',
    'route.error',
    'music.player.started',
    'music.player.failed',
    'music.player.no_stream',
  };

  static void log(String phase, [Map<String, Object?>? data]) {
    final critical = _alwaysLogPhases.contains(phase);
    if (!kDebugMode && !critical) return;
    final extra = data == null || data.isEmpty
        ? ''
        : ' ${data.entries.map((e) => '${e.key}=${e.value}').join(' ')}';
    debugPrint('$_tag $phase$extra');
  }

  static void roomJoin({
    required String roomId,
    String source = 'presence',
    bool skipped = false,
  }) {
    if (!skipped) _roomJoinCount++;
    log('ROOM JOIN', {
      'roomId': roomId,
      'source': source,
      'count': _roomJoinCount,
      if (skipped) 'skipped': true,
    });
  }

  static void roomLeave({
    required String roomId,
    String source = 'dispose',
  }) {
    _roomLeaveCount++;
    log('ROOM LEAVE', {
      'roomId': roomId,
      'source': source,
      'count': _roomLeaveCount,
    });
  }

  static void sseConnect({required String roomId, String? url}) {
    _sseConnectCount++;
    log('SSE CONNECT', {
      'roomId': roomId,
      'count': _sseConnectCount,
      'url': ?url,
    });
  }

  static void sseDisconnect({String? roomId, String reason = 'manual'}) {
    _sseDisconnectCount++;
    log('SSE DISCONNECT', {
      'roomId': ?roomId,
      'reason': reason,
      'count': _sseDisconnectCount,
    });
  }

  static void sseReconnect({
    required String roomId,
    required int attempt,
    required int delaySec,
  }) {
    _sseReconnectCount++;
    log('SSE RECONNECT', {
      'roomId': roomId,
      'attempt': attempt,
      'delaySec': delaySec,
      'count': _sseReconnectCount,
    });
  }

  static void presenceUpdate({
    required String roomId,
    required int previousCount,
    required int incomingCount,
    required int mergedCount,
    String source = 'sse',
  }) {
    log('PRESENCE UPDATE', {
      'roomId': roomId,
      'source': source,
      'prev': previousCount,
      'incoming': incomingCount,
      'merged': mergedCount,
    });
  }

  static void seatUpdate({
    required String roomId,
    required int seatCount,
    String source = 'presence',
  }) {
    log('SEAT UPDATE', {
      'roomId': roomId,
      'source': source,
      'seats': seatCount,
    });
  }

  static void djUpdate({
    required String roomId,
    bool? playing,
    String? musicUrl,
    String? videoId,
    String? title,
    String source = 'sse',
  }) {
    log('DJ UPDATE', {
      'roomId': roomId,
      'source': source,
      'playing': playing,
      'musicUrl': musicUrl == null
          ? '(null)'
          : (musicUrl.length > 120
              ? '${musicUrl.substring(0, 117)}…'
              : musicUrl),
      'videoId': videoId ?? '(null)',
      'title': title ?? '(null)',
    });
    log('DJ EVENT RECEIVED', {
      'playing': playing,
      'musicUrl': musicUrl == null || musicUrl.isEmpty ? '(empty)' : 'set',
      'videoId': videoId ?? '(null)',
      'title': title ?? '(null)',
    });
  }

  static void musicStart({
    String? videoId,
    String? title,
    String? streamUrl,
  }) {
    log('MUSIC START', {
      'videoId': ?videoId,
      'title': ?title,
      if (streamUrl != null) 'stream': _shortUrl(streamUrl),
    });
  }

  static void musicStop({String? reason}) {
    log('MUSIC STOP', {'reason': ?reason});
  }

  static void musicError({
    required String phase,
    Object? error,
    String? url,
    String? videoId,
  }) {
    log('MUSIC ERROR', {
      'phase': phase,
      if (error != null) 'error': error.toString(),
      if (url != null) 'url': _shortUrl(url),
      'videoId': ?videoId,
    });
  }

  static String _shortUrl(String url) {
    if (url.length <= 120) return url;
    return '${url.substring(0, 117)}…';
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
      'len': ?tokenLength,
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
      'status': ?status,
      'body': ?summary,
      'ms': ?elapsedMs,
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
