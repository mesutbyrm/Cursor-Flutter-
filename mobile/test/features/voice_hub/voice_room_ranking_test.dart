import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/live/presentation/providers/discover_voice_rooms.dart';
import 'package:canlifal_social/features/voice_hub/presentation/providers/voice_room_ranking_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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

  test('resolveLiveOnlineCount prefers SSE discover counts', () {
    const room = VoiceRoomEntity(
      id: 'room-a',
      slug: 'room-a',
      nameTr: 'A',
      onlineCount: 3,
    );
    expect(
      resolveLiveOnlineCount(room, {'room-a': 42}),
      42,
    );
    expect(resolveLiveOnlineCount(room, const {}), 3);
  });

  test('buildVoiceRoomRanking uses live presence for score and display', () {
    const room = VoiceRoomEntity(
      id: 'room-live',
      slug: 'room-live',
      nameTr: 'Live',
      onlineCount: 2,
    );
    final ranked = buildVoiceRoomRanking(
      [room],
      livePresenceCounts: {'room-live': 25},
    );
    expect(ranked.single.room.displayOnline, 25);
    expect(ranked.single.score, voiceRoomRankingScore(room, liveOnline: 25));
  });

  test('scoreForRoom returns proxy score from notifier state', () async {
    const room = VoiceRoomEntity(
      id: 'room-score',
      slug: 'room-score',
      nameTr: 'Score',
      onlineCount: 12,
      isPkLive: true,
    );
    final container = ProviderContainer(
      overrides: [
        voiceRoomsProvider.overrideWith((ref) async => [room]),
      ],
    );
    addTearDown(container.dispose);

    await container.read(voiceRoomRankingProvider.notifier).refresh();
    expect(
      container.read(voiceRoomRankingProvider.notifier).scoreForRoom('room-score'),
      170,
    );
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
