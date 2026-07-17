import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/live/domain/entities/live_gift_event.dart';
import 'package:canlifal_social/features/live/domain/entities/live_stream_entity.dart';
import 'package:canlifal_social/features/live/domain/pk/live_pk_opponent_filter.dart';
import 'package:canlifal_social/features/live/data/datasources/live_gifts_remote_datasource.dart';
import 'package:dio/dio.dart';

void main() {
  group('filterPkEligibleLiveStreams', () {
    test('excludes owner-null, offline, duplicates; keeps zero-viewer hosts', () {
      final streams = [
        LiveStreamEntity(
          id: 'a',
          title: 'A',
          streamerName: 'Host A',
          thumbnailUrl: '',
          category: 'chat',
          viewerCount: 5,
          isLive: true,
          hostUserId: 'u1',
        ),
        LiveStreamEntity(
          id: 'a',
          title: 'A dup',
          streamerName: 'Host A',
          thumbnailUrl: '',
          category: 'chat',
          viewerCount: 3,
          isLive: true,
          hostUserId: 'u1',
        ),
        LiveStreamEntity(
          id: 'b',
          title: 'B',
          streamerName: 'Host B',
          thumbnailUrl: '',
          category: 'chat',
          viewerCount: 0,
          isLive: true,
          hostUserId: 'u2',
        ),
        LiveStreamEntity(
          id: 'c',
          title: 'C',
          streamerName: 'Host C',
          thumbnailUrl: '',
          category: 'chat',
          viewerCount: 2,
          isLive: true,
          hostUserId: null,
        ),
      ];

      final out = filterPkEligibleLiveStreams(streams, excludeStreamId: 'mine');
      expect(out.map((e) => e.id).toList(), ['a', 'b']);
    });

    test('allows PK live with zero viewers', () {
      final streams = [
        LiveStreamEntity(
          id: 'pk1',
          title: 'PK',
          streamerName: 'PK Host',
          thumbnailUrl: '',
          category: 'chat',
          viewerCount: 0,
          isLive: true,
          hostUserId: 'u9',
          isPkLive: true,
        ),
      ];
      expect(filterPkEligibleLiveStreams(streams), hasLength(1));
    });
  });

  group('parseGiftEvent jeton', () {
    final ds = LiveGiftsRemoteDataSource(Dio());

    test('uses totalCoin when backend sends giftPrice + totalCoin', () {
      final ev = ds.parseGiftEvent(
        {
          'id': 'g1',
          'giftTypeId': 'rose',
          'giftName': 'Gül',
          'senderName': 'Ahmet',
          'receiverName': 'Ayşe',
          'quantity': 10,
          'giftPrice': 50,
          'totalCoin': 500,
          'giftImage': 'https://cdn.example.com/rose.png',
        },
        streamId: 'stream-1',
      );
      expect(ev, isNotNull);
      expect(ev!.jetonAmount, 500);
      expect(ev.giftPrice, 50);
      expect(ev.displayImageUrl, contains('rose.png'));
    });

    test('LiveGiftEvent.jetonAmount prefers totalCoin', () {
      final ev = LiveGiftEvent(
        id: 'x',
        senderName: 'A',
        receiverName: 'B',
        giftId: 'g',
        giftName: 'Gül',
        quantity: 10,
        coinCost: 0,
        giftPrice: 50,
        totalCoin: 500,
        timestamp: DateTime(2026),
      );
      expect(ev.jetonAmount, 500);
    });
  });
}
