import 'package:flutter/foundation.dart';

/// PK uçtan uca test izleme — yalnızca debug modda.
abstract final class PkEventLog {
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
    debugPrint('[PK] $event$extra');
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

  static void requestStart({String? streamId, String? roomId, String? targetId}) =>
      log('request_start', {
        if (streamId != null) 'streamId': streamId,
        if (roomId != null) 'roomId': roomId,
        if (targetId != null) 'targetId': targetId,
      });

  static void requestSuccess({String? matchId, String? battleId}) =>
      log('request_success', {
        if (matchId != null) 'matchId': matchId,
        if (battleId != null) 'battleId': battleId,
      });

  static void incomingRequest({String? matchId, String? inviteId}) =>
      log('incoming_request', {
        if (matchId != null) 'matchId': matchId,
        if (inviteId != null) 'inviteId': inviteId,
      });

  static void acceptStart({String? matchId, String? inviteId}) =>
      log('accept_start', {
        if (matchId != null) 'matchId': matchId,
        if (inviteId != null) 'inviteId': inviteId,
      });

  static void acceptSuccess({String? matchId, String? battleId}) =>
      log('accept_success', {
        if (matchId != null) 'matchId': matchId,
        if (battleId != null) 'battleId': battleId,
      });

  static void reject({String? matchId, String? inviteId}) =>
      log('reject', {
        if (matchId != null) 'matchId': matchId,
        if (inviteId != null) 'inviteId': inviteId,
      });

  static void connecting({String? roomId, String? streamId}) =>
      log('connecting', {
        if (roomId != null) 'roomId': roomId,
        if (streamId != null) 'streamId': streamId,
      });

  static void connected({String? roomId, String? streamId}) =>
      log('connected', {
        if (roomId != null) 'roomId': roomId,
        if (streamId != null) 'streamId': streamId,
      });

  static void remoteJoined({required String userId}) =>
      log('remote_joined', {'userId': userId});

  static void reconnecting({String? context}) =>
      log('reconnecting', {if (context != null) 'context': context});

  static void ending({String? matchId, String? battleId}) =>
      log('ending', {
        if (matchId != null) 'matchId': matchId,
        if (battleId != null) 'battleId': battleId,
      });

  static void ended({String? matchId, String? battleId, String? reason}) =>
      log('ended', {
        if (matchId != null) 'matchId': matchId,
        if (battleId != null) 'battleId': battleId,
        if (reason != null) 'reason': reason,
      });

  static void error(String phase, Object error) =>
      log('error', {
        'phase': phase,
        'message': error.toString().split('\n').first,
      });
}
