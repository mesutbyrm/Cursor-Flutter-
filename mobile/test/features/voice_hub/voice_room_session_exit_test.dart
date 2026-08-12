import 'package:canlifal_social/features/voice_hub/domain/entities/voice_room_realtime_event.dart';
import 'package:canlifal_social/features/voice_hub/presentation/providers/chat_room_providers.dart';
import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_session_exit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detectExitMessage on room_closed state', () {
    const prev = VoiceRoomLiveState(selfInRoom: true, presence: []);
    const next = VoiceRoomLiveState(
      selfInRoom: false,
      presence: [],
      error: 'Oda kapatıldı',
    );
    expect(
      VoiceRoomSessionExit.detectExitMessage(prev: prev, next: next),
      'Oda kapatıldı',
    );
  });

  test('detectExitMessage on ban moderation event', () {
    const prev = VoiceRoomLiveState(realtimeEvents: []);
    final next = VoiceRoomLiveState(
      realtimeEvents: [
        VoiceRoomRealtimeEvent(
          kind: VoiceRoomRealtimeKind.moderation,
          message: 'Odadan yasaklandınız',
          at: DateTime(2026, 8, 12),
        ),
      ],
    );
    expect(
      VoiceRoomSessionExit.detectExitMessage(prev: prev, next: next),
      'Odadan yasaklandınız',
    );
  });

  test('isTerminalError matches ban and closure messages', () {
    expect(VoiceRoomSessionExit.isTerminalError('Bu odadan yasaklandınız'), isTrue);
    expect(VoiceRoomSessionExit.isTerminalError('Oda kapatıldı'), isTrue);
    expect(VoiceRoomSessionExit.isTerminalError('Bağlantı zaman aşımı'), isFalse);
  });
}
