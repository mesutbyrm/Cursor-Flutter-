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
      log('join_start', {'roomId': roomId});

  static void joinSuccess({required String roomId, int? presenceCount}) =>
      log('join_success', {
        'roomId': roomId,
        if (presenceCount != null) 'presenceCount': presenceCount,
      });

  static void leaveStart({required String roomId}) =>
      log('leave_start', {'roomId': roomId});

  static void leaveSuccess({required String roomId}) =>
      log('leave_success', {'roomId': roomId});

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
