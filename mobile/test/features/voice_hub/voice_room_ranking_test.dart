import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/voice_hub/presentation/providers/voice_room_ranking_provider.dart';

void main() {
  test('buildVoiceRoomRanking sorts by score and caps at 100', () {
    final rooms = List.generate(
      120,
      (i) => VoiceRoomEntity(
        id: 'room-$i',
        slug: 'room-$i',
        nameTr: 'Oda $i',
        onlineCount: i,
        isPkLive: i % 10 == 0,
      ),
    );
    final ranked = buildVoiceRoomRanking(rooms, limit: 100);
    expect(ranked.length, 100);
    expect(ranked.first.rank, 1);
    expect(ranked.first.score, greaterThan(ranked.last.score));
  });

  test('voiceRoomRankingScore adds PK and music bonus', () {
    const base = VoiceRoomEntity(
      id: 'a',
      slug: 'a',
      nameTr: 'A',
      onlineCount: 10,
    );
    const pk = VoiceRoomEntity(
      id: 'b',
      slug: 'b',
      nameTr: 'B',
      onlineCount: 10,
      isPkLive: true,
    );
    expect(voiceRoomRankingScore(pk), greaterThan(voiceRoomRankingScore(base)));
  });
}
