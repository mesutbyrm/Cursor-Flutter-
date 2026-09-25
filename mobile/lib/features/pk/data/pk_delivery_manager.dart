import 'dart:async';
import '../../../core/network/api_exception.dart';
import '../../../core/network/pk_event_log.dart';
import 'pk_models.dart';
import 'pk_service.dart';

/// PK isteği delivery sistemi - karşı tarafa garantili ulaşım.
class PkDeliveryManager {
  PkDeliveryManager(this._pkService);

  final PkService _pkService;

  // In-flight PK requests
  final Map<String, _PkRequestPending> _pending = {};

  // Retry timer
  Timer? _retryTimer;

  /// PK davetini gönder - retry system active.
  Future<PkBattle> sendInvite({
    required String contextId,
    required String targetContextId,
    required String contextKind,
    int durationSeconds = 180,
  }) async {
    final context = contextId.trim();
    final target = targetContextId.trim();

    if (context.isEmpty || target.isEmpty) {
      throw const ApiException('PK context ID boş olamaz');
    }

    PkEventLog.requestStart(
      streamId: contextKind == 'live' ? context : null,
      roomId: contextKind == 'voice' ? context : null,
      targetId: target,
    );

    try {
      final battle = await _pkService.create(
        roomId: context,
        targetRoomId: target,
        durationSeconds: durationSeconds,
      );

      if (battle.id.isEmpty) {
        throw const ApiException('PK ID alınamadı');
      }

      _registerPending(
        battleId: battle.id,
        senderContextId: context,
        receiverContextId: target,
        kind: contextKind,
      );

      _scheduleRetry();

      PkEventLog.log('pk_delivery_sent', {
        'battleId': battle.id,
        'from': context,
        'to': target,
        'kind': contextKind,
      });

      return battle;
    } catch (e) {
      PkEventLog.error('pk_delivery_failed', e);
      rethrow;
    }
  }

  /// SSE event geldiğinde - pending'i doğrula ve kapat.
  void confirmFromSse(String battleId, PkBattle battle) {
    final bid = battleId.trim();
    if (bid.isEmpty) return;

    final pending = _pending[bid];
    if (pending == null) return;

    if (battle.status == PkStatus.pending ||
        battle.status == PkStatus.active) {
      PkEventLog.log('pk_delivery_confirmed_sse', {
        'battleId': bid,
        'status': battle.status.name,
        'from': pending.senderContextId,
        'to': pending.receiverContextId,
      });
      _clearPending(bid);
    }
  }

  /// Pending state'i doğrula.
  bool isPending(String battleId) {
    final bid = battleId.trim();
    return bid.isNotEmpty && _pending.containsKey(bid);
  }

  void _registerPending({
    required String battleId,
    required String senderContextId,
    required String receiverContextId,
    required String kind,
  }) {
    if (battleId.isEmpty) return;
    _pending[battleId] = _PkRequestPending(
      battleId: battleId,
      senderContextId: senderContextId,
      receiverContextId: receiverContextId,
      kind: kind,
      sentAt: DateTime.now(),
      retryCount: 0,
    );
  }

  void _clearPending(String battleId) {
    if (battleId.isEmpty) return;
    _pending.remove(battleId);
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 5), _checkPendingRetry);
  }

  Future<void> _checkPendingRetry() async {
    final now = DateTime.now();
    final maxAge = Duration(seconds: 30);
    final maxRetries = 3;

    final toRetry = <String, _PkRequestPending>{};

    _pending.removeWhere((battleId, pending) {
      final age = now.difference(pending.sentAt);

      if (age.compareTo(maxAge) > 0) {
        PkEventLog.log('pk_delivery_timeout', {
          'battleId': battleId,
          'from': pending.senderContextId,
          'to': pending.receiverContextId,
          'retries': pending.retryCount,
        });
        return true;
      }

      if (pending.retryCount < maxRetries && age.inSeconds > 5) {
        toRetry[battleId] = pending;
      }

      return false;
    });

    for (final entry in toRetry.entries) {
      final battleId = entry.key;
      final pending = entry.value;

      try {
        final current = await _pkService.getState(pending.senderContextId);
        if (current != null && current.id == battleId) {
          confirmFromSse(battleId, current);
          continue;
        }
      } catch (_) {
        // Retry
      }

      pending.retryCount++;
      PkEventLog.log('pk_delivery_retry', {
        'battleId': battleId,
        'attempt': pending.retryCount,
      });
    }

    if (_pending.isNotEmpty) {
      _scheduleRetry();
    }
  }

  void dispose() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _pending.clear();
  }
}

class _PkRequestPending {
  _PkRequestPending({
    required this.battleId,
    required this.senderContextId,
    required this.receiverContextId,
    required this.kind,
    required this.sentAt,
    required this.retryCount,
  });

  final String battleId;
  final String senderContextId;
  final String receiverContextId;
  final String kind;
  final DateTime sentAt;
  int retryCount;
}
