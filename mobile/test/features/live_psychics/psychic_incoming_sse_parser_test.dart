import 'package:canlifal_social/features/live_psychics/data/services/psychic_incoming_sse_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parsePsychicIncomingSsePayload', () {
    test('connected event emits pending session requests', () {
      final events = parsePsychicIncomingSsePayload(
        {
          'type': 'connected',
          'pendingSessions': [
            {
              'type': 'psychic_request_created',
              'sessionId': 'sess_conn_001',
              'clientName': 'Ayşe',
            },
          ],
        },
        eventName: 'connected',
      );

      expect(events, hasLength(1));
      final sessionEvents = events.whereType<PsychicIncomingSessionRequests>();
      expect(sessionEvents, hasLength(1));
      expect(sessionEvents.first.requests, hasLength(1));
      expect(sessionEvents.first.requests.first.sessionId, 'sess_conn_001');
      expect(sessionEvents.first.requests.first.isPending, isTrue);
    });

    test('pending_sessions event parses sessions list', () {
      final events = parsePsychicIncomingSsePayload(
        {
          'type': 'pending_sessions',
          'sessions': [
            {
              'sessionId': 'sess_pending_001',
              'clientName': 'Mehmet',
              'status': 'pending',
            },
            {
              'sessionId': 'sess_pending_002',
              'clientName': 'Zeynep',
              'status': 'pending',
            },
          ],
        },
        eventName: 'pending_sessions',
      );

      expect(events, hasLength(1));
      final requests = (events.first as PsychicIncomingSessionRequests).requests;
      expect(requests, hasLength(2));
      expect(requests.map((r) => r.sessionId), ['sess_pending_001', 'sess_pending_002']);
    });

    test('raw pending list payload parses when event name contains pending', () {
      final events = parsePsychicIncomingSsePayload(
        [
          {
            'type': 'psychic_request_created',
            'sessionId': 'sess_list_001',
            'clientName': 'Deniz',
          },
        ],
        eventName: 'pending_sessions',
      );

      expect(events, hasLength(1));
      final requests = (events.first as PsychicIncomingSessionRequests).requests;
      expect(requests, hasLength(1));
      expect(requests.first.sessionId, 'sess_list_001');
    });

    test('presence tick for online/offline/status events', () {
      for (final type in ['online', 'offline', 'presence_tick', 'status_update']) {
        final events = parsePsychicIncomingSsePayload({'type': type});
        expect(events, hasLength(1), reason: 'type=$type');
        expect(events.first, isA<PsychicIncomingPresenceTick>());
      }
    });

    test('cancel events emit session cancelled', () {
      for (final type in ['session_cancelled', 'session_rejected', 'rejected']) {
        final events = parsePsychicIncomingSsePayload({
          'type': type,
          'sessionId': 'sess_cancel_$type',
        });
        expect(events, hasLength(1), reason: 'type=$type');
        expect(
          (events.first as PsychicIncomingSessionCancelled).sessionId,
          'sess_cancel_$type',
        );
      }
    });

    test('psychic_request_created emits pending session request', () {
      final events = parsePsychicIncomingSsePayload({
        'type': 'psychic_request_created',
        'session': {
          'id': 'sess_req_001',
          'clientName': 'Elif',
          'status': 'pending',
        },
      });

      expect(events, hasLength(1));
      final requests = (events.first as PsychicIncomingSessionRequests).requests;
      expect(requests, hasLength(1));
      expect(requests.first.sessionId, 'sess_req_001');
      expect(requests.first.clientName, 'Elif');
    });

    test('ignores non-pending sessions in pending list', () {
      final events = parsePsychicIncomingSsePayload(
        {
          'type': 'pending_sessions',
          'sessions': [
            {
              'sessionId': 'sess_active_001',
              'status': 'active',
            },
          ],
        },
        eventName: 'pending_sessions',
      );

      expect(events, isEmpty);
    });
  });
}
