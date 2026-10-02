import 'package:canlifal_social/features/live/domain/pk/live_pk_chat_filter.dart';
import 'package:canlifal_social/features/live/presentation/widgets/broadcast_room/live_room_chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('kullanıcı mesajı "pk" içerse bile PK sohbetinde görünür', () {
    const m = LiveRoomChatMessage(user: 'Ayşe', text: 'pk at artık');
    expect(livePkChatMessageVisible(m), isTrue);
  });

  test('PK sistem gürültüsü gizlenir, diğer sistem mesajları görünür', () {
    const noise = LiveRoomChatMessage(
      user: 'Sistem',
      text: 'PK başladı!',
      isSystem: true,
    );
    const welcome = LiveRoomChatMessage(
      user: 'Sistem',
      text: 'Ali odaya katıldı',
      isSystem: true,
    );
    expect(livePkChatMessageVisible(noise), isFalse);
    expect(livePkChatMessageVisible(welcome), isTrue);
  });
}
