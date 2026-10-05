import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/voice_hub/domain/pk/pk_battle_remote_models.dart';
import 'package:canlifal_social/features/voice_hub/presentation/providers/pk_battle_provider.dart';

void main() {
  test('serverAuthoritative uses single countdown path (endsAt sync)', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final endsAt = DateTime.now().toUtc().add(const Duration(seconds: 4));
    final battle = PkBattleRemote(
      id: 'pk-timer-1',
      battleType: 'voice',
      status: 'active',
      challengerScore: 10,
      opponentScore: 5,
      secondsLeft: 600,
      durationSeconds: 300,
      targetScore: 0,
      voiceRoomId: 'room-x',
      endsAt: endsAt,
      serverNow: DateTime.now().toUtc().toIso8601String(),
    );

    final notifier = container.read(pkBattleProvider.notifier);
    notifier.applyRemoteBattleForVoiceRoom(
      battle,
      const VoiceRoomEntity(id: 'room-x', slug: 'room-x', nameTr: 'X'),
    );

    expect(container.read(pkBattleProvider).serverAuthoritative, isTrue);
    expect(container.read(pkBattleProvider).secondsLeft, lessThanOrEqualTo(4));

    await Future<void>.delayed(const Duration(milliseconds: 1200));
    expect(container.read(pkBattleProvider).secondsLeft, lessThanOrEqualTo(3));
  });

  test('local init countdown decrements without serverAuthoritative', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(pkBattleProvider.notifier);
    notifier.init(
      room: const VoiceRoomEntity(id: 'r', slug: 'r', nameTr: 'R'),
      presence: const [],
      durationSeconds: 3,
    );

    expect(container.read(pkBattleProvider).serverAuthoritative, isFalse);
    expect(container.read(pkBattleProvider).secondsLeft, 3);

    await Future<void>.delayed(const Duration(milliseconds: 2100));
    expect(container.read(pkBattleProvider).secondsLeft, lessThanOrEqualTo(1));
  });
}
