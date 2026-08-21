import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/voice_hub/domain/pk/pk_battle_mode.dart';
import 'package:canlifal_social/features/voice_hub/presentation/providers/pk_battle_provider.dart';

void main() {
  test('pkBattleProvider starts active phase and disposes cleanly', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(pkBattleProvider.notifier).init(
          room: const VoiceRoomEntity(
            id: 'room-1',
            slug: 'room-1',
            nameTr: 'Test',
          ),
          presence: const [],
          durationSeconds: 5,
        );
    expect(container.read(pkBattleProvider).phase, PkBattlePhase.active);
    expect(container.read(pkBattleProvider).secondsLeft, 5);
  });
}
