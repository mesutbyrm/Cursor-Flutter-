import 'package:canlifal_social/features/live/domain/live_chat_gift_merge.dart';
import 'package:canlifal_social/features/live/presentation/widgets/broadcast_room/live_room_chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

LiveRoomChatMessage g(String s, String r, int j, String gift) =>
    LiveRoomChatMessage(
      user: 'Sistem',
      isSystem: true,
      text: "$s, $r'ye $j Jeton değerinde $gift gönderdi.",
    );

void main() {
  test('ardışık aynı hediye tek satırda toplanır', () {
    final out = mergeGiftChatMessages([
      g('Mert', 'Ayşe', 500, 'Aslan'),
      g('Mert', 'Ayşe', 500, 'Aslan'),
      g('Mert', 'Ayşe', 500, 'Aslan'),
    ]);
    expect(out, hasLength(1));
    expect(out.single.text, '🎁 Mert → Ayşe · Aslan x3 (1500 Jeton)');
  });

  test('farklı gönderen/hediye ve normal mesaj birleşmez', () {
    final out = mergeGiftChatMessages([
      g('Mert', 'Ayşe', 500, 'Aslan'),
      const LiveRoomChatMessage(user: 'Ali', text: 'Harika'),
      g('Mert', 'Ayşe', 500, 'Aslan'),
      g('Kaan', 'Ayşe', 1, 'Gül'),
    ]);
    expect(out, hasLength(4));
  });
}
