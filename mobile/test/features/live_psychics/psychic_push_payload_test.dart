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
