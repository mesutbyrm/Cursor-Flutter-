import 'package:canlifal_social/features/live/domain/entities/live_gift_event.dart';
import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_presence.dart';
import 'package:canlifal_social/features/voice_hub/domain/pk/pk_battle_mode.dart';
import 'package:canlifal_social/features/voice_hub/presentation/providers/pk_battle_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prepareShell starts with zero scores (no fake hash scores)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const room = VoiceRoomEntity(id: 'r1', slug: 'r1', nameTr: 'Oda');
    const left = ChatRoomPresence(id: 'u-left', name: 'Sol');
    const right = ChatRoomPresence(id: 'u-right', name: 'Sağ');

    container.read(pkBattleProvider.notifier).prepareShell(
          room: room,
          presence: const [left, right],
          left: left,
          right: right,
          mode: PkBattleMode.oneVsOne,
        );

    final pk = container.read(pkBattleProvider);
    expect(pk.left.score, 0);
    expect(pk.right.score, 0);
    expect(pk.left.winStreak, 0);
    expect(pk.right.winStreak, 0);
  });

  test('giftSideResolvable uses receiver id not hash parity', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const room = VoiceRoomEntity(id: 'r1', slug: 'r1', nameTr: 'Oda');
    const left = ChatRoomPresence(id: 'u-left', name: 'Sol');
    const right = ChatRoomPresence(id: 'u-right', name: 'Sağ');

    final notifier = container.read(pkBattleProvider.notifier);
    notifier.prepareShell(
      room: room,
      presence: const [left, right],
      left: left,
      right: right,
    );

    final unresolved = LiveGiftEvent(
      id: 'g1',
      senderName: 'X',
      receiverName: 'Y',
      giftId: 'heart',
      giftName: 'Kalp',
      quantity: 1,
      coinCost: 100,
      timestamp: DateTime.now(),
    );
    expect(notifier.giftSideResolvable(unresolved), isFalse);

    final toLeft = LiveGiftEvent(
      id: 'g2',
      senderName: 'X',
      receiverName: 'Sol',
      receiverId: 'u-left',
      giftId: 'heart',
      giftName: 'Kalp',
      quantity: 1,
      coinCost: 100,
      timestamp: DateTime.now(),
    );
    expect(notifier.giftSideResolvable(toLeft), isTrue);
    expect(notifier.giftTargetsLeft(toLeft), isTrue);

    final toRight = toLeft.copyWith(receiverId: 'u-right');
    expect(notifier.giftTargetsLeft(toRight), isFalse);
  });
}

extension on LiveGiftEvent {
  LiveGiftEvent copyWith({String? receiverId}) {
    return LiveGiftEvent(
      id: id,
      senderId: senderId,
      receiverId: receiverId ?? this.receiverId,
      senderName: senderName,
      receiverName: receiverName,
      giftId: giftId,
      giftName: giftName,
      quantity: quantity,
      coinCost: coinCost,
      timestamp: timestamp,
    );
  }
}
