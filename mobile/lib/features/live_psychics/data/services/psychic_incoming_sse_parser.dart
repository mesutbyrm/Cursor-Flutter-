import '../../domain/entities/psychic_request_entity.dart';
import '../../presentation/providers/psychic_live_event_bus.dart';
import '../../presentation/providers/psychic_push_payload.dart';

/// Falcı gelen istek SSE bloğu — test edilebilir ayrıştırma.
sealed class PsychicIncomingSseEvent {
  const PsychicIncomingSseEvent();
}

class PsychicIncomingPresenceTick extends PsychicIncomingSseEvent {
  const PsychicIncomingPresenceTick();
}

class PsychicIncomingSessionRequests extends PsychicIncomingSseEvent {
  const PsychicIncomingSessionRequests(this.requests);

  final List<PsychicRequestEntity> requests;
}

class PsychicIncomingSessionCancelled extends PsychicIncomingSseEvent {
  const PsychicIncomingSessionCancelled(this.sessionId);

  final String sessionId;
}

List<PsychicIncomingSseEvent> parsePsychicIncomingSsePayload(
  dynamic decoded, {
  String? eventName,
}) {
  if (decoded is List) {
    final event = (eventName ?? '').toLowerCase();
    if (event.contains('pending')) {
      final requests = _pendingRequestsFromList(decoded);
      if (requests.isNotEmpty) {
        return [PsychicIncomingSessionRequests(requests)];
      }
    }
    return const [];
  }
  if (decoded is! Map) return const [];

  final map = Map<String, dynamic>.from(decoded);
  if (eventName != null && eventName.isNotEmpty) {
    map.putIfAbsent('event', () => eventName);
    map.putIfAbsent('type', () => eventName);
  }

  final type = (map['type'] ?? eventName ?? '').toString().toLowerCase();
  final events = <PsychicIncomingSseEvent>[];

  if (type.contains('connected')) {
    final pending = map['pendingSessions'] ?? map['pending_sessions'];
    if (pending is List) {
      final requests = _pendingRequestsFromList(pending);
      if (requests.isNotEmpty) {
        events.add(PsychicIncomingSessionRequests(requests));
      }
    }
  }

  if (type == 'pending_sessions' || eventName == 'pending_sessions') {
    final sessions = map['sessions'] ?? map['pendingSessions'];
    if (sessions is List) {
      final requests = _pendingRequestsFromList(sessions);
      if (requests.isNotEmpty) {
        events.add(PsychicIncomingSessionRequests(requests));
      }
    }
    return events;
  }

  if (type.contains('online') ||
      type.contains('offline') ||
      type.contains('presence') ||
      type.contains('status')) {
    events.add(const PsychicIncomingPresenceTick());
  }

  if (type.contains('cancel') ||
      type == 'rejected' ||
      type == 'session_cancelled' ||
      type == 'session_rejected') {
    final sessionId = (map['sessionId'] ??
            map['id'] ??
            (map['session'] is Map ? (map['session'] as Map)['id'] : null))
        ?.toString()
        .trim();
    if (sessionId != null && sessionId.isNotEmpty) {
      events.add(PsychicIncomingSessionCancelled(sessionId));
    }
    return events;
  }

  if (type.contains('request') ||
      type.contains('session') ||
      type.contains('invite') ||
      map.containsKey('sessionId') ||
      map.containsKey('request') ||
      map.containsKey('session')) {
    final req =
        parsePsychicIncomingPayload(map) ?? parsePsychicSsePayload(map);
    if (req != null && req.sessionId.isNotEmpty) {
      if (req.isPending) {
        events.add(PsychicIncomingSessionRequests([req]));
      } else if (!req.isPending &&
          (type.contains('cancel') || type.contains('reject'))) {
        events.add(PsychicIncomingSessionCancelled(req.sessionId));
      }
    }
  }

  return events;
}

List<PsychicRequestEntity> _pendingRequestsFromList(List<dynamic> sessions) {
  final out = <PsychicRequestEntity>[];
  for (final item in sessions) {
    if (item is! Map) continue;
    final req = parsePsychicIncomingPayload(
          Map<String, dynamic>.from(item),
        ) ??
        parsePsychicSsePayload(Map<String, dynamic>.from(item));
    if (req != null && req.sessionId.isNotEmpty && req.isPending) {
      out.add(req);
    }
  }
  return out;
}
