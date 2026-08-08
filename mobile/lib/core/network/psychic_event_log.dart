import 'package:flutter/foundation.dart';

/// Canlı fal seansı uçtan uca test izleme — yalnızca debug modda.
abstract final class PsychicEventLog {
  static const _secretKeys = {
    'userSig',
    'token',
    'accessToken',
    'refreshToken',
    'authorization',
    'password',
  };

  static void log(String event, [Map<String, Object?>? data]) {
    if (!kDebugMode) return;
    final safe = _sanitize(data);
    final extra = safe.isEmpty
        ? ''
        : ' ${safe.entries.map((e) => '${e.key}=${e.value}').join(' ')}';
    debugPrint('[PSYCHIC] $event$extra');
  }

  @visibleForTesting
  static Map<String, Object?> sanitize(Map<String, Object?>? data) =>
      _sanitize(data);

  static Map<String, Object?> _sanitize(Map<String, Object?>? data) {
    if (data == null || data.isEmpty) return const {};
    final out = <String, Object?>{};
    for (final entry in data.entries) {
      if (_secretKeys.contains(entry.key)) continue;
      final v = entry.value;
      if (v is String &&
          (v.length > 80 ||
              v.contains('eyJ') && v.split('.').length >= 3)) {
        continue;
      }
      out[entry.key] = v;
    }
    return out;
  }

  static void requestSend({required String sessionId, String? tellerId}) =>
      log('request_send', {
        'sessionId': sessionId,
        if (tellerId != null) 'tellerId': tellerId,
      });

  static void requestReceive({required String sessionId}) =>
      log('request_receive', {'sessionId': sessionId});

  static void accept({required String sessionId}) =>
      log('accept', {'sessionId': sessionId});

  static void reject({required String sessionId}) =>
      log('reject', {'sessionId': sessionId});

  static void sessionCreate({required String sessionId, String? roomId}) =>
      log('session_create', {
        'sessionId': sessionId,
        if (roomId != null) 'roomId': roomId,
      });

  static void joinStart({required String sessionId, required String roomId}) =>
      log('join_start', {'sessionId': sessionId, 'roomId': roomId});

  static void joinSuccess({required String sessionId, required String roomId}) =>
      log('join_success', {'sessionId': sessionId, 'roomId': roomId});

  static void trtcJoin({required String sessionId, required String role}) =>
      log('trtc_join', {'sessionId': sessionId, 'role': role});

  static void localAudio({required bool enabled, required String sessionId}) =>
      log('local_audio', {'enabled': enabled, 'sessionId': sessionId});

  static void localVideo({required bool enabled, required String sessionId}) =>
      log('local_video', {'enabled': enabled, 'sessionId': sessionId});

  static void remoteAudio({
    required String sessionId,
    required String userId,
    required bool available,
  }) =>
      log('remote_audio', {
        'sessionId': sessionId,
        'userId': userId,
        'available': available,
      });

  static void remoteVideo({
    required String sessionId,
    required String userId,
    required bool available,
  }) =>
      log('remote_video', {
        'sessionId': sessionId,
        'userId': userId,
        'available': available,
      });

  static void phase(String from, String to, {String? sessionId}) =>
      log('phase', {
        'from': from,
        'to': to,
        if (sessionId != null) 'sessionId': sessionId,
      });

  static void sessionEnd({required String sessionId, String? reason}) =>
      log('session_end', {
        'sessionId': sessionId,
        if (reason != null) 'reason': reason,
      });

  static void error(String phase, Object error, {String? sessionId}) =>
      log('error', {
        'phase': phase,
        'message': error.toString().split('\n').first,
        if (sessionId != null) 'sessionId': sessionId,
      });
}
