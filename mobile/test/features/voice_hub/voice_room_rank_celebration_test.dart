import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/voice_hub/presentation/providers/voice_room_rank_celebration_provider.dart';
import 'package:canlifal_social/features/voice_hub/presentation/providers/voice_room_ranking_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('evaluate does not celebrate on bootstrap load', () {
    final container = ProviderContainer();
    final notifier =
        container.read(voiceRoomRankCelebrationProvider.notifier);
    const room = VoiceRoomEntity(
      id: 'r1',
      slug: 'r1',
      nameTr: 'Test',
    );
    notifier.evaluate(
      VoiceRoomRankingState(
        hourly: [
          VoiceRoomRankEntry(room: room, rank: 1, score: 100),
        ],
        daily: const [],
        lastUpdated: DateTime.now(),
      ),
    );
    expect(container.read(voiceRoomRankCelebrationProvider), isNull);
    container.dispose();
  });

  test('evaluate celebrates top 3 once per hour boundary session', () {
    final container = ProviderContainer();
    final notifier =
        container.read(voiceRoomRankCelebrationProvider.notifier);
    const room = VoiceRoomEntity(
      id: 'r1',
      slug: 'r1',
      nameTr: 'CanlıFal',
    );
    final ranking = VoiceRoomRankingState(
      hourly: [
        VoiceRoomRankEntry(room: room, rank: 2, score: 100),
      ],
      daily: const [],
      lastUpdated: DateTime.now(),
    );
    notifier.evaluate(ranking, trigger: RankCelebrationTrigger.hourBoundary);
    final first = container.read(voiceRoomRankCelebrationProvider);
    expect(first, isNotNull);
    expect(first!.rank, 2);
    expect(first.roomName, 'CanlıFal');

    notifier.evaluate(ranking, trigger: RankCelebrationTrigger.hourBoundary);
    expect(container.read(voiceRoomRankCelebrationProvider), first);
    container.dispose();
  });
}
