import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/voice_hub/presentation/providers/voice_room_ranking_provider.dart';
import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_discover_ranking.dart';

void main() {
  test('orderDiscoverRoomsByProxyRanking prefers SSE live counts', () {
    const a = VoiceRoomEntity(
      id: 'a',
      slug: 'a',
      nameTr: 'A',
      onlineCount: 5,
    );
    const b = VoiceRoomEntity(
      id: 'b',
      slug: 'b',
      nameTr: 'B',
      onlineCount: 2,
      isPkLive: true,
    );
    final ordered = orderDiscoverRoomsByProxyRanking(
      [a, b],
      livePresenceCounts: {'b': 40},
    );
    expect(ordered.first.id, 'b');
  });

  test('discoverHourlyRankForRoom returns rank within badge cap', () {
    const room = VoiceRoomEntity(
      id: 'room-x',
      slug: 'room-x',
      nameTr: 'X',
      onlineCount: 10,
    );
    final hourly = [
      VoiceRoomRankEntry(rank: 1, room: room, score: 100),
    ];
    expect(discoverHourlyRankForRoom('room-x', hourly), 1);
    expect(discoverHourlyRankForRoom('missing', hourly), isNull);
  });

  test('pickDiscoverPresenceTrackRooms dedupes and caps', () {
    const a = VoiceRoomEntity(id: '1', slug: '1', nameTr: 'A');
    const b = VoiceRoomEntity(id: '2', slug: '2', nameTr: 'B');
    const c = VoiceRoomEntity(id: '3', slug: '3', nameTr: 'C');
    final picked = pickDiscoverPresenceTrackRooms(
      spotlight: [a, b],
      visible: [a, c],
      maxRooms: 2,
    );
    expect(picked.length, 2);
    expect(picked.map((r) => r.id).toList(), ['1', '2']);
  });
}
