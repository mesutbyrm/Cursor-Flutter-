import 'package:dio/dio.dart';
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
    'audio.trtc.joined',
    'audio.trtc.fail',
    'audio.agora.prepare',
    'audio.agora.initialized',
    'audio.agora.joined',
    'audio.agora.fail',
    'audio.agora.error',
    'audio.agora.left',
    'audio.trtc.enter_room',
    'ROOM JOIN',
    'ROOM LEAVE',
    'ROOM_LEAVE',
    'ROOM_LIFECYCLE',
    'ROOM_CALLBACK',
    'SEAT_REQUEST',
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
    'JOIN_INTENT',
    'JOIN_START',
    'JOIN_SUCCESS',
    'PRESENCE_JOIN',
    'SSE_START',
    'TRTC_START',
    'LEAVE_START',
    'LEAVE_UI',
    'LEAVE_SUMMARY_SKIPPED',
    'LEAVE_FAILED',
    'ROUTE_LEFT_VOICE_ROOM',
    'LEAVE_COMPLETE',
    'BLOCKED_IMPLICIT_JOIN',
    'api.presence.heartbeat',
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
    'route.enter',
    'route.error',
    'music.player.started',
    'music.player.failed',
    'music.player.no_stream',
    // Sürüm derlemesinde de görünür — 403 sonrası istek kesildi kanıtı.
    'VOICE_BLOCKED_403',
    'SPEAK_REQUESTS_BLOCKED_403',
    'VOICE_JOIN_SKIPPED_NO_SEAT',
    'PRESENCE_SNAPSHOT_EMPTY_IGNORED',
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

  static void joinIntent({required String roomId, String source = 'user'}) {
    log('JOIN_INTENT', {'roomId': roomId, 'source': source});
  }

  static void joinStart({required String roomId}) {
    log('JOIN_START', {'roomId': roomId});
  }

  static void joinSuccess({required String roomId}) {
    log('JOIN_SUCCESS', {'roomId': roomId});
  }

  static void presenceJoinPhase({required String roomId}) {
    log('PRESENCE_JOIN', {'roomId': roomId});
  }

  static void sseStart({required String roomId}) {
    log('SSE_START', {'roomId': roomId});
  }

  static void trtcStart({required String roomId}) {
    log('TRTC_START', {'roomId': roomId});
  }

  static void leaveStart({required String roomId, String source = 'ui'}) {
    log('LEAVE_START', {'roomId': roomId, 'source': source});
  }

  static void leaveComplete({required String roomId}) {
    log('LEAVE_COMPLETE', {'roomId': roomId});
  }

  static void blockedImplicitJoin({
    required String reason,
    required String roomId,
  }) {
    log('BLOCKED_IMPLICIT_JOIN', {'reason': reason, 'roomId': roomId});
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
      if (stack != null) 'stack': stackSummary(stack),
    });
  }

  static void recordPlatformError(Object error, StackTrace stack) {
    log('ui.platform', {
      'error': describeError(error),
      'stack': stackSummary(stack),
    });
  }

  static void recordZoneError(Object error, StackTrace stack) {
    log('ui.zone', {
      'error': describeError(error),
      'stack': stackSummary(stack),
    });
  }

  /// DioException için yöntem + yol + durum (sorgu dizesi/başlık yok → token
  /// sızmaz). Önceden yalnız "status code of 401" yazıyor, uç bilinmiyordu.
  @visibleForTesting
  static String describeError(Object error) {
    if (error is DioException) {
      final o = error.requestOptions;
      final status = error.response?.statusCode;
      return 'DioException[${error.type.name}] ${o.method} ${o.uri.path}'
          '${status != null ? ' status=$status' : ''}';
    }
    return error.toString();
  }

  /// Obfuscated release yığını: `flutter symbolize` için gereken başlık
  /// (`*** ***`, os/arch, `build_id`, `*_dso_base`) + ilk çerçeveler (`#00 abs …`).
  /// ` | ` yerine satır sonu koyup CI sembolleriyle çözülebilir. Önceden yalnız
  /// ilk 3 başlık satırı yazılıyor, çerçeve hiç yoktu.
  @visibleForTesting
  static String stackSummary(StackTrace stack, {int maxFrames = 12}) {
    final lines = stack
        .toString()
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final frames = lines.where((l) => l.startsWith('#')).take(maxFrames).toList();
    if (frames.isEmpty || !lines.first.startsWith('***')) {
      return lines.take(3).join(' | ');
    }
    final header = lines.where((l) => !l.startsWith('#')).take(8);
    return [...header, ...frames].join(' | ');
  }
}
