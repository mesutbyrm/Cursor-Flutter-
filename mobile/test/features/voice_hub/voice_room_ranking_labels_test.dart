import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/voice_hub/presentation/providers/voice_room_ranking_provider.dart';
import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_ranking_labels.dart';

void main() {
  test('voiceRoomRankingResetLabel hourly mentions minutes', () {
    final label = voiceRoomRankingResetLabel(
      VoiceRoomRankingPeriod.hourly,
      DateTime(2026, 9, 9, 14, 30),
    );
    expect(label, contains('Saatlik sıfırlama'));
    expect(label, contains('dk'));
  });

  test('voiceRoomRankingResetLabel daily mentions reset', () {
    final label = voiceRoomRankingResetLabel(
      VoiceRoomRankingPeriod.daily,
      DateTime(2026, 9, 9, 22, 15),
    );
    expect(label, contains('Günlük sıfırlama'));
  });
}
