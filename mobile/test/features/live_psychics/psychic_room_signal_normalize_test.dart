import 'package:canlifal_social/features/live_psychics/domain/psychic_room_signal_normalize.dart';
import 'package:canlifal_social/features/live_psychics/domain/psychic_timer_handshake.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizePsychicRoomSignalMap', () {
    test('maps production signalType and signalData', () {
      final norm = normalizePsychicRoomSignalMap({
        'id': 'sig_1',
        'signalType': 'timer_start_request',
        'signalData': {'action': 'timer_start_request'},
      });

      expect(norm['type'], 'timer_start_request');
      expect(norm['data'], isA<Map>());
      expect(
        PsychicTimerHandshake.signalMatches(
          norm,
          PsychicTimerHandshake.signalRequest,
        ),
        isTrue,
      );
    });

    test('parses string signalData JSON', () {
      final norm = normalizePsychicRoomSignalMap({
        'signalType': 'timer_start_accept',
        'signalData': '{"action":"timer_start_accept"}',
      });

      expect(norm['type'], 'timer_start_accept');
      expect(
        PsychicTimerHandshake.signalMatches(
          norm,
          PsychicTimerHandshake.signalAccept,
        ),
        isTrue,
      );
    });
  });
}
