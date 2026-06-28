import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/push/push_notification_service.dart';
import '../../live_psychics/domain/entities/psychic_request_entity.dart';
import '../../live_psychics/presentation/providers/psychic_live_event_bus.dart';
import '../domain/video_call_invitation.dart';

/// Gelen görüntülü çağrı davetleri — SSE, push ve 30 sn zaman aşımı.
class VideoCallInvitationService {
  VideoCallInvitationService();

  static const callTimeout = Duration(seconds: 30);

  final _incoming = StreamController<VideoCallInvitation>.broadcast();
  Stream<VideoCallInvitation> get incoming => _incoming.stream;

  final Map<String, Timer> _timeouts = {};
  final Set<String> _activeCallIds = {};

  void handlePsychicRequest(PsychicRequestEntity request) {
    final invite = VideoCallInvitation(
      callId: request.sessionId,
      callerId: request.clientId,
      callerName: request.clientName,
      category: request.fortuneType,
      durationMinutes: request.durationMinutes,
      totalJeton: request.totalJeton,
      sessionId: request.sessionId,
      receivedAt: DateTime.now(),
    );
    enqueue(invite);
  }

  void enqueue(VideoCallInvitation invitation) {
    final id = invitation.callId.trim();
    if (id.isEmpty || _activeCallIds.contains(id)) return;
    _activeCallIds.add(id);
    _startTimeout(id);
    if (!_incoming.isClosed) _incoming.add(invitation);
  }

  void cancel(String callId, {VideoCallResponse reason = VideoCallResponse.reject}) {
    final id = callId.trim();
    _timeouts.remove(id)?.cancel();
    _activeCallIds.remove(id);
    if (reason == VideoCallResponse.missed ||
        reason == VideoCallResponse.timeout) {
      unawaited(_showMissedNotification(id));
    }
  }

  void dispose() {
    for (final t in List.from(_timeouts.values)) {
      t.cancel();
    }
    _timeouts.clear();
    _activeCallIds.clear();
    _incoming.close();
  }

  void _startTimeout(String callId) {
    _timeouts.remove(callId)?.cancel();
    _timeouts[callId] = Timer(callTimeout, () {
      _activeCallIds.remove(callId);
      if (!_incoming.isClosed) {
        _incoming.addError(VideoCallTimeoutException(callId));
      }
      unawaited(_showMissedNotification(callId));
    });
  }

  Future<void> showBackgroundNotification(VideoCallInvitation invite) async {
    if (kIsWeb) return;
    try {
      await PushNotificationService.instance.showLocal(
        id: invite.callId.hashCode,
        title: 'Gelen görüntülü arama',
        body: '${invite.callerName} sizi arıyor',
        payload: invite.callId,
        urgent: true,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('VideoCall notification: $e');
    }
  }

  Future<void> _showMissedNotification(String callId) async {
    if (kIsWeb) return;
    try {
      await PushNotificationService.instance.showLocal(
        id: callId.hashCode,
        title: 'Kaçırılan arama',
        body: 'Görüntülü çağrıyı kaçırdınız',
        payload: callId,
      );
    } catch (_) {}
  }
}

class VideoCallTimeoutException implements Exception {
  VideoCallTimeoutException(this.callId);
  final String callId;

  @override
  String toString() => 'VideoCallTimeoutException($callId)';
}

/// Psychic SSE payload → [VideoCallInvitation].
VideoCallInvitation? videoCallFromPsychicMap(Map<String, dynamic> map) {
  final request = parsePsychicSsePayload(map);
  if (request == null) return null;
  return VideoCallInvitation(
    callId: request.sessionId,
    callerId: request.clientId,
    callerName: request.clientName,
    category: request.fortuneType,
    durationMinutes: request.durationMinutes,
    totalJeton: request.totalJeton,
    sessionId: request.sessionId,
    receivedAt: DateTime.now(),
  );
}
