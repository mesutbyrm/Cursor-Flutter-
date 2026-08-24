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
}
