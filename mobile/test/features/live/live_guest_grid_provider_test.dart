import 'package:canlifal_social/features/live/domain/entities/live_guest_layout.dart';
import 'package:canlifal_social/features/live/presentation/providers/live_guest_grid_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LiveGuestGridNotifier.syncCoBroadcasters', () {
    test('clears guest slots when approved list is empty', () {
      final container = ProviderContainer();
      final notifier = container.read(liveGuestGridProvider.notifier);
      notifier.setLayout(LiveGuestLayout.duo);
      notifier.addGuest(
        slotIndex: 1,
        userId: 'guest1',
        displayName: 'Guest',
        rtcUserId: 'rtc1',
      );

      notifier.syncCoBroadcasters(const []);

      expect(notifier.state.layout, LiveGuestLayout.solo);
      expect(notifier.state.slots.length, 1);
      container.dispose();
    });

    test('uses slotIndex from backend payload', () {
      final container = ProviderContainer();
      final notifier = container.read(liveGuestGridProvider.notifier);
      notifier.setLayout(LiveGuestLayout.duo);

      notifier.syncCoBroadcasters([
        {
          'userId': 'g1',
          'displayName': 'G1',
          'rtcUserId': 'rtc-g1',
          'slotIndex': 1,
          'status': 'joined',
        },
      ]);

      expect(notifier.state.slots[1].userId, 'g1');
      expect(notifier.state.slots[1].rtcUserId, 'rtc-g1');
      container.dispose();
    });

    test('rejects pending guests', () {
      final container = ProviderContainer();
      final notifier = container.read(liveGuestGridProvider.notifier);
      notifier.syncCoBroadcasters([
        {
          'userId': 'pending',
          'status': 'pending',
        },
      ]);
      expect(notifier.state.slots.length, 1);
      expect(notifier.state.slots[0].isHost, isTrue);
      container.dispose();
    });

    test('rejects guests with missing status', () {
      final container = ProviderContainer();
      final notifier = container.read(liveGuestGridProvider.notifier);
      notifier.syncCoBroadcasters([
        {'userId': 'no-status'},
      ]);
      expect(notifier.state.slots.length, 1);
      expect(notifier.state.slots[0].isHost, isTrue);
      container.dispose();
    });
  });
}
