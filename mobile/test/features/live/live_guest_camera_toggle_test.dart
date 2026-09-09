import 'package:canlifal_social/features/live/domain/entities/live_guest_layout.dart';
import 'package:canlifal_social/features/live/presentation/providers/live_guest_grid_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toggleGuestCamera flips cameraOn on slot', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(liveGuestGridProvider.notifier);
    notifier.setLayout(LiveGuestLayout.duo);
    notifier.addGuest(
      slotIndex: 1,
      userId: 'u2',
      displayName: 'Konuk',
    );
    expect(container.read(liveGuestGridProvider).slots[1].cameraOn, isTrue);
    notifier.toggleGuestCamera(1);
    expect(container.read(liveGuestGridProvider).slots[1].cameraOn, isFalse);
    notifier.toggleGuestCamera(1);
    expect(container.read(liveGuestGridProvider).slots[1].cameraOn, isTrue);
  });
}
