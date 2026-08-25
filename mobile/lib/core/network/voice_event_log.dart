import 'package:flutter/foundation.dart';

/// Sesli oda uçtan uca test izleme — yalnızca debug modda.
abstract final class VoiceEventLog {
  static const _secretKeys = {
    'userSig',
    'token',
    'accessToken',
    'refreshToken',
    'authorization',
  };

  static void log(String event, [Map<String, Object?>? data]) {
    if (!kDebugMode) return;
    final safe = _sanitize(data);
    final extra = safe.isEmpty
        ? ''
        : ' ${safe.entries.map((e) => '${e.key}=${e.value}').join(' ')}';
    debugPrint('[VOICE] $event$extra');
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

  static void roomListLoad({int? page, int? count}) => log('room_list_load', {
        if (page != null) 'page': page,
        if (count != null) 'count': count,
      });

  static void joinStart({required String roomId}) =>
      log('room_join_start', {'roomId': roomId});

  static void joinSuccess({required String roomId, int? presenceCount}) =>
      log('room_join_success', {
        'roomId': roomId,
        if (presenceCount != null) 'presenceCount': presenceCount,
      });

  static void joinFailed({required String roomId, Object? error}) =>
      log('room_join_failed', {
        'roomId': roomId,
        if (error != null) 'message': error.toString().split('\n').first,
      });

  static void leaveStart({required String roomId}) =>
      log('leave_start', {'roomId': roomId});

  static void leaveSuccess({required String roomId}) =>
      log('leave_success', {'roomId': roomId});

  static void socketConnected({required String roomId}) =>
      log('socket_connected', {'roomId': roomId});

  static void socketDisconnected({required String roomId, String? reason}) =>
      log('socket_disconnected', {
        'roomId': roomId,
        if (reason != null) 'reason': reason,
      });

  static void socketReconnected({required String roomId}) =>
      log('socket_reconnected', {'roomId': roomId});

  static void presenceRegistered({required String roomId, String? userId}) =>
      log('presence_registered', {
        'roomId': roomId,
        if (userId != null) 'userId': userId,
      });

  static void presenceRemoved({required String roomId, String? userId}) =>
      log('presence_removed', {
        'roomId': roomId,
        if (userId != null) 'userId': userId,
      });

  static void membershipLoaded({String? tier}) =>
      log('membership_loaded', {if (tier != null) 'tier': tier});

  static void roomThemeLoaded({String? roomId, String? theme}) =>
      log('room_theme_loaded', {
        if (roomId != null) 'roomId': roomId,
        if (theme != null) 'theme': theme,
      });

  static void entryEffectStarted({String? userId, String? tier}) =>
      log('entry_effect_started', {
        if (userId != null) 'userId': userId,
        if (tier != null) 'tier': tier,
      });

  static void entryEffectFinished({String? userId}) =>
      log('entry_effect_finished', {if (userId != null) 'userId': userId});

  static void trtcConnecting({required String roomId}) =>
      log('trtc_connecting', {'roomId': roomId});

  static void trtcConnected({required String roomId}) =>
      log('trtc_connected', {'roomId': roomId});

  static void seatTake({required String roomId, required int seatIndex}) =>
      log('seat_take', {'roomId': roomId, 'seatIndex': seatIndex});

  static void seatLeave({required String roomId}) =>
      log('seat_leave', {'roomId': roomId});

  static void heartbeat({required String roomId}) =>
      log('heartbeat', {'roomId': roomId});

  static void presenceUpdate({required String roomId, required int count}) =>
      log('presence_update', {'roomId': roomId, 'count': count});

  static void error(String phase, Object error) => log('error', {
        'phase': phase,
        'message': error.toString().split('\n').first,
      });
}
