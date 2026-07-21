import 'package:canlifal_social/features/gifts/presentation/sync/gift_session_controller.dart';
import 'package:canlifal_social/features/live/domain/entities/live_gift_event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

LiveGiftEvent _event({
  required String id,
  String senderId = 'u1',
  String giftId = 'heart',
  int jeton = 50,
}) {
  return LiveGiftEvent(
    id: id,
    senderId: senderId,
    senderName: 'Ali',
    receiverName: 'Ayşe',
    giftId: giftId,
    giftName: 'Kalp',
    quantity: 1,
    coinCost: jeton,
    giftPrice: jeton,
    totalCoin: jeton,
    totalDiamond: 0,
    combo: 1,
    timestamp: DateTime.now(),
  );
}

void main() {
  test('combo artar, aynı kullanıcı aynı hediyede yeni satır açmaz', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(giftSessionProvider('room-1').notifier);
    notifier.onGiftSent(_event(id: 'e1'), source: 'test');
    notifier.onGiftSent(_event(id: 'e2'), source: 'test');

    final state = container.read(giftSessionProvider('room-1'));
    expect(state.recentGifts.length, 1);
    expect(state.recentGifts.first.combo, 2);
    expect(state.processedEventIds.length, 2);
  });

  test('duplicate event id yok sayılır', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(giftSessionProvider('room-1').notifier);
    notifier.onGiftSent(_event(id: 'dup'), source: 'test');
    notifier.onGiftSent(_event(id: 'dup'), source: 'test');

    final state = container.read(giftSessionProvider('room-1'));
    expect(state.recentGifts.length, 1);
    expect(state.recentGifts.first.combo, 1);
  });
}
