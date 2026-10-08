import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/trtc/presentation/trtc_room_manager.dart';
import 'package:canlifal_social/features/voice_hub/presentation/audio/voice_trtc_engine.dart';

void main() {
  group('TrtcRoomManager native ownership (VOICE-002)', () {
    test('no active session → any manager may drive native', () {
      final a = TrtcRoomManager();
      expect(TrtcRoomManager.ownsNative(null, a), isTrue);
    });

    test('only the active session owns native', () {
      final a = TrtcRoomManager();
      final b = TrtcRoomManager();
      expect(TrtcRoomManager.ownsNative(a, a), isTrue);
      expect(TrtcRoomManager.ownsNative(a, b), isFalse);
    });

    test('operation gate is shared across instances', () async {
      final gate = TrtcRoomManager.sharedGateForTest;
      expect(identical(gate, TrtcRoomManager.sharedGateForTest), isTrue);
      final order = <String>[];
      final first = gate.run(() async {
        order.add('voice:start');
        await Future<void>.delayed(const Duration(milliseconds: 20));
        order.add('voice:end');
      });
      final second = gate.run(() async => order.add('live:start'));
      await Future.wait([first, second]);
      expect(order, ['voice:start', 'voice:end', 'live:start']);
    });
  });

  group('Mic defaults (VOICE-001 / VOICE-005)', () {
    test('fresh manager is not capturing audio', () {
      expect(TrtcRoomManager().micOn, isFalse);
    });

    test('switchRole is refused outside a room', () async {
      final m = TrtcRoomManager();
      expect(await m.setAnchorPublishing(true), isFalse);
      expect(m.micOn, isFalse);
    });

    test('engine mic state mirrors the manager and stays off before join',
        () async {
      final engine = VoiceTrtcEngine();
      expect(engine.micOn, isFalse);
      await engine.setMicEnabled(true);
      expect(engine.micOn, isFalse);
      expect(engine.manager.micOn, isFalse);
    });

    test('leave clears external onUserVoiceVolume hook', () async {
      final m = TrtcRoomManager();
      var calls = 0;
      m.onUserVoiceVolume = (_, __) => calls++;
      await m.leave();
      expect(m.onUserVoiceVolume, isNull);
      m.onUserVoiceVolume?.call([], 0);
      expect(calls, 0);
    });
  });
}
