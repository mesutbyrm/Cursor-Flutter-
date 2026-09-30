import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/voice_hub/presentation/providers/pk_battle_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('applyAudienceSupport respects per-user budget', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(pkBattleProvider.notifier);
    notifier.init(
      room: const VoiceRoomEntity(id: 'room1', slug: 'room1', nameTr: 'Test'),
      presence: const [],
      durationSeconds: 60,
    );
    expect(
      notifier.applyAudienceSupport(
        battleId: 'b1',
        userId: 'viewer',
        points: 3,
      ),
      isTrue,
    );
    expect(
      notifier.applyAudienceSupport(
        battleId: 'b1',
        userId: 'viewer',
        points: 3,
      ),
      isFalse,
    );
    expect(notifier.audienceSupportRemaining('b1', 'viewer'), 0);
    final state = container.read(pkBattleProvider);
    expect(state.left.audienceSupport, 3);
    expect(state.left.total, 3);
  });
}
