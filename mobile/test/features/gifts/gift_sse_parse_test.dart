import 'package:canlifal_social/features/live/data/datasources/live_gifts_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LiveGiftsRemoteDataSource remote;

  setUp(() {
    remote = LiveGiftsRemoteDataSource(Dio());
  });

  test('parseGiftEvent handles voice room flat SSE payload', () {
    final event = remote.parseGiftEvent(
      {
        'type': 'gift',
        'senderId': 'u_7781',
        'senderName': 'Yıldız',
        'recipientId': 'u_55',
        'recipientName': 'Ali',
        'giftTypeId': 'gt_rose',
        'giftName': 'Gül',
        'giftIcon': '🌹',
        'quantity': 10,
        'amount': 100,
        'currencyType': 'jeton',
      },
      streamId: 'clr9x2abc',
    );

    expect(event, isNotNull);
    expect(event!.giftId, 'gt_rose');
    expect(event.giftName, 'Gül');
    expect(event.senderName, 'Yıldız');
    expect(event.receiverName, 'Ali');
    expect(event.quantity, 10);
    expect(event.totalCoin, 100);
  });

  test('parseGiftEvent handles nested live stream gift payload', () {
    final event = remote.parseGiftEvent(
      {
        'type': 'gift',
        'streamId': 'vs_9021',
        'gift': {
          'id': 'g_5521',
          'senderName': 'Yıldız',
          'giftName': 'Kalp',
          'giftIcon': '❤️',
          'quantity': 5,
          'totalPrice': 250,
          'assetUrl': 'https://cdn.example.com/heart.mp4',
          'assetType': 'video',
        },
      },
      streamId: 'vs_9021',
    );

    expect(event, isNotNull);
    expect(event!.giftId, 'g_5521');
    expect(event.giftName, 'Kalp');
    expect(event.totalCoin, 250);
    expect(event.animationKey, 'https://cdn.example.com/heart.mp4');
  });
}
