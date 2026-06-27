import 'package:canlifal_social/features/voice_hub/domain/entities/voice_room_realtime_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('VoiceRoomRealtimeEvent.append caps feed length', () {
    var list = <VoiceRoomRealtimeEvent>[];
    for (var i = 0; i < VoiceRoomRealtimeEvent.maxFeedItems + 5; i++) {
      list = VoiceRoomRealtimeEvent.append(
        list,
        VoiceRoomRealtimeEvent(
          kind: VoiceRoomRealtimeKind.system,
          message: 'event-$i',
          at: DateTime.now(),
        ),
      );
    }
    expect(list.length, VoiceRoomRealtimeEvent.maxFeedItems);
    expect(list.first.message, 'event-${VoiceRoomRealtimeEvent.maxFeedItems + 4}');
  });
}
