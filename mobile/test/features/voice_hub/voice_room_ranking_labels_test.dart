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

  test('voiceRoomRankingUpdatedLabel relative minutes', () {
    final now = DateTime(2026, 9, 9, 15, 0);
    final label = voiceRoomRankingUpdatedLabel(
      now.subtract(const Duration(minutes: 5)),
      now,
    );
    expect(label, 'Güncellendi · 5 dk önce');
  });

  test('voiceRoomRankingUpdatedLabel az önce', () {
    final now = DateTime(2026, 9, 9, 15, 0);
    final label = voiceRoomRankingUpdatedLabel(
      now.subtract(const Duration(seconds: 20)),
      now,
    );
    expect(label, 'Güncellendi · az önce');
  });
}
