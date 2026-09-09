import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/voice_hub/presentation/providers/voice_room_rank_celebration_provider.dart';
import 'package:canlifal_social/features/voice_hub/presentation/providers/voice_room_ranking_provider.dart';

void main() {
  test('rank celebration fires on rank improvement with cooldown', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(voiceRoomRankCelebrationProvider.notifier);
    const room = VoiceRoomEntity(
      id: 'room-a',
      slug: 'room-a',
      nameTr: 'Oda A',
      onlineCount: 50,
      isPkLive: true,
    );
    final entry = VoiceRoomRankEntry(rank: 2, room: room, score: 520);
    final ranking = VoiceRoomRankingState(
      hourly: [entry],
      daily: [entry],
      lastUpdated: DateTime.now(),
    );

    notifier.evaluate(ranking);
    expect(container.read(voiceRoomRankCelebrationProvider)?.rank, 2);

    notifier.dismiss();
    notifier.evaluate(ranking);
    expect(container.read(voiceRoomRankCelebrationProvider), isNull);
  });

  test('rank celebration ignores same rank repeat', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(voiceRoomRankCelebrationProvider.notifier);
    const room = VoiceRoomEntity(
      id: 'room-b',
      slug: 'room-b',
      nameTr: 'Oda B',
      onlineCount: 30,
    );
    final ranking = VoiceRoomRankingState(
      hourly: [VoiceRoomRankEntry(rank: 1, room: room, score: 300)],
      daily: const [],
      lastUpdated: DateTime.now(),
    );

    notifier.evaluate(ranking);
    expect(container.read(voiceRoomRankCelebrationProvider)?.rank, 1);
    notifier.dismiss();
    notifier.evaluate(ranking);
    expect(container.read(voiceRoomRankCelebrationProvider), isNull);
  });
}
