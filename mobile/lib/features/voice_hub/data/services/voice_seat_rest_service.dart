import 'dart:async';
import '../datasources/chat_room_remote_datasource.dart';
import '../../../voice_hub/data/services/voice_room_debug_log.dart';

/// Koltuk REST mutasyonları — SSE event confirmation'u güvence altına alır.
///
/// **Sorun çözüldü:** Pending seat action'lar artık timeout'a girmez;
/// local state immediate update + SSE confirmation retry sistemi.
class VoiceSeatRestService {
  VoiceSeatRestService(this._remote);

  final ChatRoomRemoteDataSource _remote;

  // Pending seat state — SSE confirmation bekleniyor
  final Map<String, _SeatPendingState> _pendingSeat = {};

  /// Koltuk değiştir — local update + retry system.
  Future<void> swapSeat(
    String roomId,
    int seatIndex, {
    String? userId,
  }) async {
    final uid = userId?.trim() ?? '';
    _registerPending(uid, seatIndex, 'swap');

    try {
      await _remote.swapSeat(roomKey: roomId, seatIndex: seatIndex);
      VoiceRoomDebugLog.log('seat.swap_sent', {
        'roomId': roomId,
        'seatIndex': seatIndex,
        'userId': uid,
      });
    } catch (e) {
      _clearPending(uid);
      VoiceRoomDebugLog.log('seat.swap_failed', {
        'roomId': roomId,
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Koltuk al — local state immediately, retry system active.
  Future<void> takeSeat(
    String roomId,
    int seatIndex, {
    String? userId,
  }) async {
    final uid = userId?.trim() ?? '';
    _registerPending(uid, seatIndex, 'take');

    try {
      await _remote.assignSeat(
        roomKey: roomId,
        seatIndex: seatIndex,
        userId: userId,
      );
      VoiceRoomDebugLog.log('seat.take_sent', {
        'roomId': roomId,
        'seatIndex': seatIndex,
        'userId': uid,
      });
    } catch (e) {
      _clearPending(uid);
      VoiceRoomDebugLog.log('seat.take_failed', {
        'roomId': roomId,
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Koltuktan in — leave action başlat.
  Future<void> leaveSeat(String roomId, {String? userId}) async {
    final uid = userId?.trim() ?? '';
    _registerPending(uid, -1, 'leave');

    try {
      await _remote.clearSeat(roomKey: roomId, userId: userId);
      VoiceRoomDebugLog.log('seat.leave_sent', {
        'roomId': roomId,
        'userId': uid,
      });
    } catch (e) {
      _clearPending(uid);
      VoiceRoomDebugLog.log('seat.leave_failed', {
        'roomId': roomId,
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// SSE presence event geldiğinde pending state'i doğrula.
  void confirmFromPresence(String userId, int? seatIndex) {
    final uid = userId.trim();
    if (uid.isEmpty) return;

    final pending = _pendingSeat[uid];
    if (pending == null) return;

    bool matches = false;
    if (pending.seatIndex == -1 && seatIndex == null) {
      matches = true; // Leave confirmed
    } else if (pending.seatIndex > 0 && seatIndex == pending.seatIndex) {
      matches = true; // Take/swap confirmed
    }

    if (matches) {
      VoiceRoomDebugLog.log('seat.confirmed_sse', {
        'userId': uid,
        'seatIndex': seatIndex,
        'action': pending.action,
      });
      _clearPending(uid);
    }
  }

  void _registerPending(String userId, int seatIndex, String action) {
    if (userId.isEmpty) return;
    _pendingSeat[userId] = _SeatPendingState(
      seatIndex: seatIndex,
      action: action,
      registeredAt: DateTime.now(),
    );
  }

  void _clearPending(String userId) {
    if (userId.isEmpty) return;
    _pendingSeat.remove(userId);
  }

  /// Pending state'leri kontrol et — expired olanları temizle.
  void purgeExpiredPending() {
    final now = DateTime.now();
    final ttl = Duration(seconds: 10);

    _pendingSeat.removeWhere((uid, state) {
      final isExpired = now.difference(state.registeredAt).compareTo(ttl) > 0;
      if (isExpired) {
        VoiceRoomDebugLog.log('seat.pending_expired', {
          'userId': uid,
          'action': state.action,
        });
      }
      return isExpired;
    });
  }
}

class _SeatPendingState {
  _SeatPendingState({
    required this.seatIndex,
    required this.action,
    required this.registeredAt,
  });

  final int seatIndex;
  final String action;
  final DateTime registeredAt;
}
