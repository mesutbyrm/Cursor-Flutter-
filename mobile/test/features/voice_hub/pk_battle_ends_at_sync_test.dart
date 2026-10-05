
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/voice_hub/domain/pk/pk_battle_remote_models.dart';
import 'package:canlifal_social/features/voice_hub/presentation/providers/pk_battle_provider.dart';

void main() {
  test('serverAuthoritative battle syncs secondsLeft from endsAt each second',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final endsAt = DateTime.now().toUtc().add(const Duration(seconds: 3));
    final battle = PkBattleRemote(
      id: 'pk-1',
      battleType: 'voice',
      status: 'active',
      challengerScore: 0,
      opponentScore: 0,
      secondsLeft: 999,
      durationSeconds: 300,
      targetScore: 0,
      voiceRoomId: 'room-a',
      endsAt: endsAt,
      serverNow: DateTime.now().toUtc().toIso8601String(),
    );

    container.read(pkBattleProvider.notifier).applyRemoteBattleForVoiceRoom(
          battle,
          const VoiceRoomEntity(id: 'room-a', slug: 'room-a', nameTr: 'A'),
        );

    expect(container.read(pkBattleProvider).secondsLeft, lessThanOrEqualTo(3));
    expect(container.read(pkBattleProvider).serverAuthoritative, isTrue);

    await Future<void>.delayed(const Duration(milliseconds: 1100));
    final after = container.read(pkBattleProvider).secondsLeft;
    expect(after, lessThanOrEqualTo(2));
  });
}
