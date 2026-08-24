import 'package:flutter/foundation.dart';

/// Canlı yayın uçtan uca test izleme — yalnızca debug modda.
///
/// Secret/token değerleri asla loglanmaz.
abstract final class LiveEventLog {
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
    debugPrint('[LIVE] $event$extra');
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

  static void createStart({String? title}) =>
      log('create_start', {if (title != null) 'title': title});

  static void createSuccess({required String streamId}) =>
      log('create_success', {'streamId': streamId});

  static void joinStart({required String streamId, required bool isHost}) =>
      log('join_start', {'streamId': streamId, 'isHost': isHost});

  static void joinSuccess({required String streamId, required bool isHost}) =>
      log('join_success', {'streamId': streamId, 'isHost': isHost});

  static void trtcJoin({required String streamId, required String role}) =>
      log('trtc_join', {'streamId': streamId, 'role': role});

  static void localAudio({required bool enabled, String? streamId}) =>
      log('local_audio', {
        'enabled': enabled,
        if (streamId != null) 'streamId': streamId,
      });

  static void localVideo({required bool enabled, String? streamId}) =>
      log('local_video', {
        'enabled': enabled,
        if (streamId != null) 'streamId': streamId,
      });

  static void viewerJoined({required String streamId, String? userId}) =>
      log('viewer_joined', {
        'streamId': streamId,
        if (userId != null && userId.isNotEmpty) 'userId': userId,
      });

  static void viewerLeft({required String streamId, String? userId}) =>
      log('viewer_left', {
        'streamId': streamId,
        if (userId != null && userId.isNotEmpty) 'userId': userId,
      });

  static void heartbeat({required String streamId}) =>
      log('heartbeat', {'streamId': streamId});

  static void leave({required String streamId, required bool isHost}) =>
      log('leave', {'streamId': streamId, 'isHost': isHost});

  static void ended({required String streamId, String? reason}) =>
      log('ended', {
        'streamId': streamId,
        if (reason != null) 'reason': reason,
      });

  static void error(String phase, Object error, {String? streamId}) =>
      log('error', {
        'phase': phase,
        'message': error.toString().split('\n').first,
        if (streamId != null) 'streamId': streamId,
      });
}
