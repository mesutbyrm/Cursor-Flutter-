import 'package:canlifal_social/features/live_psychics/presentation/controllers/psychic_push_action_bridge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    PsychicPushActionBridge.onRespond = null;
  });

  group('PsychicPushActionBridge.handle', () {
    test('maps accept action ids to accept API action', () async {
      String? capturedAction;
      PsychicPushActionBridge.onRespond = (sessionId, action, data) async {
        expect(sessionId, 'sess_push_1');
        capturedAction = action;
      };

      final handled = await PsychicPushActionBridge.handle(
        actionId: 'kabul',
        data: {'sessionId': 'sess_push_1'},
      );

      expect(handled, isTrue);
      expect(capturedAction, 'accept');
    });

    test('maps reject action ids to reject API action', () async {
      String? capturedAction;
      PsychicPushActionBridge.onRespond = (sessionId, action, data) async {
        capturedAction = action;
      };

      final handled = await PsychicPushActionBridge.handle(
        actionId: 'reddet',
        data: {'sessionId': 'sess_push_2'},
      );

      expect(handled, isTrue);
      expect(capturedAction, 'reject');
    });

    test('returns false when handler is not registered', () async {
      final handled = await PsychicPushActionBridge.handle(
        actionId: 'accept',
        data: {'sessionId': 'sess_push_3'},
      );

      expect(handled, isFalse);
    });

    test('returns false for unknown action id', () async {
      PsychicPushActionBridge.onRespond = (_, __, ___) async {};

      final handled = await PsychicPushActionBridge.handle(
        actionId: 'unknown',
        data: {'sessionId': 'sess_push_4'},
      );

      expect(handled, isFalse);
    });
  });
}
