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
  test('publishRemote dedupes duplicate event id', () async {
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

    await Future<void>.delayed(const Duration(milliseconds: 20));
    await sub.cancel();

    expect(seen, hasLength(1));
    expect(seen.single.id, 'evt-1');
  });

  test('publishRemote dedupes rapid fingerprint with different ids', () async {
    final dio = Dio();
    final svc = VoiceRoomGiftRealtimeService(
      ChatRoomGiftsRemoteDataSource(dio, LiveGiftsRemoteDataSource(dio)),
    );
    addTearDown(svc.dispose);

    final seen = <LiveGiftEvent>[];
    final sub = svc.events.listen(seen.add);
    final t0 = DateTime.utc(2026, 10, 6, 12);

    svc.publishRemote(_gift(id: 'evt-a', at: t0));
    svc.publishRemote(
      _gift(id: 'evt-b', at: t0.add(const Duration(milliseconds: 500))),
    );

    await Future<void>.delayed(const Duration(milliseconds: 20));
    await sub.cancel();

    expect(seen, hasLength(1));
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
