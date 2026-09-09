import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_ranking_sse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isVoiceRoomRankChangedSseEvent matches known aliases', () {
    const positives = [
      'room_rank_changed',
      'ROOM_RANK_CHANGED',
      ' room_rank ',
      'room_rank',
      'roomrankchanged',
      'ranking_updated',
      'room_ranking_updated',
    ];
    for (final ev in positives) {
      expect(isVoiceRoomRankChangedSseEvent(ev), isTrue);
    }
  });

  test('isVoiceRoomRankChangedSseEvent rejects unrelated events', () {
    const negatives = [
      null,
      '',
      '   ',
      'pk_started',
      'gift_ranking_updated',
      'seat_update',
      'user_joined',
    ];
    for (final ev in negatives) {
      expect(isVoiceRoomRankChangedSseEvent(ev), isFalse);
    }
  });
}
