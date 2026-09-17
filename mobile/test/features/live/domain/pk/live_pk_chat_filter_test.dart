import 'package:canlifal_social/features/live/domain/pk/live_pk_chat_filter.dart';
import 'package:canlifal_social/features/live/presentation/widgets/broadcast_room/live_room_chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hides PK system noise', () {
    expect(
      livePkChatMessageVisible(
        LiveRoomChatMessage(
          id: '1',
          user: 'Sistem',
          text: 'PK başladı!',
          isSystem: true,
        ),
      ),
      isFalse,
    );
  });

  test('hides gift system lines', () {
    expect(
      livePkChatMessageVisible(
        LiveRoomChatMessage(
          id: '2',
          user: 'Sistem',
          text: 'Mesut 10 jeton değerinde hediye gönderdi',
          isSystem: true,
        ),
      ),
      isFalse,
    );
  });

  test('keeps normal chat', () {
    expect(
      livePkChatMessageVisible(
        LiveRoomChatMessage(
          id: '3',
          user: 'Ayşe',
          text: 'Merhaba herkese',
        ),
      ),
      isTrue,
    );
  });
}
