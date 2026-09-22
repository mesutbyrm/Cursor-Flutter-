import 'package:canlifal_social/features/live_psychics/domain/psychic_timer_handshake.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PsychicTimerHandshake.tellerShouldSendRequest', () {
    test('teller sends once when client present and timer not started', () {
      expect(
        PsychicTimerHandshake.tellerShouldSendRequest(
          isClient: false,
          timerStarted: false,
          requestAlreadySent: false,
          peerPresent: true,
        ),
        isTrue,
      );
    });

    test('client never sends the request', () {
      expect(
        PsychicTimerHandshake.tellerShouldSendRequest(
          isClient: true,
          timerStarted: false,
          requestAlreadySent: false,
          peerPresent: true,
        ),
        isFalse,
      );
    });

    test('no request before peer joins the room', () {
      expect(
        PsychicTimerHandshake.tellerShouldSendRequest(
          isClient: false,
          timerStarted: false,
          requestAlreadySent: false,
          peerPresent: false,
        ),
        isFalse,
      );
    });

    test('not sent twice', () {
      expect(
        PsychicTimerHandshake.tellerShouldSendRequest(
          isClient: false,
          timerStarted: false,
          requestAlreadySent: true,
          peerPresent: true,
        ),
        isFalse,
      );
    });

    test('no request once timer already started', () {
      expect(
        PsychicTimerHandshake.tellerShouldSendRequest(
          isClient: false,
          timerStarted: true,
          requestAlreadySent: false,
          peerPresent: true,
        ),
        isFalse,
      );
    });
  });

  group('PsychicTimerHandshake.clientShouldPrompt', () {
    test('client prompts once before timer starts', () {
      expect(
        PsychicTimerHandshake.clientShouldPrompt(
          isClient: true,
          timerStarted: false,
          promptAlreadyShown: false,
        ),
        isTrue,
      );
    });

    test('teller never prompts', () {
      expect(
        PsychicTimerHandshake.clientShouldPrompt(
          isClient: false,
          timerStarted: false,
          promptAlreadyShown: false,
        ),
        isFalse,
      );
    });

    test('no prompt if already shown or timer started', () {
      expect(
        PsychicTimerHandshake.clientShouldPrompt(
          isClient: true,
          timerStarted: false,
          promptAlreadyShown: true,
        ),
        isFalse,
      );
      expect(
        PsychicTimerHandshake.clientShouldPrompt(
          isClient: true,
          timerStarted: true,
          promptAlreadyShown: false,
        ),
        isFalse,
      );
    });
  });

  group('PsychicTimerHandshake.tellerShouldStartTimer', () {
    test('teller starts timer on accept when not started', () {
      expect(
        PsychicTimerHandshake.tellerShouldStartTimer(
          isClient: false,
          timerStarted: false,
        ),
        isTrue,
      );
    });

    test('client cannot start timer; no double start', () {
      expect(
        PsychicTimerHandshake.tellerShouldStartTimer(
          isClient: true,
          timerStarted: false,
        ),
        isFalse,
      );
      expect(
        PsychicTimerHandshake.tellerShouldStartTimer(
          isClient: false,
          timerStarted: true,
        ),
        isFalse,
      );
    });
  });

  group('PsychicTimerHandshake.shouldGateMedia', () {
    test('media gated until timer starts', () {
      expect(PsychicTimerHandshake.shouldGateMedia(timerStarted: false), isTrue);
      expect(PsychicTimerHandshake.shouldGateMedia(timerStarted: true), isFalse);
    });
  });

  group('PsychicTimerHandshake.signalMatches', () {
    test('matches root type and nested action', () {
      expect(
        PsychicTimerHandshake.signalMatches(
          {'type': 'timer_start_request'},
          PsychicTimerHandshake.signalRequest,
        ),
        isTrue,
      );
      expect(
        PsychicTimerHandshake.signalMatches(
          {
            'type': 'room_signal',
            'data': {'action': 'timer_start_accept'},
          },
          PsychicTimerHandshake.signalAccept,
        ),
        isTrue,
      );
      expect(
        PsychicTimerHandshake.signalMatches(
          {'type': 'tip'},
          PsychicTimerHandshake.signalRequest,
        ),
        isFalse,
      );
    });
  });

  group('signal type names are distinct and non-overlapping', () {
    test('request/accept do not substring-collide', () {
      expect(
        PsychicTimerHandshake.signalRequest
            .contains(PsychicTimerHandshake.signalAccept),
        isFalse,
      );
      expect(
        PsychicTimerHandshake.signalAccept
            .contains(PsychicTimerHandshake.signalRequest),
        isFalse,
      );
    });
  });
}
