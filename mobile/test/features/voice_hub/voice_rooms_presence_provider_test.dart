import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/features/voice_hub/presentation/providers/voice_rooms_presence_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VoiceRoomsPresenceNotifier', () {
    test('build starts with empty state and no connected rooms', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(voiceRoomsPresenceProvider);

      expect(state.counts, isEmpty);
      expect(state.connectedRooms, isEmpty);
    });

    test('homeTrackedRooms is lower than maxTrackedRooms', () {
      expect(
        VoiceRoomsPresenceNotifier.homeTrackedRooms,
        lessThan(VoiceRoomsPresenceNotifier.maxTrackedRooms),
      );
    });
  });
}
