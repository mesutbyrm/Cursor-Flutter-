import 'package:canlifal_social/features/gifts/domain/gift_engine_sse_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GiftEngineSseRouter', () {
    test('classifies gift_received as visualize', () {
      expect(
        GiftEngineSseRouter.classify({
          'engine': true,
          'event': 'gift_received',
          'giftHistoryId': 'h1',
        }),
        GiftEngineSseAction.visualize,
      );
    });

    test('classifies gift_queue_updated as queueSync', () {
      expect(
        GiftEngineSseRouter.classify({
          'engine': true,
          'event': 'gift_queue_updated',
          'queue': [],
        }),
        GiftEngineSseAction.queueSync,
      );
    });

    test('classifies gift_finished as finished', () {
      expect(
        GiftEngineSseRouter.classify({
          'engine': true,
          'event': 'gift_finished',
          'queueItemId': 'q1',
        }),
        GiftEngineSseAction.finished,
      );
    });

    test('legacy payload without engine is legacyVisualize', () {
      expect(
        GiftEngineSseRouter.classify({
          'type': 'gift',
          'giftTypeId': 'rose',
          'giftName': 'Gül',
        }),
        GiftEngineSseAction.legacyVisualize,
      );
    });

    test('unknown engine event is skip', () {
      expect(
        GiftEngineSseRouter.classify({
          'engine': true,
          'event': 'gift_unknown',
        }),
        GiftEngineSseAction.skip,
      );
    });

    test('dedupeKey prefers giftHistoryId', () {
      expect(
        GiftEngineSseRouter.dedupeKey({
          'giftHistoryId': 'hist-99',
          'id': 'other',
        }),
        'hist-99',
      );
    });
  });
}
