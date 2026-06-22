import 'package:canlifal_social/features/live_psychics/presentation/providers/psychic_live_event_bus.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/psychic_push_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parsePsychicIncomingPayload', () {
    test('recognizes psychic_request_created with nested session', () {
      final invite = parsePsychicIncomingPayload({
        'type': 'psychic_request_created',
        'session': {
          'id': 'sess_psychic_001',
          'clientName': 'Ayşe',
          'status': 'pending',
        },
      });

      expect(invite, isNotNull);
      expect(invite!.sessionId, 'sess_psychic_001');
      expect(invite.clientName, 'Ayşe');
      expect(invite.isPending, isTrue);
    });

    test('recognizes psychic_request_created with sessionId only', () {
      final invite = parsePsychicIncomingPayload({
        'type': 'psychic_request_created',
        'sessionId': 'sess_flat_002',
        'clientName': 'Mehmet',
      });

      expect(invite, isNotNull);
      expect(invite!.sessionId, 'sess_flat_002');
    });

    test('ignores session_ended payloads', () {
      final invite = parsePsychicIncomingPayload({
        'type': 'session_ended',
        'sessionId': 'sess_end',
      });

      expect(invite, isNull);
    });

    test('parses JSON string data envelope from OneSignal', () {
      final invite = parsePsychicIncomingPayload({
        'data': '{"type":"psychic_request_created","sessionId":"sess_json_003"}',
      });

      expect(invite, isNotNull);
      expect(invite!.sessionId, 'sess_json_003');
    });

    test('loose parse uses targetId and fal title', () {
      final invite = parsePsychicIncomingLoose(
        {'targetId': 'sess_loose_004'},
        title: 'Canlı fal isteği: Ayşe',
      );

      expect(invite, isNotNull);
      expect(invite!.sessionId, 'sess_loose_004');
      expect(invite.clientName, 'Ayşe');
      expect(invite.isPending, isTrue);
    });

    test('invite with nested non-pending status stays pending', () {
      final invite = parsePsychicIncomingPayload({
        'type': 'psychic_request_created',
        'session': {'id': 'sess_status', 'status': 'active'},
      });

      expect(invite, isNotNull);
      expect(invite!.isPending, isTrue);
    });
  });

  group('parsePsychicSessionCancelledPayload', () {
    test('matches session_cancelled', () {
      final cancel = parsePsychicSessionCancelledPayload({
        'type': 'psychic_session_cancelled',
        'sessionId': 'sess_cancel_1',
      });

      expect(cancel, isNotNull);
      expect(cancel!.sessionId, 'sess_cancel_1');
      expect(cancel.isCancelled, isTrue);
    });
  });

  group('parsePsychicSsePayload', () {
    test('forces pending for psychic_request_created SSE event', () {
      final invite = parsePsychicSsePayload({
        'type': 'psychic_request_created',
        'event': 'psychic_request_created',
        'session': {
          'id': 'sess_sse_001',
          'status': 'active',
          'clientName': 'Zeynep',
        },
      });

      expect(invite, isNotNull);
      expect(invite!.sessionId, 'sess_sse_001');
      expect(invite.isPending, isTrue);
    });
  });

  group('isPsychicInviteEventType', () {
    test('matches production psychic_request_created', () {
      expect(isPsychicInviteEventType('psychic_request_created'), isTrue);
    });

    test('does not match session_ended', () {
      expect(isPsychicInviteEventType('session_ended'), isFalse);
    });
  });
}
