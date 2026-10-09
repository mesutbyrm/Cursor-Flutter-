import 'package:canlifal_social/features/gifts/domain/gift_engine_sse_router.dart';
import 'package:canlifal_social/features/gifts/domain/gift_entity.dart';
import 'package:canlifal_social/features/gifts/presentation/providers/gift_providers.dart';
import 'package:canlifal_social/features/gifts/presentation/sync/gift_session_controller.dart';
import 'package:canlifal_social/features/live/domain/entities/live_gift_event.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

LiveGiftEvent _event({
  required String id,
  String senderId = 'u1',
  String giftId = 'heart',
  int jeton = 50,
  int combo = 1,
  String? assetUrl,
  String? assetType,
  String? engineAnimationType,
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
    combo: combo,
    timestamp: DateTime.now(),
    engineDurationMs: 2000,
    engineFeedDurationMs: 3000,
    assetUrl: assetUrl,
    assetType: assetType,
    engineAnimationType: engineAnimationType,
  );
}

ProviderContainer _isolatedGiftContainer() {
  return ProviderContainer(
    overrides: [
      liveGiftCatalogProvider.overrideWith((ref) async => const <GiftEntity>[]),
      voiceRoomGiftCatalogProvider.overrideWith(
        (ref) async => const <GiftEntity>[],
      ),
      liveStreamGiftCatalogProvider.overrideWith(
        (ref) async => const <GiftEntity>[],
      ),
    ],
  );
}

void _mockPathProviderForTests() {
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    switch (call.method) {
      case 'getTemporaryDirectory':
      case 'getApplicationSupportDirectory':
      case 'getApplicationDocumentsDirectory':
      case 'getApplicationCacheDirectory':
        return '/tmp';
      default:
        return null;
    }
  });
}

void _clearPathProviderForTests() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    null,
  );
}

Future<void> _waitActive(
  ProviderContainer container,
  String key,
  String id,
) async {
  for (var i = 0; i < 100; i++) {
    if (container.read(giftSessionProvider(key)).activeAnimation?.id == id) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('aktif animasyon $id olmadı');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('backend combo değeri recent satırında korunur', () {
    final container = _isolatedGiftContainer();
    addTearDown(container.dispose);

    final notifier = container.read(giftSessionProvider('room-1').notifier);
    notifier.onGiftSent(_event(id: 'e1', combo: 5), source: 'test');

    final state = container.read(giftSessionProvider('room-1'));
    expect(state.recentGifts.length, 1);
    expect(state.recentGifts.first.combo, 5);
  });

  test('duplicate event id yok sayılır', () {
    final container = _isolatedGiftContainer();
    addTearDown(container.dispose);

    final notifier = container.read(giftSessionProvider('room-1').notifier);
    notifier.onGiftSent(_event(id: 'dup'), source: 'test');
    notifier.onGiftSent(_event(id: 'dup'), source: 'test');

    final state = container.read(giftSessionProvider('room-1'));
    expect(state.recentGifts.length, 1);
    expect(state.processedEventIds.length, 1);
  });

  test('legacy blocked after engine gift_received for same history', () {
    final container = _isolatedGiftContainer();
    addTearDown(container.dispose);

    final notifier = container.read(giftSessionProvider('room-e').notifier);
    expect(
      notifier.routeGiftSsePayload({
        'engine': true,
        'event': 'gift_received',
        'giftHistoryId': 'hist-1',
      }),
      GiftEngineSseAction.visualize,
    );
    expect(
      notifier.routeGiftSsePayload({
        'type': 'gift',
        'giftHistoryId': 'hist-1',
        'giftTypeId': 'rose',
      }),
      GiftEngineSseAction.skip,
    );
  });

  test('voice_realtime kaynağı animasyon kuyruğuna eklenir', () async {
    _mockPathProviderForTests();
    addTearDown(_clearPathProviderForTests);

    final container = _isolatedGiftContainer();
    addTearDown(container.dispose);

    final notifier = container.read(giftSessionProvider('room-v').notifier);
    notifier.onVoiceGiftSent(
      _event(
        id: 'voice-1',
        jeton: 100,
      ),
      source: 'voice_realtime',
    );

    final state = container.read(giftSessionProvider('room-v'));
    expect(state.processedEventIds, contains('voice-1'));
    expect(state.recentGifts, isNotEmpty);
    expect(state.latestEvent?.id, 'voice-1');
    final queued = state.activeAnimation ??
        (state.animationQueue.isNotEmpty ? state.animationQueue.first : null);
    expect(queued?.id, 'voice-1');

    await Future<void>.delayed(const Duration(milliseconds: 100));
  });

  test('GIFT-001: video sürerken gift_finished kuyruğu kapatmaz', () async {
    _mockPathProviderForTests();
    addTearDown(_clearPathProviderForTests);

    final container = _isolatedGiftContainer();
    addTearDown(container.dispose);

    final sub = container.listen(giftSessionProvider('room-g'), (_, __) {});
    addTearDown(sub.close);
    final notifier = container.read(giftSessionProvider('room-g').notifier);
    notifier.onVoiceGiftSent(_event(id: 'vid-1', jeton: 100),
        source: 'voice_realtime');
    await _waitActive(container, 'room-g', 'vid-1');
    var state = container.read(giftSessionProvider('room-g'));

    notifier.holdActiveForVideo('vid-1', const Duration(milliseconds: 300));
    expect(notifier.isVideoHeld('vid-1'), isTrue);

    // Backend varsayılan 3000 ms sonunda gift_finished gönderir.
    notifier.onEngineGiftFinished({'event': 'gift_finished', 'id': 'vid-1'});
    state = container.read(giftSessionProvider('room-g'));
    expect(state.activeAnimation?.id, 'vid-1',
        reason: 'video bitmeden kapatılmamalı');

    await Future<void>.delayed(const Duration(milliseconds: 400));
    state = container.read(giftSessionProvider('room-g'));
    expect(state.activeAnimation?.id, isNot('vid-1'));
    expect(notifier.isVideoHeld('vid-1'), isFalse);
  });

  test('GIFT-001: overlay açık bitişi tutmayı da temizler', () async {
    _mockPathProviderForTests();
    addTearDown(_clearPathProviderForTests);

    final container = _isolatedGiftContainer();
    addTearDown(container.dispose);

    final sub = container.listen(giftSessionProvider('room-h'), (_, __) {});
    addTearDown(sub.close);
    final notifier = container.read(giftSessionProvider('room-h').notifier);
    notifier.onVoiceGiftSent(_event(id: 'vid-2', jeton: 100),
        source: 'voice_realtime');
    await _waitActive(container, 'room-h', 'vid-2');
    notifier.holdActiveForVideo('vid-2', const Duration(seconds: 5));
    notifier.dequeueAnimation('vid-2');
    final state = container.read(giftSessionProvider('room-h'));
    expect(state.activeAnimation?.id, isNot('vid-2'));
    expect(notifier.isVideoHeld('vid-2'), isFalse);
  });

  test('K1: gift_finished bekleyen (oynamamış) hediyeyi kuyruktan silmez',
      () async {
    _mockPathProviderForTests();
    addTearDown(_clearPathProviderForTests);

    final container = _isolatedGiftContainer();
    addTearDown(container.dispose);

    final sub = container.listen(giftSessionProvider('room-k'), (_, __) {});
    addTearDown(sub.close);
    final notifier = container.read(giftSessionProvider('room-k').notifier);
    notifier.onGiftSent(_event(id: 'a'), source: 'live_realtime');
    notifier.onGiftSent(_event(id: 'b'), source: 'live_realtime');
    await _waitActive(container, 'room-k', 'a');

    // Sunucu zaman çizelgesi önde: henüz oynamamış «b» için bitti.
    notifier.onEngineGiftFinished({'event': 'gift_finished', 'id': 'b'});
    var state = container.read(giftSessionProvider('room-k'));
    expect(state.animationQueue.map((e) => e.id), contains('b'));

    notifier.onEngineGiftFinished({'event': 'gift_finished', 'id': 'a'});
    await _waitActive(container, 'room-k', 'b');
    state = container.read(giftSessionProvider('room-k'));
    expect(state.activeAnimation?.id, 'b');
  });

  test('K1: REST yanıtıyla işlenen hediye SSE gelince yine de oynar',
      () async {
    _mockPathProviderForTests();
    addTearDown(_clearPathProviderForTests);

    final container = _isolatedGiftContainer();
    addTearDown(container.dispose);

    final sub = container.listen(giftSessionProvider('room-s'), (_, __) {});
    addTearDown(sub.close);
    final notifier = container.read(giftSessionProvider('room-s').notifier);
    notifier.onGiftSent(_event(id: 'own-1', jeton: 100), source: 'api_response');
    var state = container.read(giftSessionProvider('room-s'));
    expect(state.activeAnimation, isNull);
    expect(state.roomTotalJeton, 100);

    notifier.onGiftSent(_event(id: 'own-1', jeton: 100), source: 'live_realtime');
    await _waitActive(container, 'room-s', 'own-1');
    state = container.read(giftSessionProvider('room-s'));
    expect(state.roomTotalJeton, 100, reason: 'jeton iki kez sayılmaz');
    expect(state.recentGifts.length, 1);

    // Üçüncü kopya artık gerçek tekrar.
    notifier.dequeueAnimation('own-1');
    notifier.onGiftSent(_event(id: 'own-1', jeton: 100), source: 'live_realtime');
    state = container.read(giftSessionProvider('room-s'));
    expect(state.activeAnimation, isNull);
    expect(state.animationQueue, isEmpty);
  });
}
