import 'package:canlifal_social/features/voice_hub/domain/entities/voice_room_realtime_event.dart';
import 'package:canlifal_social/features/voice_hub/presentation/providers/chat_room_providers.dart';
import 'package:canlifal_social/features/voice_hub/presentation/providers/voice_room_live_side_effect_slices.dart';
import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_session_exit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detectExitFromSignals ban on new moderation head event', () {
    final prev = (
      error: null,
      selfInRoom: true,
      presenceCount: 2,
      realtimeEventCount: 0,
      headEventKind: null,
      headEventMessage: null,
    );
    final next = (
      error: null,
      selfInRoom: true,
      presenceCount: 2,
      realtimeEventCount: 1,
      headEventKind: VoiceRoomRealtimeKind.moderation,
      headEventMessage: 'Bu odadan yasaklandınız',
    );
    expect(
      VoiceRoomSessionExit.detectExitFromSignals(prev: prev, next: next),
      'Bu odadan yasaklandınız',
    );
  });

  test('voiceRoomExitSignalsSlice stable for empty state', () {
    final slice = voiceRoomExitSignalsSlice(const VoiceRoomLiveState());
    expect(slice.realtimeEventCount, 0);
    expect(slice.selfInRoom, isFalse);
  });
}
