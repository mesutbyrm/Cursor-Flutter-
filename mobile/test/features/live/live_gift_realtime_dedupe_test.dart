import 'package:canlifal_social/features/live/data/datasources/live_gifts_remote_datasource.dart';
import 'package:canlifal_social/features/live/data/services/live_gift_realtime_service.dart';
import 'package:canlifal_social/features/live/domain/entities/live_gift_event.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoRemote implements LiveGiftsRemoteDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

LiveGiftEvent _ev(String id, DateTime at) => LiveGiftEvent(
      id: id,
      senderId: 'u1',
      senderName: 'Ali',
      receiverName: 'Ayşe',
      giftId: 'rose',
      giftName: 'Gül',
      quantity: 1,
      coinCost: 10,
      giftPrice: 10,
      totalCoin: 10,
      totalDiamond: 0,
      combo: 1,
      timestamp: at,
    );

void main() {
  test('K1: aynı hediye art arda (SSE, farklı id) iki kez yayınlanır', () async {
    final svc = LiveGiftRealtimeService(_NoRemote());
    addTearDown(svc.dispose);
    final got = <String>[];
    final sub = svc.events.listen((e) => got.add(e.id));
    addTearDown(sub.cancel);
    final now = DateTime.now();
    svc.publishRemote(_ev('g1', now));
    svc.publishRemote(_ev('g2', now.add(const Duration(milliseconds: 500))));
    await Future<void>.delayed(Duration.zero);
    expect(got, ['g1', 'g2']);
  });

  test('K1: poll kopyası (farklı id) SSE ile gelmişse tekrar yayınlanmaz',
      () async {
    final svc = LiveGiftRealtimeService(_NoRemote());
    addTearDown(svc.dispose);
    final got = <String>[];
    final sub = svc.events.listen((e) => got.add(e.id));
    addTearDown(sub.cancel);
    final now = DateTime.now();
    svc.publishRemote(_ev('sse-1', now));
    svc.publishPolled(_ev('hist-1', now));
    // SSE'de olmayan ikinci aynı hediye poll ile gelir.
    svc.publishPolled(_ev('hist-2', now.add(const Duration(seconds: 1))));
    await Future<void>.delayed(Duration.zero);
    expect(got, ['sse-1', 'hist-2']);
  });
}
