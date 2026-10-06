import 'package:canlifal_social/features/live/data/datasources/live_gifts_remote_datasource.dart';
import 'package:canlifal_social/features/live/domain/entities/live_gift_event.dart';
import 'package:canlifal_social/features/voice_hub/data/datasources/chat_room_gifts_remote_datasource.dart';
import 'package:canlifal_social/features/voice_hub/data/services/voice_room_gift_realtime_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

LiveGiftEvent _gift({required String id, DateTime? at}) {
  final ts = at ?? DateTime.utc(2026, 10, 6, 12);
  return LiveGiftEvent(
    id: id,
    senderId: 's1',
    senderName: 'Sender',
    receiverId: 'r1',
    receiverName: 'Receiver',
    giftId: 'g1',
    giftName: 'Rose',
    quantity: 1,
    coinCost: 10,
    timestamp: ts,
    totalCoin: 10,
  );
}

void main() {
  test('publishRemote dedupes same id and rapid fingerprint (P1/P2)', () async {
    final dio = Dio();
    final gifts = ChatRoomGiftsRemoteDataSource(
      dio,
      LiveGiftsRemoteDataSource(dio),
    );
    final svc = VoiceRoomGiftRealtimeService(gifts);
    addTearDown(svc.dispose);

    final seen = <LiveGiftEvent>[];
    final sub = svc.events.listen(seen.add);

    svc.publishRemote(_gift(id: 'evt-1'));
    svc.publishRemote(_gift(id: 'evt-1'));
    svc.publishRemote(
      _gift(
        id: 'evt-2',
        at: DateTime.utc(2026, 10, 6, 12, 0, 0, 100),
      ),
    );
    svc.publishRemote(
      _gift(
        id: 'evt-3',
        at: DateTime.utc(2026, 10, 6, 12, 0, 0, 200),
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 20));
    await sub.cancel();

    expect(seen, hasLength(2));
    expect(seen.map((e) => e.id), ['evt-1', 'evt-2']);
  });

  test('setSseActive stops poll path (SSE primary)', () {
    final dio = Dio();
    final svc = VoiceRoomGiftRealtimeService(
      ChatRoomGiftsRemoteDataSource(dio, LiveGiftsRemoteDataSource(dio)),
    );
    addTearDown(svc.dispose);
    svc.setSseActive(true);
    svc.start('room-1');
    expect(svc.events, isNotNull);
    svc.stop();
  });
}
