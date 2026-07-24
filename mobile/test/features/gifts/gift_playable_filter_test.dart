import 'package:canlifal_social/features/gifts/domain/gift_entity.dart';
import 'package:canlifal_social/features/gifts/domain/gift_playable_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('filters inactive and hidden gifts', () {
    final gifts = [
      const GiftEntity(id: 'a', name: 'A', price: 10, isHidden: true),
      const GiftEntity(id: 'b', name: 'B', price: 10, isActive: false),
      const GiftEntity(id: 'c', name: 'C', price: 10),
    ];
    expect(
      GiftPlayableFilter.forContext(gifts, context: 'voice_room').length,
      1,
    );
  });

  test('respects voice/live visibility flags', () {
    final gifts = [
      const GiftEntity(
        id: 'v',
        name: 'Voice',
        price: 10,
        visibleInLiveStream: false,
      ),
      const GiftEntity(
        id: 'l',
        name: 'Live',
        price: 10,
        visibleInVoiceRoom: false,
      ),
    ];
    expect(
      GiftPlayableFilter.forContext(gifts, context: 'voice_room').single.id,
      'v',
    );
    expect(
      GiftPlayableFilter.forContext(gifts, context: 'live_stream').single.id,
      'l',
    );
  });

  test('mergeContexts dedupes by id', () {
    final merged = GiftPlayableFilter.mergeContexts(
      [const GiftEntity(id: 'x', name: 'X', price: 5)],
      [const GiftEntity(id: 'x', name: 'Old', price: 1)],
      context: 'voice_room',
    );
    expect(merged.single.name, 'X');
  });
}
